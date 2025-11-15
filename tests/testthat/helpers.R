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

local_rapp_app <- function(
  lines,
  prefix = "rapp-app-",
  fileext = ".R",
  .local_envir = parent.frame()
) {
  app_path <- tempfile(prefix, fileext = fileext)
  writeLines(lines, app_path)
  withr::defer(unlink(app_path), envir = .local_envir)
  app_path
}

local_rapp_script <- function(
  lines,
  prefix = "rapp-app-",
  fileext = ".R",
  .local_envir = parent.frame()
) {
  if (!length(lines) || !startsWith(lines[[1L]], "#!/")) {
    lines <- c("#!/usr/bin/env Rapp", lines)
  }
  local_rapp_app(
    lines,
    prefix = prefix,
    fileext = fileext,
    .local_envir = .local_envir
  )
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

help_lines <- function(
  app_path,
  command_path = character(),
  format = c("text", "yaml")
) {
  format <- match.arg(format)
  app <- Rapp:::as_app(app_path)
  lines <- capture.output(Rapp:::print_app_help(
    app,
    yaml = identical(format, "yaml"),
    command_path = command_path
  ))
  if (length(lines) && identical(tail(lines, 1L), "NULL")) {
    lines <- head(lines, -1L)
  }
  lines
}

help_lines_from_script <- function(
  lines,
  command_path = character(),
  format = c("text", "yaml"),
  prefix = "rapp-help-",
  .local_envir = parent.frame()
) {
  app_path <- local_rapp_script(
    lines,
    prefix = prefix,
    .local_envir = .local_envir
  )
  help_lines(app_path, command_path = command_path, format = format)
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

run_cli_app <- function(command, args = character()) {
  system2(command, args, stdout = TRUE)
}

write_cli_output <- function(command, args = character()) {
  writeLines(run_cli_app(command, args))
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
