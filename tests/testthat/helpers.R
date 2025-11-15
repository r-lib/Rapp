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

capture_help_lines <- function(
  app_path,
  command_path = character(),
  full = FALSE
) {
  app <- Rapp:::as_app(app_path)
  lines <- capture.output(Rapp:::print_app_help(
    app,
    yaml = FALSE,
    command_path = command_path
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
  lines <- capture.output(Rapp:::print_app_help(
    app,
    yaml = TRUE,
    command_path = command_path
  ))
  if (length(lines) && identical(tail(lines, 1L), "NULL")) {
    lines <- head(lines, -1L)
  }
  lines
}

capture_app_env <- function(app_path, args = character()) {
  app <- Rapp:::as_app(app_path)
  Rapp:::process_args(args, app)
  run_env <- new.env(parent = baseenv())
  capture.output({
    for (expr in app$exprs) {
      eval(expr, run_env)
    }
  })
  as.list(run_env, all.names = TRUE)
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
