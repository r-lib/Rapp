


as_app <- function(x, complete = TRUE) {
  if(inherits(x, "Rapp"))
    return(x)

  # TODO: present a nice error message in case of parse errors
  filepath <- x
  lines <- readLines(filepath)
  exprs <- parse(
    text = lines, keep.source = TRUE,
    srcfile = srcfilecopy(filepath, lines,
                          file.mtime(filepath), isFile = TRUE))

  app <- new.env(parent = emptyenv())
  attr(app, "class") <- "Rapp"

  app$filepath <- filepath
  app$lines <- lines
  app$line_is_hashpipe <- startsWith(lines, "#| ")
  app$exprs <- exprs

  if(complete) {
    app$data <- get_app_data(app)
    inputs <- get_app_inputs(app)
    app$opts <- inputs$opts
    app$args <- inputs$args
  }

  app
}


get_app_data <- function(app) {

  app <- as_app(app, complete = FALSE)

  data <-
    if (app$line_is_hashpipe[1] ||
        startsWith(app$lines[1], "#!/") && app$line_is_hashpipe[2]) {
      # allow frontmatter to start on 2nd line if first line is a shebang

      hashpipe_start <- which.max(app$line_is_hashpipe)
      hashpipe_end <- which.min(c(TRUE, app$line_is_hashpipe[-1L])) -1L

      parse_hashpipe_yaml(app$lines[hashpipe_start:hashpipe_end])
    } else {
      as_yaml(list())
    }


  data
}


get_app_inputs <- function(app) {

  app <- as_app(app, complete = FALSE)
  lines <- app$lines
  exprs <- app$exprs
  is_hashpipe <- app$line_is_hashpipe

  # 0-length names to force a yaml mapping if no flags.
  opts <- structure(list(), names = character())
  args <- structure(list(), names = character())

  for (i in seq_along(exprs)) {
    e <- exprs[[i]]

    if (!is.call(e))
      next

    op <- e[[1L]]
    if (op != quote(`=`) && op != quote(`<-`))
      next

    if (typeof(e[[2L]]) != "symbol")
      next

    name <- as.character(e[[2L]])

    # already encountered this same symbol as a flag earlier
    if (name %in% names(args))
      next

    default <- e[[3L]]
    if (is.call(default)) {


      if(!is.symbol(call_sym <- default[[1]]))
        next

      call_sym <- as.character(call_sym)

      if(!call_sym %in% c("c", "character", "+"))
        next

      if(all.names(default) %in% c("c", "character")) #"+"
        default <- eval(default, envir = baseenv())
      ## TODO: complex are `+` calls, eval, all else, next
      ## TODO: special syntax for var len values? `vals <- c("a", "b")`, injected as `[a,b]`
    }

    if (!typeof(default) %in%
        c("double", "integer", "character", "logical", "NULL"))
      next

    if (!(identical(length(default), 1L) ||
          identical(length(default), 0L)))
      next

    ## three types of cli args:
    ##   --foo bar  (option: option that takes a val)
    ##   --foo      (switch: bool flag)
    ##   foo        (positional arg)
    ## bonus:
    ##   -f         (short form of opt and switch) (NotYetImplemented())

    arg <- list(
      default = default,
      val_type = switch(
        typeof(default),
        "character" = "string",
        "logical" = "bool",
        "double" = "float",
        "integer" = "int",
        "NULL" = "string"
      ),
      arg_type =
        if (isTRUE(default) || isFALSE(default)) "switch"
      else if (length(default)) "option"
      else "positional",
      .val_pos_in_exprs = c(i, 3L)
    )

    # "complex" = "string"))
    # yaml has no native support for complex

    lineno <- utils::getSrcLocation(exprs[i], "line")
    # look for adjacent anno hints about this flag
    if (is_hashpipe[lineno - 1L]) {
      anno_start <- anno_end <- lineno - 1L
      while (is_hashpipe[anno_start - 1L])
        subtract(anno_start) <- 1L

      anno <- parse_hashpipe_yaml(lines[anno_start:anno_end])
      arg <- utils::modifyList(arg, anno)
    }

    if (arg$arg_type == "positional")
      args[[name]] <- arg
    else
      opts[[name]] <- arg

  }


  list(args = args, opts = opts)
}



#' Run an R app.
#'
#' @param app A filepath to an Rapp.
#' @param args character vector of command line args.
#'
#' @return nothing, invisibly. Called for its side effect.
#' @export
run <- function(app, args = commandArgs(TRUE)) {
  args <- textConnection(args)
  if(missing(app))
    app <- readLines(args, 1L)

  app <- as_app(app)

  if (process_args(args, app))
    eval(app$exprs, new.env(parent = globalenv()))
  invisible()
}

