process_args <- function(args, app) {
  app <- as_app(app)
  app_opts <- app$opts
  app_args <- app$args
  app_commands <- app$commands
  command_path <- character()

  if (!inherits(args, "connection")) {
    args <- textConnection(args)
    on.exit(close(args))
  }

  short_opt_to_long_opt <- function(short_opt) {
    short <- str_drop_prefix(short_opt, "-")
    for (i in seq_along(app_opts)) {
      if (identical(short, app_opts[[i]]$short)) {
        return(paste0("--", names(app_opts)[[i]]))
      }
    }
  }

  positional_args <- character()
  while (length(a <- readLines(args, 1L))) {
    if (a == "--" || a == "--args") {
      break
    }

    if (a %in% c("--help", "--help-yaml")) {
      print_app_help(
        app,
        command_path = command_path,
        yaml = a == "--help-yaml"
      )
      return(FALSE)
    }

    arg_type <-
      if (startsWith(a, "--")) {
        "long-opt"
      } else if (startsWith(a, "-")) {
        "short-opt"
      } else if (to_kebab_case(a) %in% names(app_commands)) {
        "command"
      } else {
        "positional"
      }

    if (arg_type == "command") {
      # in the R space, names are always snake_case
      # in the app spec, names are always kebab-case
      app$exprs[[app_commands$.val_pos_in_exprs]] <- to_snake_case(a)
      a <- to_kebab_case(a)
      command <- app_commands[[a]]
      append(app_opts) <- command$opts
      append(app_args) <- command$args
      command_path <- c(command_path, a)
      app_commands <- command$commands
      next
    }

    if (arg_type == "positional") {
      positional_args <- c(positional_args, a)
      next
    }

    if (arg_type == "short-opt") {
      long_name <- short_opt_to_long_opt(a)
      if (!is.null(long_name)) {
        pushBack(long_name, args)
        next
      }
    }

    # resolve these values in this block
    name <- val <- spec <- NULL

    # --name=val
    equals_idx <- regexpr("=", a)
    if (!identical(c(equals_idx), -1L)) {
      name <- substring(a, 3, equals_idx - 1L)
      name <- gsub("-", "_", name, fixed = TRUE)
      val <- str_drop_prefix(a, equals_idx)
      spec <- app_opts[[name]]
    } else {
      # --name
      name <- str_drop_prefix(a, "--")
      name <- gsub("-", "_", name, fixed = TRUE)

      spec <- app_opts[[name]]

      # if flag not known, maybe this is a switch flag
      if (is.null(spec) && startsWith(a, "--no-")) {
        alt_name <- str_drop_prefix(name, "no_")
        spec <- app_opts[[alt_name]]
        if (!is.null(spec)) {
          val <- "false"
          name <- alt_name
        }
      }
    }

    if (is.null(spec)) {
      # we failed to match this to a known option,
      # match later as a positional arg
      append(positional_args) <- a
      next
    }

    if (is.null(val)) {
      if (identical(spec$arg_type, "switch")) {
        val <- "true"
      } else {
        # arg_type == "option"
        val <- readLines(args, 1L)
      }
    }

    mode <- switch(
      spec$val_type,
      "string" = "character",
      "bool" = "logical",
      "float" = "double",
      "integer" = "integer",
      "any"
    )

    # TODO: do we care about enforcing or formalizing flag val length?
    # right now, a val like [1,2,3] gets parsed and is injected as a
    # length 3 integer vector.
    # Decide if this needs a guardrail or paving and signage.

    # Try coerce to the R type, but if coercion fails, e.g.:
    # Warning in as.vector("1a", "integer") : NAs introduced by coercion
    # Then keep the original yaml parsed val as is.
    # NAs cannot be injected from cli args via regular yaml,
    # NAs are sentinals users can use to check if an opt was supplied.
    # (but anything is possible with '!expr ...')
    if (mode != "character") {
      tryCatch(
        {
          val <- parse_yaml(val)
          if (!is.na(coerced_val <- as.vector(val, mode))) {
            val <- coerced_val
          }
        },
        error = identity,
        warning = identity
      )
    }

    # val can be NULL
    if (identical(spec$action, "append")) {
      expr <- app$exprs[[spec$.val_pos_in_exprs]]
      if (!is.call(expr)) {
        expr <- if (isTRUE(is.na(expr))) expr <- quote(c()) else call("c", expr)
      }
      expr[[length(expr) + 1L]] <- val
      app$exprs[[spec$.val_pos_in_exprs]] <- expr
      next
    }

    app$exprs[[spec$.val_pos_in_exprs]] <- val
  }

  if (length(positional_args) || length(app_args)) {
    # we've parsed all the command line args,
    # we can now match positional args
    specs <- app_args %||% structure(list(), names = character())

    collector <- which(
      endsWith(names(specs), "...") |
        startsWith(names(specs), "...")
    )
    if (length(collector) > 1) {
      stop(
        "Only one collector positional arg permitted, encountered:",
        paste(names(specs)[collector], collapse = ", "),
        call. = FALSE
      )
    }

    if (length(collector)) {
      specs[[collector]]$variadic <- TRUE
      specs[[collector]]$action <- "append"
      n_short <- length(positional_args) - length(specs)
      if (n_short < 0) {
        # If a collector is present but there aren't enough positional args,
        # drop the collector slot only when it's not explicitly required.
        if (!isTRUE(specs[[collector]]$required)) {
          specs[[collector]] <- NULL
        }
      } else if (n_short > 0) {
        collector_spec <- specs[collector]
        collector_spec[[1]]$action <- "append"
        append(specs, after = collector) <-
          rep(collector_spec, n_short)
      }
    }

    if (length(specs) < length(positional_args)) {
      stop(
        "Arguments not recognized: ",
        paste0(positional_args[-seq_along(specs)], collapse = " ")
      )
    }

    if (length(specs) != length(positional_args)) {
      for (i in rev(seq_along(specs))) {
        if (isFALSE(specs[[i]]$required)) {
          specs[[i]] <- NULL
        }
        if (length(specs) == length(positional_args)) break
      }
      if (length(specs) != length(positional_args)) {
        n_missing <- length(specs) - length(positional_args)
        noun <- if (length(n_missing) == 1L) "argument" else "arguments"
        nms <- names(specs[seq(to = length(specs), length.out = n_missing)])
        nms <- toupper(gsub("_", "-", nms, fixed = TRUE))
        nms <- paste0(nms, collapse = ", ")
        stop(sprintf("Missing required %s: %s", noun, nms), call. = FALSE)
      }
    }

    for (i in seq_along(positional_args)) {
      spec <- specs[[i]]
      if (identical(spec$action, "append")) {
        append_arg(app$exprs[[spec$.val_pos_in_exprs]]) <- positional_args[[i]]
      } else {
        app$exprs[[spec$.val_pos_in_exprs]] <- positional_args[[i]]
      }
    }
  }

  TRUE
}

# TODO: short options for boolean flags - if default is TRUE,
#   should short should negate the default and inject FALSE? might be confusing.
# TODO: support 'desc' for 'description' in yaml header (meh)
# TODO: think through what character() can/should mean (meh)

to_snake_case <- function(x) gsub("-", "_", x, fixed = TRUE)
to_kebab_case <- function(x) gsub("_", "-", x, fixed = TRUE)
