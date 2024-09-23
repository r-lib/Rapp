


process_args <- function(args, app) {

  app <- as_app(app)

  if(!inherits(args, "connection")) {
    args <- textConnection(args)
    on.exit(close(args))
  }

  short_opt_to_long_opt <- local({
    table <- unlist(lapply(app$opts, function(opt) opt$short))
    table <- setNames(as.list(sprintf("--%s", names(table))),
                      sprintf("-%s", table))
    function(short_opt) table[[short_opt]]
  })
  positional_args <- character()
  while(length(a <- readLines(args, 1L))) {

    if (a == "--" || a == "--args")
      break

    if (a == "--help") {
      print_app_help(app, yaml = "--yaml" %in% readLines(args))
      if (interactive()) return(invisible(FALSE))
      else q("no")
    }

    arg_type <-
      if (startsWith(a, "--")) "long-opt" else
      if (startsWith(a, "-")) "short-opt" else
      # if (a %in% names(app$commands)) "command" else
      "positional-arg"

    if(arg_type == "command") {
      .NotYetImplemented()
      # if(length(app$args)) {
      #   pushBack(app$args, args)
      #   app$args <- NULL
      # }
      return(process_args(args, app = app$commands[[a]]))
    }

    if(arg_type == "positional-arg") {
      append(positional_args) <- a
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
      spec <- app$opts[[name]]

    } else {
    # --name
      name <- str_drop_prefix(a, "--")
      name <- gsub("-", "_", name, fixed = TRUE)

      spec <- app$opts[[name]]

      # if flag not known, maybe this is a switch flag
      if(is.null(spec) && startsWith(a, "--no-")) {
        alt_name <- str_drop_prefix(name, "no_")
        spec <- app$opts[[alt_name]]
        if(!is.null(spec)) {
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
      if (identical(spec$arg_type, "switch"))
        val <- "true"
      else # arg_type == "option"
        val <- readLines(args, 1L)
    }

    mode <- switch(spec$val_type,
      "string" =  "character",
      "bool" =  "logical",
      "float" =  "double",
      "integer" =  "integer",
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
    if (mode != "character")
      tryCatch({
        val <- parse_yaml(val)
        if (!is.na(coerced_val <- as.vector(val, mode)))
          val <- coerced_val
      }, error = identity, warning = identity)

    # val can be NULL
    app$exprs[[spec$.val_pos_in_exprs]] <- val
  }


  if(length(positional_args)) {
    # we've parsed all the command line args,
    # we can now match positional args
    specs <- app$args

    collector <- which(endsWith(names(specs), "...") |
                      startsWith(names(specs), "..."))
    if(length(collector) > 1)
      stop("Only one collector positional arg permitted, encountered:",
           paste(names(specs)[collector], collapse = ", "))

    if (length(collector)) {
      specs[[collector]]$variadic <- TRUE
      n_short <- length(positional_args) - length(specs)
      if (n_short < 0)
        specs[[collector]] <- NULL
      else if (n_short > 0) {
        collector_spec <- specs[collector]
        collector_spec[[1]]$action <- "append"
        append(specs, after = collector) <-
          rep(collector_spec, n_short)
      }
    }

    if(length(specs) != length(positional_args))
      stop("Arguments not recognized: ",
           paste0(positional_args[-seq_along(specs)], collapse = " "))

    for (i in seq_along(positional_args)) {
      spec <- specs[[i]]
      if (identical(spec$action, "append"))
        append(app$exprs[[spec$.val_pos_in_exprs]]) <- positional_args[[i]]
      else
        app$exprs[[spec$.val_pos_in_exprs]] <- positional_args[[i]]
    }
  }

  invisible(TRUE)
}




print_app_help <- function(app, yaml = TRUE) {
  app <- as_app(app)
  if (yaml) {

    x <- c(app$data,
           list(options = app$opts),
           list(arguments = app$args))
    for(nm in names(x$options))
      x$options[[nm]]$.val_pos_in_exprs <- NULL

    for(nm in names(x$arguments))
      x$arguments[[nm]]$.val_pos_in_exprs <- NULL

    print.yaml(x)
    return()
  }

  app_name <- app$data$name %||% basename(app$filepath)
  usage <- paste0(collapse = " ", c(
    "Usage:", app_name,
    if (length(app$opts)) "[options]",
    if (length(app$args)) local({ # "<arguments>"
      x <- paste0(sprintf("<%s>", names(app$args)), collapse = " ")
      x <- sub("<...", "...<", x, fixed = TRUE)
      x <- sub("...>", ">...", x, fixed = TRUE)
      x <- paste0("[", x, "]")
      x
    })
  ))
  description <- app$data$description

  options <- imap_chr(app$opts, function(opt, name) {

    if (opt$arg_type == "switch") {
      true <- paste0("--", name)
      false <- paste0("--no-", name)
      default <- if (opt$default) true else false
      header <- sprintf("  %s | %s  (Default: %s)", true, false, default)
      description <- if (length(opt$description))
        strwrap(opt$description, 70, indent = 6, exdent = 6)
      out <- paste0(c(header, description), collapse = "\n")
      return(out)
    }

    if (opt$arg_type == "option") {
      default <- opt$default
      type <- opt$val_type
      if (type == "string")
        default <- deparse1(default)
      header <- sprintf("  --%s <value>  (Default: %s, Type: %s)", name, default, type)
      description <- if (length(opt$description))
        strwrap(opt$description, 70, indent = 6, exdent = 6)
      out <- paste0(c(header, description), collapse = "\n")
      return(out)
    }

    # noisy safe fallback (shouldn't happen)
    opt$.val_pos_in_exprs <- NULL
    yaml::as.yaml(opt)
  })

  ## omit positional args without a description (they appear in usage)
  args <- do.call(c, imap(app$args, function(arg, name) {

    if (!length(arg$description)) return()

    description <- if (length(arg$description))
      strwrap(arg$description, 70, indent = 6, exdent = 6)
    header <- paste0("  ", sub("^\\.\\.\\.|\\.\\.\\.$", "", name))
    paste0(c(header, description), collapse = "\n")
  }))

  if (length(options))
    options <- c("\nOptions:", options)

  if (length(args))
    args <- c("\nArguments:", args)

  if (length(description))
    description <- c(description, "")

  writeLines(c(description, usage, options, args))
  return()
}
