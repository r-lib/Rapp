build_help_yaml_spec <- function(app) {
  opts <- sanitize_help_entries(app$opts)
  args <- sanitize_help_entries(app$args)
  commands <- build_help_command_specs(app$commands)
  c(
    app$data,
    list(
      options = opts,
      arguments = args,
      commands = commands
    )
  )
}

sanitize_help_entries <- function(entries) {
  if (!length(entries)) {
    return(NULL)
  }
  lapply(entries, function(entry) {
    entry$.val_pos_in_exprs <- NULL
    entry
  })
}

build_help_command_specs <- function(commands) {
  if (!length(commands)) {
    return(NULL)
  }
  command_names <- names(commands)
  if (is.null(command_names)) {
    return(NULL)
  }
  commands <- commands[command_names != ".val_pos_in_exprs"]
  if (!length(commands)) {
    return(NULL)
  }
  for (nm in names(commands)) {
    command <- commands[[nm]]
    spec <- command$meta %||% list()
    spec["options"] <- list(sanitize_help_entries(command$opts))
    spec["arguments"] <- list(sanitize_help_entries(command$args))
    spec["commands"] <- list(build_help_command_specs(command$commands))
    commands[[nm]] <- spec
  }
  commands
}

build_help_scope <- function(app, command_path = character()) {
  app <- as_app(app)

  meta <- if (length(app$data)) {
    prune_empty(as.list(unclass(app$data)))
  }

  scope <- list(list(
    name = app$data$name %||% basename(app$filepath),
    opts = app$opts,
    args = app$args,
    commands = app$commands %||% list(),
    meta = meta
  ))

  commands <- app$commands %||% list()
  for (cmd in command_path) {
    command <- commands[[cmd]]
    if (is.null(command)) {
      break
    }
    command_meta <- if (!is.null(command$meta)) {
      prune_empty(as.list(unclass(command$meta)))
    }
    scope[[length(scope) + 1L]] <- list(
      name = cmd,
      opts = command$opts,
      args = command$args,
      commands = command$commands %||% list(),
      meta = command_meta
    )
    commands <- command$commands %||% list()
  }

  scope
}

print_app_help <- function(app, yaml = TRUE, command_path = character()) {
  app <- as_app(app)
  if (yaml) {
    spec <- build_help_yaml_spec(app)
    print.yaml(spec)
    return()
  }
  scope <- build_help_scope(app, command_path)

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

    if (identical(opt$action, "append")) {
      details <- c(details, "May be supplied multiple times.")
    }

    meta_idx <- grepl("^\\[", details)
    meta <- trimws(paste(details[meta_idx], collapse = " "))
    extra <- trimws(paste(details[!meta_idx], collapse = " "))
    desc <- trimws(paste(description, collapse = " "))
    pieces <- c(
      if (nzchar(desc)) desc else NULL,
      if (nzchar(meta)) meta else NULL,
      if (nzchar(extra)) extra else NULL
    )
    list(label = flag, pieces = pieces)
  }
  label_context <- function(label, indent, label_width) {
    padded_label <- sprintf(
      "%s%-*s",
      strrep(" ", indent),
      label_width,
      label
    )
    list(
      initial = paste0(padded_label, "  "),
      continuation = strrep(" ", indent + label_width + 2L)
    )
  }
  format_labeled_block <- function(
    entries,
    indent = 2L,
    width = getOption("width", 79L),
    max_label_width = 30L,
    label_width = NULL
  ) {
    if (!length(entries)) {
      return(character())
    }
    labels <- vapply(entries, "[[", "", "label")
    if (is.null(label_width)) {
      non_empty <- labels[nzchar(labels)]
      target <- if (length(non_empty)) non_empty else labels
      label_width <- min(max(nchar(target)), max_label_width)
    }
    out <- character()
    for (entry in entries) {
      ctx <- label_context(entry$label, indent, label_width)
      text <- entry$text
      if (!length(text)) {
        out <- c(out, ctx$initial)
        next
      }
      for (i in seq_along(text)) {
        content <- text[[i]]
        wrapped <- if (!nzchar(content)) {
          if (i == 1L) ctx$initial else ctx$continuation
        } else {
          lines <- strwrap(
            content,
            width = width,
            initial = if (i == 1L) ctx$initial else ctx$continuation,
            prefix = ctx$continuation
          )
          if (!length(lines)) {
            if (i == 1L) ctx$initial else ctx$continuation
          } else {
            lines
          }
        }
        out <- c(out, wrapped)
      }
    }
    out
  }
  format_option_block <- function(opts) {
    opts <- ensure_list(opts)
    if (!length(opts)) {
      return(character())
    }

    entries <- imap(opts, format_option_entry)
    flags <- vapply(entries, "[[", "", "label")
    flag_width <- min(max(nchar(flags)), 30L)
    indent <- 2L
    total_width <- getOption("width", 79L)
    formatted <- lapply(entries, function(entry) {
      pieces <- entry$pieces
      ctx <- label_context(entry$label, indent, flag_width)
      if (length(pieces) >= 2L && startsWith(pieces[[2L]], "[")) {
        combined <- paste(pieces[[1L]], pieces[[2L]], collapse = " ")
        fit <- strwrap(
          combined,
          width = total_width,
          initial = ctx$initial,
          prefix = ctx$continuation
        )
        if (length(fit) == 1L) {
          pieces <- c(combined, pieces[-(1:2)])
        }
      }
      if (length(pieces) >= 2L) {
        candidate <- paste(pieces[[1L]], pieces[[2L]], collapse = " ")
        line_candidate <- paste0(ctx$initial, candidate)
        if (nchar(line_candidate) <= total_width) {
          pieces <- c(candidate, pieces[-(1:2)])
        }
      }
      list(label = entry$label, text = pieces)
    })

    format_labeled_block(
      formatted,
      indent = indent,
      width = total_width,
      label_width = flag_width
    )
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
        text = desc
      )
    }

    if (!length(entries)) {
      return(character())
    }
    format_labeled_block(entries)
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
      label <- meta$title %||% meta$description %||% ""
      list(label = name, text = label)
    })

    format_labeled_block(entries)
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

  if (!is.null(app$launcher_name)) {
    scope[[1]]$name <- app$launcher_name
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

  title <- current_meta$title
  description <- current_meta$description

  if (length(scope) == 1L) {
    if (is.null(description) && is.null(title)) {
      description <- app_name
    }
  } else if (is.null(description) && is.null(title)) {
    description <- sprintf("%s command", utils::tail(full_command, 1L))
  }

  title_lines <- if (!is.null(title)) wrap_lines(title) else character()
  description_lines <- if (!is.null(description)) {
    wrap_lines(description)
  } else {
    character()
  }

  intro_lines <- character()
  if (length(title_lines)) {
    intro_lines <- c(intro_lines, title_lines, "")
  }
  intro_lines <- c(intro_lines, usage_line)
  if (length(description_lines)) {
    intro_lines <- c(intro_lines, "", description_lines)
  }

  sections <- list(intro_lines)

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
  while (length(sections) && utils::tail(sections, 1L) == "") {
    sections <- utils::head(sections, -1L)
  }
  writeLines(sections)
  return()
}
