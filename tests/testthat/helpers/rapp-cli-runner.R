args <- commandArgs(trailingOnly = TRUE)

if (!length(args)) {
  stop("App path must be supplied.", call. = FALSE)
}

pkg_root <- Sys.getenv("RAPP_PKG_ROOT", unset = NA_character_)
if (is.na(pkg_root) || !nzchar(pkg_root)) {
  stop("RAPP_PKG_ROOT must be set to the package root.", call. = FALSE)
}
pkg_root <- normalizePath(pkg_root, winslash = "/", mustWork = TRUE)
r_dir <- file.path(pkg_root, "R")
r_files <- sort(list.files(r_dir, pattern = "\\.[rR]$", full.names = TRUE))
pkg_env <- new.env(parent = baseenv())
for (file in r_files) {
  sys.source(file, envir = pkg_env)
}

app <- args[[1]]
cli_args <- if (length(args) > 1) args[-1] else character()

pkg_env$run(app, args = cli_args)
