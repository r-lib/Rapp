


process_args <- function(args, app) {

  app <- as_app(app)

  if(!inherits(args, "connection")) {
    args <- textConnection(args)
    on.exit(close(args))
  }

  positional_args <- character()
  while(length(a <- readLines(args, 1L))) {

    if (a == "--" || a == "--args")
      break

    if (a == "--help") {
      print_app_help(app, yaml = TRUE) #"--yaml" %in% args)
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

    if(arg_type == "short-opt") {
      # convert to a long opt, possibly pushBack()ing val to args
      .NotYetImplemented()
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
      "int" =  "integer",
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

  if(!isTRUE(yaml))
    .NotYetImplemented()

  x <- c(app$data,
         list(options = app$opts),
         list(arguments = app$args))
  for(nm in names(x$options))
    x$options[[nm]]$.val_pos_in_exprs <- NULL

  for(nm in names(x$arguments))
    x$arguments[[nm]]$.val_pos_in_exprs <- NULL

  print.yaml(x)
}


