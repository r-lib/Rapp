is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

# options(Rapp.quit_on_error = FALSE)

setup_fake_rapp_package <- function(base, suffix, package = "Rapp") {
  dir.create(base, recursive = TRUE, showWarnings = FALSE)

  lib_dir <- file.path(
    base,
    paste0("lib-", Sys.getpid(), suffix)
  )
  unlink(lib_dir, recursive = TRUE, force = TRUE)

  exec_dir <- file.path(lib_dir, package, "exec")
  dir.create(exec_dir, recursive = TRUE)

  desc_path <- file.path(lib_dir, package, "DESCRIPTION")
  writeLines(c(paste0("Package: ", package), "Version: 0.0.0"), desc_path)

  list(lib = lib_dir, exec = exec_dir, package = package)
}


path <- function(...) {
  normalizePath(file.path(...), mustWork = FALSE)
}

normalize_paths <- function(paths) {
  normalizePath(paths, mustWork = FALSE)
}

expect_same_path <- function(actual, expected) {
  testthat::expect_equal(normalize_paths(actual), normalize_paths(expected))
}

expect_same_paths_set <- function(actual, expected) {
  testthat::expect_setequal(normalize_paths(actual), normalize_paths(expected))
}

build_help_scope <- function(app, command_path = character()) {
  app_name <- app$data$name
  if (is.null(app_name)) {
    app_name <- basename(app$filepath)
  }
  scope <- list(list(
    name = app_name,
    opts = app$opts,
    args = app$args,
    commands = if (is.null(app$commands)) list() else app$commands,
    meta = if (length(app$data)) {
      Rapp:::prune_empty(as.list(unclass(app$data)))
    } else {
      NULL
    }
  ))

  commands <- if (is.null(app$commands)) list() else app$commands
  for (cmd in command_path) {
    command <- commands[[cmd]]
    if (is.null(command)) {
      break
    }
    meta <- if (!is.null(command$meta)) {
      Rapp:::prune_empty(as.list(unclass(command$meta)))
    } else {
      NULL
    }
    scope[[length(scope) + 1L]] <- list(
      name = cmd,
      opts = command$opts,
      args = command$args,
      commands = if (is.null(command$commands)) list() else command$commands,
      meta = meta
    )
    commands <- if (is.null(command$commands)) list() else command$commands
  }
  scope
}

capture_help_lines <- function(
  app_path,
  command_path = character(),
  full = FALSE
) {
  app <- Rapp:::as_app(app_path)
  scope <- build_help_scope(app, command_path)
  lines <- capture.output(Rapp:::print_app_help(
    app,
    yaml = FALSE,
    scope = scope
  ))
  if (length(lines) && identical(tail(lines, 1L), "NULL")) {
    lines <- head(lines, -1L)
  }
  lines
}

capture_help_yaml <- function(
  app_path,
  command_path = character(),
  full = FALSE,
  variant = NULL
) {
  app <- Rapp:::as_app(app_path)
  scope <- build_help_scope(app, command_path)
  lines <- capture.output(Rapp:::print_app_help(
    app,
    yaml = TRUE,
    scope = scope,
    full = full
  ))
  if (length(lines) && identical(tail(lines, 1L), "NULL")) {
    lines <- head(lines, -1L)
  }
  lines
}


# tryCatch(
#   eval(app$exprs, new.env(parent = globalenv())),
#   error = function(e) {
#     if (interactive() || !getOption("Rapp.quit_on_error", TRUE)) {
#       stop(e)
#     }
#     print_error_like_stop(e)
#     print_help_hint()
#     quit(save = "no", status = 1L, runLast = FALSE)
#   }
# )

print_error_like_stop <- function(err) {
  call <- conditionCall(err)
  prefix <- if (!is.null(call)) {
    sprintf("Error in %s : ", deparse(call)[1])
  } else {
    "Error: "
  }
  cat(prefix, conditionMessage(err), "\n", file = stderr(), sep = "")
}

print_help_hint <- function() {
  message("Hint: run with --help to view usage information.")
}
