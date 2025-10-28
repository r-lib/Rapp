is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

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
