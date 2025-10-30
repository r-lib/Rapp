print_app_help <- function(app, yaml = TRUE, scope = NULL) {
  app <- as_app(app)
  if (yaml) {
    x <- c(app$data, list(options = app$opts), list(arguments = app$args))
    for (nm in names(x$options)) {
      x$options[[nm]]$.val_pos_in_exprs <- NULL
    }

    for (nm in names(x$arguments)) {
      x$arguments[[nm]]$.val_pos_in_exprs <- NULL
    }

    print.yaml(x)
    return()
  }

  ensure_list <- function(x) if (is.null(x)) list() else x
  wrap_lines <- function(text, indent = 0L, exdent = indent) {
    if (!length(text)) {
      return(character())
    }
    unlist(lapply(
      text,
      function(.x) {
        if (!nzchar(.x)) {
          ""
        } else {
          strwrap(
            .x,
            width = getOption("width", 79L),
            indent = indent,
            exdent = exdent
          )
        }
      }
    ))
  }
  flatten_scope_items <- function(items, key) {
    if (!length(items)) {
      return(list())
    }
    out <- list()
    for (entry in items) {
      value <- ensure_list(entry[[key]])
      if (length(value)) {
        out <- c(out, value)
      }
    }
    out
  }
  default_scope <- function(app) {
    meta <- if (length(app$data)) {
      prune_empty(as.list(unclass(app$data)))
    }
    list(list(
      name = app$data$name %||% basename(app$filepath),
      opts = app$opts,
      args = app$args,
      commands = app$commands %||% list(),
      meta = meta
    ))
  }
  format_cli_name <- function(name) gsub("_", "-", name, fixed = TRUE)
  format_placeholder <- function(name) {
    sprintf("<%s>", toupper(format_cli_name(name)))
  }
  format_default_value <- function(value) {
    if (!length(value)) {
      return(NULL)
    }
    if (is.logical(value) && length(value) == 1L) {
      return(tolower(as.character(value)))
    }
    if (is.integer(value) && length(value) == 1L) {
      return(as.character(value))
    }
    if (is.numeric(value) && length(value) == 1L) {
      return(format(value, trim = TRUE))
    }
    if (is.character(value)) {
      if (length(value) == 1L) {
        return(sprintf("\"%s\"", value))
      }
      quoted <- sprintf("\"%s\"", value)
      return(sprintf("[%s]", paste(quoted, collapse = ", ")))
    }
    if (is.numeric(value) && length(value) > 1L) {
      return(sprintf("[%s]", paste(value, collapse = ", ")))
    }
    deparse1(value)
  }
  format_option_entry <- function(opt, name) {
    cli_name <- format_cli_name(name)
    short_flag <- opt$short
    flag <- paste0("--", cli_name)
    if (!is.null(short_flag) && nzchar(short_flag)) {
      flag <- paste0("-", short_flag, ", ", flag)
    }

    description <- opt$description %||% character()
    details <- character()

    if (identical(opt$arg_type, "option")) {
      flag <- paste(flag, format_placeholder(name))
      default_value <- format_default_value(opt$default)
      if (!is.null(default_value)) {
        details <- c(details, sprintf("[default: %s]", default_value))
      }
      if (length(opt$val_type)) {
        details <- c(details, sprintf("[type: %s]", opt$val_type))
      }
    } else if (identical(opt$arg_type, "switch")) {
      default_value <- format_default_value(opt$default)
      toggle_flag <- paste0("--no-", cli_name)
      toggle_note <- if (isTRUE(opt$default)) {
        sprintf("Disable with `%s`.", toggle_flag)
      } else {
        sprintf("Enable with `%s`.", paste0("--", cli_name))
      }
      if (!is.null(default_value)) {
        details <- c(details, sprintf("[default: %s]", default_value))
      }
      details <- c(details, toggle_note)
      flag <- paste(flag, "/", toggle_flag)
    }

    info <- c(description, details)
    info <- paste(info, collapse = " ")
    list(flag = flag, info = trimws(info))
  }
  format_option_block <- function(opts) {
    opts <- ensure_list(opts)
    if (!length(opts)) {
      return(character())
    }

    entries <- imap(opts, format_option_entry)
    flags <- vapply(entries, "[[", "", "flag")
    infos <- vapply(entries, "[[", "", "info")
    width <- getOption("width", 79L)
    flag_width <- min(max(nchar(flags)), 30L)
    indent <- 2L
    info_width <- width - indent - flag_width - 2L

    out <- character()
    for (i in seq_along(entries)) {
      flag <- flags[[i]]
      info <- infos[[i]]
      padded_flag <- sprintf("%s%-*s", strrep(" ", indent), flag_width, flag)
      wrapped <- if (nzchar(info)) {
        strwrap(info, width = info_width)
      } else {
        ""
      }
      if (!length(wrapped)) {
        wrapped <- ""
      }
      out <- c(
        out,
        paste0(padded_flag, "  ", wrapped[[1L]])
      )
      if (length(wrapped) > 1L) {
        continuation <- paste0(
          strrep(" ", indent + flag_width + 2L),
          wrapped[-1L]
        )
        out <- c(out, continuation)
      }
    }
    out
  }
  format_argument_block <- function(args) {
    args <- ensure_list(args)
    if (!length(args)) {
      return(character())
    }

    entries <- list()
    for (i in seq_along(args)) {
      arg <- args[[i]]
      name <- names(args)[[i]]
      desc <- arg$description
      if (!length(desc)) {
        next
      }
      label <- sub("^\\.\\.\\.|\\.\\.\\.$", "", name)
      label <- format_cli_name(label)
      placeholder <- format_placeholder(label)
      if (isTRUE(arg$variadic) || grepl("\\.\\.\\.", name, fixed = TRUE)) {
        placeholder <- paste0(placeholder, "...")
      }
      entries[[length(entries) + 1L]] <- list(
        label = placeholder,
        description = desc
      )
    }

    if (!length(entries)) {
      return(character())
    }

    labels <- vapply(entries, "[[", "", "label")
    width <- getOption("width", 79L)
    label_width <- min(max(nchar(labels)), 30L)
    indent <- 2L
    desc_width <- width - indent - label_width - 2L

    out <- character()
    for (entry in entries) {
      padded_label <- sprintf(
        "%s%-*s",
        strrep(" ", indent),
        label_width,
        entry$label
      )
      wrapped <- strwrap(entry$description, width = desc_width)
      if (!length(wrapped)) {
        wrapped <- ""
      }
      out <- c(out, paste0(padded_label, "  ", wrapped[[1L]]))
      if (length(wrapped) > 1L) {
        continuation <- paste0(
          strrep(" ", indent + label_width + 2L),
          wrapped[-1L]
        )
        out <- c(out, continuation)
      }
    }
    out
  }
  format_command_block <- function(commands) {
    commands <- ensure_list(commands)
    command_names <- setdiff(names(commands), ".val_pos_in_exprs")
    if (!length(command_names)) {
      return(character())
    }

    entries <- lapply(command_names, function(name) {
      command <- commands[[name]]
      meta <- command$meta %||% list()
      summary <- meta$summary %||% meta$description %||% ""
      list(name = name, summary = summary)
    })

    names_column <- vapply(entries, "[[", "", "name")
    width <- getOption("width", 79L)
    name_width <- min(max(nchar(names_column)), 30L)
    indent <- 2L
    desc_width <- width - indent - name_width - 2L

    out <- character()
    for (entry in entries) {
      padded_name <- sprintf(
        "%s%-*s",
        strrep(" ", indent),
        name_width,
        entry$name
      )
      summary <- entry$summary
      wrapped <- if (nzchar(summary)) {
        strwrap(summary, width = desc_width)
      } else {
        ""
      }
      if (!length(wrapped)) {
        wrapped <- ""
      }
      out <- c(out, paste0(padded_name, "  ", wrapped[[1L]]))
      if (length(wrapped) > 1L) {
        continuation <- paste0(
          strrep(" ", indent + name_width + 2L),
          wrapped[-1L]
        )
        out <- c(out, continuation)
      }
    }
    out
  }
  build_usage_args <- function(args) {
    args <- ensure_list(args)
    if (!length(args)) {
      return(character())
    }
    vapply(
      seq_along(args),
      function(i) {
        name <- names(args)[[i]]
        arg <- args[[i]]
        placeholder <- format_placeholder(name)
        variadic <- isTRUE(arg$variadic) ||
          grepl("\\.\\.\\.", name, fixed = TRUE)
        if (variadic) {
          placeholder <- paste0(placeholder, "...")
        }
        required <- isTRUE(arg$required)
        if (required) {
          placeholder
        } else {
          paste0("[", placeholder, "]")
        }
      },
      ""
    )
  }

  if (is.null(scope)) {
    scope <- default_scope(app)
  }

  current <- scope[[length(scope)]]
  root <- scope[[1]]
  current_meta <- current$meta %||% list()
  current_opts <- ensure_list(current$opts)
  current_args <- ensure_list(current$args)
  current_commands <- ensure_list(current$commands)

  parent_scopes <- if (length(scope) > 2L) {
    scope[seq_len(length(scope) - 1L)][-1L]
  } else {
    list()
  }
  parent_opts <- flatten_scope_items(parent_scopes, "opts")
  global_opts <- ensure_list(root$opts)

  app_name <- root$name %||% basename(app$filepath)
  command_path <- if (length(scope) > 1L) {
    vapply(scope[-1L], `[[`, "", "name")
  } else {
    character()
  }
  full_command <- c(app_name, command_path)
  usage_components <- list(
    paste(full_command, collapse = " ")
  )
  any_opts <- length(current_opts) ||
    length(parent_opts) ||
    length(global_opts)
  if (any_opts) {
    usage_components <- c(usage_components, "[OPTIONS]")
  }
  if (length(setdiff(names(current_commands), ".val_pos_in_exprs"))) {
    usage_components <- c(usage_components, "<COMMAND>")
  }
  usage_components <- c(usage_components, build_usage_args(current_args))
  usage_line <- paste("Usage:", paste(usage_components, collapse = " "))

  header_lines <- character()
  if (length(scope) == 1L) {
    desc <- current_meta$description %||% current_meta$summary
    if (length(desc)) {
      header_lines <- wrap_lines(
        sprintf("%s: %s", app_name, desc)
      )
    } else {
      header_lines <- app_name
    }
  } else {
    summary <- current_meta$summary
    description <- current_meta$description
    if (length(summary)) {
      header_lines <- wrap_lines(summary)
    }
    if (length(description)) {
      if (length(header_lines)) {
        header_lines <- c(header_lines, "")
      }
      header_lines <- c(header_lines, wrap_lines(description))
    }
    if (!length(header_lines)) {
      header_lines <- wrap_lines(
        sprintf("%s command", tail(full_command, 1L))
      )
    }
  }

  sections <- list(
    header_lines,
    "",
    usage_line
  )

  command_block <- format_command_block(current_commands)
  if (length(command_block)) {
    sections <- c(
      sections,
      "",
      "Commands:",
      command_block
    )
  }

  option_block <- format_option_block(current_opts)
  if (length(option_block)) {
    sections <- c(
      sections,
      "",
      "Options:",
      option_block
    )
  }

  parent_option_block <- format_option_block(parent_opts)
  if (length(parent_option_block)) {
    sections <- c(
      sections,
      "",
      "Parent options:",
      parent_option_block
    )
  }

  global_option_block <- if (length(scope) > 1L) {
    format_option_block(global_opts)
  } else {
    character()
  }
  if (length(global_option_block)) {
    sections <- c(
      sections,
      "",
      "Global options:",
      global_option_block
    )
  }

  argument_block <- format_argument_block(current_args)
  if (length(argument_block)) {
    sections <- c(
      sections,
      "",
      "Arguments:",
      argument_block
    )
  }

  if (length(command_block)) {
    run_cmd <- paste(full_command, collapse = " ")
    sections <- c(
      sections,
      "",
      sprintf(
        "For help with a specific command, run: `%s <command> --help`.",
        run_cmd
      )
    )
  }

  sections <- unlist(sections, recursive = FALSE, use.names = FALSE)
  sections <- sections[lengths(sections) > 0L | sections == ""]
  # trim trailing blank lines
  while (length(sections) && tail(sections, 1L) == "") {
    sections <- head(sections, -1L)
  }
  writeLines(sections)
  return()
}
