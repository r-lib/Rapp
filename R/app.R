as_app <- function(x, complete = TRUE) {
  if (inherits(x, "Rapp")) {
    return(x)
  }

  # TODO: present a nice error message in case of parse errors
  filepath <- x
  lines <- readLines(filepath)
  exprs <- parse(
    text = lines,
    keep.source = TRUE,
    srcfile = srcfilecopy(filepath, lines, file.mtime(filepath), isFile = TRUE)
  )

  app <- new.env(parent = emptyenv())
  attr(app, "class") <- "Rapp"

  app$filepath <- filepath
  app$lines <- lines
  app$line_is_hashpipe <- grepl("^\\s*#\\| ", lines)
  app$exprs <- exprs

  if (!interactive()) {
    launcher_name <- Sys.getenv("RAPP_LAUNCHER_NAME", NA_character_)
    if (!is.na(launcher_name)) {
      app$launcher_name <- launcher_name
      Sys.unsetenv("RAPP_LAUNCHER_NAME")
    }
  }

  if (complete) {
    app$data <- get_app_data(app)
    inputs <- get_app_inputs(app)
    app$opts <- inputs$opts
    app$args <- inputs$args
    app$commands <- inputs$commands
  }

  app
}


get_app_data <- function(app) {
  app <- as_app(app, complete = FALSE)

  data <- if (
    app$line_is_hashpipe[1] ||
      startsWith(app$lines[1], "#!/") && app$line_is_hashpipe[2]
  ) {
    # allow frontmatter to start on 2nd line if first line is a shebang

    hashpipe_start <- which.max(app$line_is_hashpipe)
    hashpipe_end <- which.min(c(TRUE, app$line_is_hashpipe[-1L])) - 1L

    parse_hashpipe_yaml(app$lines[hashpipe_start:hashpipe_end])
  } else {
    as_yaml(list())
  }

  data
}


is_simple_assignment_call <- function(e) {
  is.call(e) || return(FALSE)
  op <- e[[1L]]
  if (!identical(op, quote(`=`)) && !identical(op, quote(`<-`))) {
    return(FALSE)
  }
  if (typeof(e[[2L]]) != "symbol") {
    return(FALSE)
  }
  TRUE
}

is_command_switch <- function(e) {
  if (!identical(e[[1L]], quote(switch))) {
    return(FALSE)
  }
  switch_expr <- e[[2L]]
  typeof(switch_expr) == "character" || is_simple_assignment_call(switch_expr)
}

.simple_call_syms <-
  c("+", "-", "c", "character", "integer", "double", "numeric")

.simple_typeofs <- c("double", "integer", "character", "logical", "NULL")

get_app_inputs <- function(app, exprs = app$exprs, pos = integer()) {
  app <- as_app(app, complete = FALSE)
  lines <- app$lines
  is_hashpipe <- app$line_is_hashpipe

  # 0-length names to force a yaml mapping if no flags.
  opts <- args <- commands <- structure(list(), names = character())

  for (i in seq_along(exprs)) {
    e <- exprs[[i]]

    # foo <- NULL   default positional arg  `APP <FOO>`
    # foo <- <TRUE|FALSE>   default switch  `APP --foo` or `APP --no-foo`
    # foo <- <string|float|int literal>  default opt  `APP --foo val`
    # foo <- <c()|list()>   default opt with action: append   `APP --foo val1  --foo val2`
    #
    # switch(<string-literal>, ...)  command
    #
    # questioning:
    # foo <- <integer()|character()|numeric()>  ## undefined ... maybe same as `foo <- c()` with coersion?
    # foo    same as `foo <- NULL` but with required: true (no default)?
    #

    if (!is.call(e)) {
      next
    }

    if (is_command_switch(e)) {
      if (length(commands)) {
        stop("Only one app command switch() block allowed per expression level")
      }
      branches <- as.list(e)[-(1:2)]
      if (".val_pos_in_exprs" %in% names(branches)) {
        stop('command name ".val_pos_in_exprs" not permitted.')
      }

      commands <- map2(
        branches,
        seq_along(branches) + 2L,
        function(branch, branch_idx) {
          # stopifnot(is.call(branch) && identical(branch[[1]], quote(`{`)))
          inputs <-
            get_app_inputs(app, as.list(branch), pos = c(pos, i, branch_idx))

          anno <- parse_expr_anno(getSrcLineNo(branch), lines, is_hashpipe)
          inputs$meta <- anno
          inputs
        }
      )
      names(commands) <- gsub("_", "-", names(commands), fixed = TRUE)
      switch_expr <- e[[2L]]
      commands$.val_pos_in_exprs <-
        c(pos, i, 2L, if (is.call(switch_expr)) 3L)

      next
    }

    if (!is_simple_assignment_call(e)) {
      next
    }

    name <- as.character(e[[2L]])

    # already encountered this same symbol as a flag earlier
    if (name %in% names(args) || name %in% names(opts)) {
      next
    }

    default <- e[[3L]]
    if (is.call(default)) {
      if (identical_any(default, quote(c()), quote(list()))) {
        # leave as call, append opt or positional collector
        # c() collects args strings as-is
        # list() collects (maybe)parsed yaml objects
      } else {
        # maybe a numeric literal
        if (!is.symbol(call_sym <- default[[1L]])) {
          next
        }
        call_sym <- as.character(call_sym)
        if (call_sym %in% c("+", "-")) {
          arg <- default[[2L]]
          if (
            length(default) == 2L &&
              is.atomic(arg) &&
              length(arg) == 1L &&
              all(all.names(default) %in% c("+", "-"))
          ) {
            default <- eval(default, envir = baseenv())
          } else {
            next
          }
        } else {
          next
        }
      }
    }

    if (!length(default) %in% 0L:1L) {
      next
    }

    ## three types of cli args:
    ##   --foo bar  (option: option that takes a val)
    ##   --foo      (switch: bool flag)
    ##   foo        (positional arg)
    ## bonus:
    ##   -f         (short form of opt and switch)
    ##   foo        (command, which potentially adds scope)

    is_collector <-
      is.call(default) || # c() or list()
      startsWith(name, "...") ||
      endsWith(name, "...")

    arg <- list(
      default = default,

      val_type = switch(
        typeof(default),
        "character" = "string",
        "logical" = "bool",
        "double" = "float",
        "integer" = "integer",
        "language" = {
          # c() or list()
          if (identical(default[[1L]], quote(c))) "string" else "any"
        },
        "NULL" = "string"
      ),

      arg_type = if (identical(default, TRUE) || identical(default, FALSE)) {
        "switch"
      } else if (is.null(default)) {
        "positional"
      } else if (startsWith(name, "...") || endsWith(name, "...")) {
        "positional"
      } else {
        "option"
      },

      action = if (is_collector) "append" else "replace",
      .val_pos_in_exprs = c(pos, i, 3L) # pos 3 in call expr: `<-`(name, 'val')
    )

    # look for adjacent anno hints about this flag
    anno <- parse_expr_anno(getSrcLineNo(exprs[i]), lines, is_hashpipe)
    if (length(anno)) {
      arg[names(anno)] <- anno
    }

    # By default, positional arguments are required unless explicitly
    # annotated otherwise. This applies both to NULL-initialized
    # positionals and those explicitly marked via `#| arg-type: positional`.
    if (
      identical(arg$arg_type, "positional") &&
        is.null(arg$required) &&
        !(endsWith(name, "...") || startsWith(name, "..."))
    ) {
      arg$required <- TRUE
    }

    if (arg$arg_type == "positional") {
      args[[name]] <- arg
    } else {
      opts[[name]] <- arg
    }
  }

  compact(list(args = args, opts = opts, commands = commands))
}

