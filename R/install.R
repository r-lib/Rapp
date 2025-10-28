#' Install CLI launchers for package scripts
#'
#' `install_pkg_cli_apps()` scans an installed package's `exec/` directory for
#' `.R` scripts whose shebang references `Rapp` (for example, `#!/usr/bin/env Rapp` or
#' `#!/usr/bin/env -S Rscript -e 'Rapp::run()'`). Each discovered
#' script gets a lightweight wrapper in `destdir` that invokes `Rscript` to run the Rapp. Optional `#| launcher:` front
#' matter in the script lets authors tune the `Rscript` flags.
#'
#' @param package Package names to process. Defaults to the calling package when
#'   run inside a package; otherwise all installed packages.
#' @param destdir Directory to write launchers to. See Details for defaults.
#' @param lib.loc Additional library paths forwarded to [base::system.file()]
#'   while locating package scripts. Discovery happens at install time; written
#'   launchers embed absolute script paths.
#'
#' @return Invisibly returns the paths of launchers that were (re)written.
#'
#' @details Launchers are regenerated on every run, and any obsolete launchers
#'   for the same package are removed. `RAPP_INSTALL_DIR` overrides the default
#'   destination. Launchers are POSIX shell scripts on Unix-like systems and
#'   `.bat` files on Windows. Front-matter options such as `vanilla`,
#'   `no-environ`, and `default_packages` map directly to the corresponding
#'   `Rscript` arguments.
#'
#'   If `destdir` is not provided, it is resolved in this order:
#'   - env var `RAPP_INSTALL_DIR`
#'   - env var `XDG_BIN_HOME`
#'   - env var `XDG_DATA_HOME/../bin`
#'   - `~/.local/bin` (The default install location)
#'
#'   On Windows, the location is explicitly added to `PATH` (it generally is not
#'   by default). On macOS or Linux, `~/.local/bin` is typically on `PATH` if it
#'   exists. Note: some shells add `~/.local/bin` to `PATH` only if it exists at
#'   login. If `install_pkg_cli_apps()` created the directory, you may need to
#'   restart the shell for the new apps to be found on `PATH`.
#'
#' ```r
#' #!/usr/bin/env Rapp
#' #| description: About this app
#' #| launcher:
#' #|   vanilla: true
#' #|   default-packages: [base, utils, mypkg]
#' ```
#' @export
#'
#' @examples
#' \dontrun{
#' # Install the launcher for the Rapp package itself: `Rapp`
#' install_pkg_cli_apps("Rapp")
#' }

install_pkg_cli_apps <- function(
  package = parent.pkg() %||% rownames(utils::installed.packages()),
  destdir = NULL,
  lib.loc = NULL
) {
  destdir <- destdir %||% rapp_install_dir()
  dir.exists(destdir) ||
    dir.create(destdir, recursive = TRUE) ||
    stop("Failed to create directory: ", destdir)

  if (is_windows()) {
    ensure_path_windows(destdir)
  }

  existing <- list_existing_rapp_launchers(destdir)

  names(package) <- package
  created <- compact(lapply(package, function(pkg) {
    install_one_package(
      package = pkg,
      destdir = destdir,
      lib.loc = lib.loc,
      existing = existing[[pkg]]
    )
  }))

  invisible(switch(length(package), created[[1L]], created))
}


install_one_package <- function(
  package,
  destdir,
  lib.loc,
  existing = character()
) {
  app_paths <- list_package_apps(package = package, lib.loc = lib.loc)
  created <- map_chr(
    app_paths,
    function(app_path) {
      target <- launcher_path(app_path, destdir)
      script <- launcher_contents(app_path, package)
      writeLines(script, target)
      Sys.chmod(target, mode = "0755") # set executable
      message("created: ", target)
      target
    }
  )

  if ("Rapp" %in% package) {
    created <- c(created, list(Rapp = install_rapp_launcher(destdir)))
  }

  orphaned <- setdiff(
    normalizePath(as.character(existing)),
    normalizePath(created)
  )
  for (o in orphaned) {
    file.remove(o)
    message("deleted: ", o)
  }

  unname(created)
}


list_package_apps <- function(package, lib.loc = NULL) {
  exec_dir <- system.file("exec", package = package, lib.loc = lib.loc)
  dir.exists(exec_dir) || return()
  files <- list.files(exec_dir, pattern = "\\.[Rr]$", full.names = TRUE)
  files[map_lgl(files, \(f) {
    first_line <- readLines(f, n = 1, warn = FALSE)
    length(first_line) && grepl("\\bRapp\\b", first_line, perl = TRUE)
  })]
}


rapp_install_dir <- function() {
  getenv <- function(x) Sys.getenv(x, NA_character_)
  is_set <- function(x) !is.na(x) && nzchar(x)

  path <- if (is_set(p <- getenv("RAPP_BIN_DIR"))) {
    p
  } else if (is_set(p <- getenv("XDG_BIN_HOME"))) {
    p
  } else if (is_set(p <- getenv("XDG_DATA_HOME"))) {
    file.path(dirname(p), "bin")
  } else {
    switch(
      .Platform$OS.type,
      unix = "~/.local/bin",
      windows = {
        base <- if (is_set(p <- getenv("LOCALAPPDATA"))) {
          p
        } else if (is_set(p <- getenv("USERPROFILE"))) {
          file.path(p, "AppData", "Local")
        } else {
          path.expand("~/AppData/Local")
        }
        file.path(base, "Programs", "R", "Rapp", "bin")
      }
    )
  }
  normalizePath(path, mustWork = FALSE)
}


launcher_path <- function(app_path, destdir) {
  name <- sub("\\.[rR]$", "", basename(app_path))
  switch(
    .Platform$OS.type,
    windows = path(destdir, paste0(name, ".bat")),
    unix = path(destdir, name)
  )
}


launcher_contents <- function(app_path, package) {
  app_path <- normalizePath(app_path, mustWork = TRUE)
  rscript_opts <- get_app_data(app_path)$launcher

  default_packages <- rscript_opts$default_packages %||% c("base", package)
  default_packages <- if (length(default_packages)) {
    shQuote(sprintf(
      "--default-packages=%s",
      paste(default_packages, collapse = ",")
    ))
  } else {
    NULL
  }

  # assemble rscript opts
  rscript_opts <- paste0(
    c(
      if (isTRUE(rscript_opts$vanilla)) "--vanilla",
      if (isTRUE(rscript_opts$`no-environ`)) "--no-environ",
      if (isTRUE(rscript_opts$`no-site-file`)) "--no-site-file",
      if (isTRUE(rscript_opts$`no-init-file`)) "--no-init-file",
      if (isTRUE(rscript_opts$restore)) "--restore",
      if (isTRUE(rscript_opts$save)) "--save",
      if (isTRUE(rscript_opts$verbose)) "--verbose",
      default_packages
    ),
    collapse = " "
  )

  sentinel <- sprintf(
    'Generated by `Rapp::install_pkg_cli_apps(package = "%s")`. Do not edit by hand.',
    package
  )

  lines <- switch(
    .Platform$OS.type,
    "windows" = c(
      "@echo off",
      paste("::", sentinel),
      "setlocal",
      sprintf(
        r"("%s/Rscript.exe" %s -e Rapp::run() "%s" %%*))",
        R.home("bin"),
        rscript_opts,
        app_path
      )
    ),
    unix = c(
      "#!/bin/sh",
      paste("#", sentinel),
      # "set -eu",
      sprintf(
        r"(exec %s/Rscript %s -e 'Rapp::run()' '%s' "$@")",
        R.home("bin"),
        rscript_opts,
        app_path
      )
    )
  )
  lines
}