identical_any <- function(x, ...) {
  for (i in seq_len(...length())) {
    if (identical(x, ...elt(i))) return(TRUE)
  }
  FALSE
}

getSrcLineNo <- function(x) {
  # simple fast path of utils::getSrcLocation(x, "line") for a single expression.
  # avoid loading utils just for Rapp::run()
  attr(x, "srcref", TRUE)[[1L]][[1L]]
}

parse_expr_anno <- function(lineno, lines, is_hashpipe) {
  anno_start <- anno_end <- lineno - 1L
  is_hashpipe[anno_end] || return(NULL)
  while (anno_start > 1L && is_hashpipe[anno_start - 1L]) {
    anno_start <- anno_start - 1L
  }
  normalize_anno_keys(parse_hashpipe_yaml(
    lines[anno_start:anno_end]
  ))
}

normalize_anno_keys <- function(x) {
  is.list(x) || return(x)

  cls <- attr(x, "class", TRUE)
  x <- lapply(x, normalize_anno_keys)

  if (!is.null(nms <- names(x))) {
    names(x) <- gsub("-", "_", nms, fixed = TRUE)
  }

  class(x) <- cls
  x
}


#' Run an R app.
#'
#' @param app A filepath to an Rapp.
#' @param args character vector of command line args.
#'
#' @return
#'
#' Mainly called for its side effect. For advanced or testing use, it invisibly
#' returns the evaluation environment where the app’s expressions ran. If the
#' app did not run (for example, when `--help` is used), it returns `NULL`
#' invisibly.
#'
#' @export
#'
#' @details
#'
#' See the package README for full details. <https://github.com/r-lib/Rapp>
#'
#' @export
#' @examples
#' # For the example, place 'Rapp', the package examples, and 'R' on the PATH
#' old_path <- Sys.getenv("PATH")
#' Sys.setenv(PATH = paste(system.file("examples", package = "Rapp"),
#'                         system.file("exec", package = "Rapp"),
#'                         R.home("bin"),
#'                         old_path,
#'                         sep = .Platform$path.sep))
#'
#' # Here is an example app:
#' # flip-coin.R
#' writeLines(readLines(
#'   system.file("examples/flip-coin.R", package = "Rapp")))
#'
#' if(.Platform$OS.type != "windows") {
#'   # on macOS and Linux, you can call the app directly
#'   system("flip-coin.R")
#'   system("flip-coin.R --n 3")
#' } else {
#'   # On windows, there is no support for shebang '#!' style executables
#'   # but you can invoke 'Rapp' directly
#'   system("Rapp flip-coin.R")
#'   system("Rapp flip-coin.R --n 3")
#' }
#'
#' # restore PATH
#' Sys.setenv(PATH = old_path)
run <- function(app, args = commandArgs(TRUE)) {
  args <- textConnection(args)
  if (missing(app)) {
    app <- readLines(args, 1L)
  }

  app <- as_app(app)

  if (process_args(args, app)) {
    eval(app$exprs, env <- new.env(parent = globalenv()))
  } else {
    env <- NULL
  }

  invisible(env)
}