install_rapp_launcher <- function(destdir) {
  target <- switch(
    .Platform$OS.type,
    windows = path(destdir, "Rapp.bat"),
    unix = path(destdir, "Rapp")
  )

  sentinel <- sprintf(
    'Generated by `Rapp::install_pkg_cli_apps(package = "%s")`. Do not edit by hand.',
    "Rapp"
  )

  lines <- switch(
    .Platform$OS.type,
    windows = c(
      "@echo off",
      paste("::", sentinel),
      "setlocal",
      sprintf(
        r"("%s/Rscript.exe" -e Rapp::run() %%*)",
        R.home("bin")
      )
    ),
    unix = c(
      "#!/bin/sh",
      paste("#", sentinel),
      sprintf(
        r"(exec %s/Rscript -e 'Rapp::run()' "$@")",
        R.home("bin")
      )
    )
  )

  writeLines(lines, target)
  Sys.chmod(target, mode = "0755")
  message("created: ", target)
  target
}


list_existing_rapp_launchers <- function(destdir) {
  executables <- list.files(destdir, full.names = TRUE)

  launcher_pkg <- map_chr(executables, get_rapp_launcher_package)
  is_launcher <- !is.na(launcher_pkg)

  executables <- executables[is_launcher]
  launcher_pkg <- launcher_pkg[is_launcher]

  split(executables, launcher_pkg)
}

get_rapp_launcher_package <- function(path) {
  expected_header <- switch(
    .Platform$OS.type,
    unix = charToRaw("#!/bin/sh"),
    windows = {
      endsWith(path, ".bat") || return(NA_character_)
      charToRaw("@echo off")
    }
  )
  header <- tryCatch(
    readBin(path, "raw", length(expected_header)),
    error = function(e) NULL,
    warning = function(w) NULL
  )
  identical(header, expected_header) || return(NA_character_)

  lines <- tryCatch(
    readLines(path, warn = FALSE, n = 2L),
    error = function(e) NULL
  )
  identical(length(lines), 2L) || return(NA_character_)
  pkg <- sub(
    '^(::|#) Generated by `Rapp::install_pkg_cli_apps\\(package = "([[:alnum:]]+)"\\)`\\. Do not edit by hand\\.$',
    "\\2",
    lines[2]
  )
  if (identical(pkg, lines[2])) NA_character_ else pkg
}


# Ensure a directory is first on the user PATH (Windows)
ensure_path_windows <- function(destdir = rapp_install_dir()) {
  if (Sys.getenv("RAPP_NO_MODIFY_PATH") != "") {
    return(FALSE)
  }
  stopifnot(.Platform$OS.type == "windows")
  destdir <- normalizePath(destdir, winslash = "\\", mustWork = TRUE)

  # Check if we're already on PATH. If we are, do nothing
  # Read current PATH from HKCU\Environment
  path <- get_env_win_registry("Path")
  path <- strsplit(path, ";", fixed = TRUE)[[1L]]
  path <- path[nzchar(path)]
  path <- unique(path)

  path_norm <- function(x) tolower(normalizePath(x, mustWork = FALSE))
  present <- path_norm(destdir) %in% path_norm(path)
  if (present) {
    return(FALSE)
  }

  # We are not on the PATH yet, we have to add it
  # Pass the new path entry via envvar to avoid quoting and encoding shenanigans
  # also, propogate the new updated PATH from the registry to this R session
  old <- Sys.getenv("RAPP_NEW_PATH_ENTRY", NA_character_)
  Sys.setenv("RAPP_NEW_PATH_ENTRY" = destdir)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("RAPP_NEW_PATH_ENTRY")
    } else {
      Sys.setenv("RAPP_NEW_PATH_ENTRY" = old)
    }
    Sys.setenv("PATH" = get_env_win_registry("Path"))
  })

  script <- shQuote(utils::shortPathName(
    system.file("add-path-entry.ps1", package = "Rapp")
  ))
  args <- c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script)
  system2("powershell", args)
}

get_env_win_registry <- function(name) {
  utils::readRegistry("Environment", hive = "HCU", view = "default")[[name]]
}

path <- function(...) {
  normalizePath(file.path(...), mustWork = FALSE)
}
