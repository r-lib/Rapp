#' Install CLI launchers for package scripts
#'
#' `install_pkg_cli_apps()` scans an installed package's `exec/` directory for
#' `.R` scripts whose shebang line invokes `Rapp` (for example, `#!/usr/bin/env
#' Rapp`) or `Rscript` (for example, `#!/usr/bin/env Rscript`). Each discovered
#' script gets a lightweight launcher in `destdir` that invokes `Rapp` or
#' `Rscript` to run the app. The launcher encodes the absolute path to the R
#' binary this function is called from, and its name defaults to the script
#' basename without the `.R` extension.
#'
#' Optional `#| launcher:` front matter in the script lets authors set the
#' installed launcher `name` and tune the `Rscript` flags. By default, package
#' apps are invoked with `--default-packages=base,<pkg>`, where `<pkg>` is the
#' package providing the executable. The top-level `Rapp` launcher installed by
#' `install_pkg_cli_apps("Rapp")` invokes `Rscript -e Rapp::run()` without
#' package app defaults.
#'
#' @param package Package names to process. Defaults to the calling package when
#'   run inside a package; otherwise all installed packages.
#' @param destdir Directory to write launchers to. See Details for defaults.
#' @param lib.loc Additional library paths forwarded to [base::system.file()]
#'   while locating package scripts. Discovery happens at install time; written
#'   launchers embed absolute script paths.
#' @param overwrite Whether to replace an existing executable. `TRUE` always
#'   overwrites, `FALSE` never overwrites non-Rapp executables, and `NA` (the
#'   default) prompts interactively and otherwise skips.
#'
#' @return Invisibly returns the paths of launchers that were (re)written.
#'
#' @details
#'
#' Launchers are regenerated each time `install_pkg_cli_apps()` is called, and
#' any obsolete launchers for the same package are removed. `RAPP_BIN_DIR`
#' overrides the default destination. Launchers are POSIX shell scripts on
#' Unix-like systems and `.bat` files on Windows. Front-matter options such as
#' `name`, `vanilla`, `no-environ`, and `default-packages` map directly to the
#' corresponding `Rscript` arguments.
#'
#' When `overwrite` is `NA`, files previously written by Rapp are always
#' replaced while other executables trigger a confirmation prompt (skipped in
#' non-interactive sessions). A warning is emitted when skipping an existing
#' executable.
#'
#' If `destdir` is not provided, it is resolved in this order:
#'   - env var `RAPP_BIN_DIR`
#'   - env var `XDG_BIN_HOME`
#'   - env var `XDG_DATA_HOME/../bin`
#'   - the default location:
#'     - macOS and Linux: `~/.local/bin`,
#'     - Windows: `%LOCALAPPDATA%\Programs\R\Rapp\bin`
#'
#' On Windows, the resolved `destdir` is explicitly added to `PATH` (it
#' generally is not by default). On macOS, when the default `~/.local/bin`
#' destination is not already on `PATH`, it is added to `~/.zprofile`, or
#' `$ZDOTDIR/.zprofile` when `ZDOTDIR` is set. If the profile cannot be
#' updated, a warning is emitted and installation continues. To disable adding
#' it to the `PATH`, set envvar `RAPP_NO_MODIFY_PATH=1`.
#'
#' On Linux, `~/.local/bin` is typically already on `PATH` if it
#' exists. Note: some shells add `~/.local/bin` to `PATH` only if it exists at
#' login. If `install_pkg_cli_apps()` created the directory, you may need to
#' restart the shell for the new apps to be found on `PATH`.
#'
#' Example setting `launcher` args:
#'
#' ```r
#' #!/usr/bin/env Rapp
#' #| description: About this app
#' #| launcher:
#' #|   name: about
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
  lib.loc = NULL,
  overwrite = NA
) {
  destdir <- destdir %||% rapp_install_dir()
  dir.exists(destdir) ||
    dir.create(destdir, recursive = TRUE) ||
    stop("Failed to create directory: ", destdir)

  if (is_windows()) {
    ensure_path_windows(destdir)
  } else if (is_macos()) {
    ensure_path_macos(destdir)
  }

  # existing Rapp launchers we're either overwriting or deleting
  existing <- list_existing_rapp_launchers(destdir)

  package <- if ("Rapp" %in% package) {
    c(setdiff(package, "Rapp"), "Rapp")
  } else {
    unique(package)
  }

  names(package) <- package
  created <- lapply(package, function(pkg) {
    install_one_package(
      package = pkg,
      destdir = destdir,
      lib.loc = lib.loc,
      existing = existing[[pkg]],
      overwrite = overwrite
    )
  })

  invisible(if (length(package) == 1L) created[[1L]] else compact(created))
}

#' @export
#' @rdname install_pkg_cli_apps
uninstall_pkg_cli_apps <- function(
  package = parent.pkg(),
  destdir = NULL
) {
  existing <- list_existing_rapp_launchers(destdir %||% rapp_install_dir())
  if (!is.null(package)) {
    existing <- existing[names(existing) %in% package]
  }
  if ("Rapp" %in% names(existing)) {
    existing <- existing[c(setdiff(names(existing), "Rapp"), "Rapp")]
  }
  invisible(imap(existing, function(paths, pkg) {
    file.remove(paths)
    msg <- sprintf("deleted: %s (from package %s)", paths, pkg)
    message(paste0(msg, collapse = "\n"))
    paths
  }))
}


install_one_package <- function(
  package,
  destdir,
  lib.loc,
  existing = character(),
  overwrite = NA
) {
  app_paths <- list_package_apps(package = package, lib.loc = lib.loc)
  created <- map_chr(
    app_paths,
    function(app_path) {
      target <- launcher_path(app_path, destdir)
      if (file.exists(target)) {
        is_rapp <- target %in% existing
        if (!should_overwrite(target, overwrite, is_rapp)) {
          return(NA_character_)
        }
      }
      script <- launcher_contents(app_path, package)
      writeLines(script, target)
      Sys.chmod(target, mode = "0755") # set executable
      message("created: ", target, " (from package ", package, ")")
      target
    }
  )
  created <- created[!is.na(created)]

  if (package == "Rapp") {
    append(created) <- install_rapp_launcher(destdir, overwrite = overwrite)
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
  files[map_lgl(files, function(f) !is.na(get_launcher_type(f)))]
}


get_launcher_type <- function(app_path) {
  shebang <- tryCatch(
    readLines(app_path, n = 1, warn = FALSE),
    error = function(e) NULL
  )
  if (!length(shebang) || !startsWith(shebang, "#!/")) {
    return(NA_character_)
  }

  if (grepl("\\bRapp\\b", shebang, perl = TRUE)) {
    "Rapp"
  } else if (grepl("\\bRscript\\b", shebang, perl = TRUE)) {
    "Rscript"
  } else {
    NA_character_
  }
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
  data <- get_app_data(app_path)
  name <-
    data[["launcher"]][["name"]] %||%
    data[["name"]] %||%
    sub("\\.[rR]$", "", basename(app_path))
  switch(
    .Platform$OS.type,
    windows = path(destdir, paste0(name, ".bat")),
    unix = path(destdir, name)
  )
}


launcher_contents <- function(app_path, package) {
  app_path <- normalizePath(app_path, mustWork = TRUE)
  launcher_type <- get_launcher_type(app_path)
  if (is.na(launcher_type)) {
    stop("Unsupported launcher type for ", app_path)
  }

  app_data <- get_app_data(app_path)
  launcher_name <-
    app_data[["launcher"]][["name"]] %||%
    app_data[["name"]] %||%
    sub("\\.[rR]$", "", basename(app_path))
  # if (!nzchar(launcher_name) || !grepl("^[[:alnum:]_-]+$", launcher_name)) {
  #   stop("Launcher name must match ^[[:alnum:]_-]+$")
  # }

  rscript_opts <- app_data[["launcher"]]

  default_packages <- rscript_opts[["default_packages"]] %||% c("base", package)
  default_packages <- if (length(default_packages)) {
    shQuote(sprintf(
      "--default-packages=%s",
      paste(default_packages, collapse = ",")
    ))
  } else {
    NULL
  }

  # assemble rscript opts
  rscript_opts <- c(
    if (isTRUE(rscript_opts[["vanilla"]])) "--vanilla",
    if (isTRUE(rscript_opts[["no_environ"]])) "--no-environ",
    if (isTRUE(rscript_opts[["no_site_file"]])) "--no-site-file",
    if (isTRUE(rscript_opts[["no_init_file"]])) "--no-init-file",
    if (isTRUE(rscript_opts[["restore"]])) "--restore",
    if (isTRUE(rscript_opts[["save"]])) "--save",
    if (isTRUE(rscript_opts[["verbose"]])) "--verbose",
    default_packages
  )
  rscript_opts <- paste0(rscript_opts, collapse = " ")

  sentinel <- sprintf(
    'Generated by `Rapp::install_pkg_cli_apps(package = "%s")`. Do not edit by hand.',
    package
  )

  if (is_windows()) {
    cmd <- c(
      sprintf('"%s/Rscript.exe"', R.home("bin")),
      if (nzchar(rscript_opts)) rscript_opts,
      if (identical(launcher_type, "Rapp")) "-e Rapp::run()",
      sprintf('"%s"', app_path),
      "%*"
    )
    c(
      "@echo off",
      paste("::", sentinel),
      "setlocal",
      sprintf(
        'set "RAPP_LAUNCHER_NAME=%s"',
        shQuote(launcher_name, type = "cmd2")
      ),
      paste0(cmd, collapse = " ")
    )
  } else {
    cmd <- c(
      sprintf("%s/Rscript", R.home("bin")),
      if (nzchar(rscript_opts)) rscript_opts,
      if (identical(launcher_type, "Rapp")) "-e 'Rapp::run()'",
      sprintf("'%s'", app_path),
      '"$@"'
    )
    c(
      "#!/bin/sh",
      paste("#", sentinel),
      sprintf(
        "export RAPP_LAUNCHER_NAME=%s",
        shQuote(launcher_name)
      ),
      paste("exec", paste0(cmd, collapse = " "))
    )
  }
}


should_overwrite <- function(target, overwrite, is_rapp = NA) {
  if (!file.exists(target)) {
    return(TRUE)
  }

  is_rapp <- if (is.na(is_rapp)) {
    !is.na(get_rapp_launcher_package(target))
  } else {
    isTRUE(is_rapp)
  }

  if (is_rapp) {
    return(TRUE)
  }

  warn_skip <- function() {
    warning(
      sprintf(
        "Skipping existing executable %s; set overwrite = TRUE to replace it.",
        target
      ),
      call. = FALSE
    )
    FALSE
  }

  if (isTRUE(overwrite)) {
    return(TRUE)
  }

  if (isTRUE(overwrite)) {
    return(warn_skip())
  }

  if (!interactive()) {
    return(warn_skip())
  }

  prompt <- sprintf(
    "%s already exists but was not created by Rapp. Overwrite?",
    target
  )
  response <- utils::askYesNo(prompt, default = FALSE)
  if (isTRUE(response)) {
    return(TRUE)
  }

  warn_skip()
}

install_rapp_launcher <- function(destdir, overwrite = NA) {
  target <- switch(
    .Platform$OS.type,
    windows = path(destdir, "Rapp.bat"),
    unix = path(destdir, "Rapp")
  )

  if (!should_overwrite(target, overwrite)) {
    return(character())
  }

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
        '"%s/Rscript.exe" -e Rapp::run() %%*',
        R.home("bin")
      )
    ),
    unix = c(
      "#!/bin/sh",
      paste("#", sentinel),
      sprintf(
        'exec %s/Rscript -e "Rapp::run()" "$@"',
        R.home("bin")
      )
    )
  )

  writeLines(lines, target)
  Sys.chmod(target, mode = "0755")
  message("created: ", target, " (from package Rapp)")
  target
}


list_existing_rapp_launchers <- function(destdir) {
  executables <- path(list.files(destdir, full.names = TRUE))

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

  if (path_has_dir_windows(destdir)) {
    return(FALSE)
  }

  # Check if we're already on the user-level PATH. If we are, do nothing.
  # Read current PATH from HKCU\Environment.
  path <- unique(raw_path_entries(get_env_win_registry("Path")))
  present <- path_norm_windows(destdir) %in% path_norm_windows(path)
  if (present) {
    return(FALSE)
  }

  # We are not on the PATH yet, we have to add it
  # Pass the new path entry via envvar to avoid quoting and encoding shenanigans
  # and also propagate the new entry to this R session.
  old <- Sys.getenv("RAPP_NEW_PATH_ENTRY", NA_character_)
  old_path <- Sys.getenv("PATH")
  Sys.setenv("RAPP_NEW_PATH_ENTRY" = destdir)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("RAPP_NEW_PATH_ENTRY")
    } else {
      Sys.setenv("RAPP_NEW_PATH_ENTRY" = old)
    }
  })

  script <- shQuote(utils::shortPathName(
    system.file("add-path-entry.ps1", package = "Rapp")
  ))
  args <- c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script)
  status <- system2("powershell", args)
  if (!identical(status, 0L)) {
    warning(
      "Could not add ",
      destdir,
      " to the user-level PATH; powershell exited with status ",
      status,
      ".",
      call. = FALSE
    )
    return(FALSE)
  }

  Sys.setenv("PATH" = prepend_path_entry(destdir, old_path))
  TRUE
}

get_env_win_registry <- function(name) {
  utils::readRegistry("Environment", hive = "HCU", view = "default")[[name]]
}

ensure_path_macos <- function(destdir = rapp_install_dir()) {
  if (Sys.getenv("RAPP_NO_MODIFY_PATH") != "") {
    return(FALSE)
  }
  stopifnot(is_macos())

  destdir <- normalizePath(destdir, mustWork = TRUE)
  if (!identical(destdir, macos_default_install_dir())) {
    return(FALSE)
  }
  if (path_has_dir(destdir)) {
    return(FALSE)
  }

  zprofile <- macos_zprofile()
  zprofile_display <- macos_zprofile_display(zprofile)
  lines <- macos_path_lines()

  if (profile_has_lines(zprofile, lines)) {
    warning(
      "~/.local/bin PATH setup is already present in ",
      zprofile_display,
      ", ",
      "but ~/.local/bin is still not on PATH.\n",
      "Restart your shell, or run:\n\n",
      "  source ", zprofile_display,
      call. = FALSE
    )
  } else if (write_macos_path_lines(zprofile, lines, zprofile_display)) {
    message(
      "Added ~/.local/bin to PATH in ", zprofile_display, ".\n",
      "Restart your shell, or run:\n\n",
      "  source ", zprofile_display
    )
  }

  Sys.setenv(PATH = paste(destdir, Sys.getenv("PATH"), sep = .Platform$path.sep))
  TRUE
}

macos_default_install_dir <- function() {
  normalizePath(file.path(path.expand("~"), ".local", "bin"), mustWork = FALSE)
}

macos_zprofile <- function() {
  zdotdir <- Sys.getenv("ZDOTDIR")
  if (!nzchar(zdotdir)) {
    zdotdir <- path.expand("~")
  }
  path(zdotdir, ".zprofile")
}

macos_zprofile_display <- function(zprofile) {
  if (identical(path(zprofile), path(path.expand("~"), ".zprofile"))) {
    "~/.zprofile"
  } else {
    zprofile
  }
}

macos_path_lines <- function() {
  c(
    'case ":$PATH:" in',
    '  *:"$HOME/.local/bin":*) ;;',
    '  *) export PATH="$HOME/.local/bin:$PATH" ;;',
    "esac"
  )
}

profile_has_lines <- function(profile, lines) {
  if (!file.exists(profile)) {
    return(FALSE)
  }
  profile <- tryCatch(
    paste(readLines(profile, warn = FALSE), collapse = "\n"),
    error = function(e) "",
    warning = function(w) ""
  )
  grepl(paste(lines, collapse = "\n"), profile, fixed = TRUE)
}

write_macos_path_lines <- function(profile, lines, profile_display) {
  tryCatch(
    {
      suppressWarnings(cat(
        paste0(c("", lines), collapse = "\n"),
        "\n",
        file = profile,
        append = TRUE,
        sep = ""
      ))
      TRUE
    },
    error = function(e) {
      warning(
        "Could not add ~/.local/bin to PATH in ",
        profile_display,
        ": ",
        conditionMessage(e),
        call. = FALSE
      )
      FALSE
    }
  )
}

path_has_dir <- function(dir, env_path = Sys.getenv("PATH")) {
  normalizePath(dir, mustWork = FALSE) %in% path_entries(env_path)
}

path_has_dir_windows <- function(dir, env_path = Sys.getenv("PATH")) {
  path_norm_windows(dir) %in% path_norm_windows(raw_path_entries(env_path))
}

path_norm_windows <- function(x) {
  tolower(normalizePath(x, winslash = "\\", mustWork = FALSE))
}

prepend_path_entry <- function(dir, env_path = Sys.getenv("PATH")) {
  paste(c(dir, raw_path_entries(env_path)), collapse = .Platform$path.sep)
}

raw_path_entries <- function(env_path = Sys.getenv("PATH")) {
  if (is.null(env_path) || !length(env_path) || is.na(env_path)) {
    return(character())
  }
  entries <- strsplit(env_path, .Platform$path.sep, fixed = TRUE)[[1L]]
  entries[nzchar(entries)]
}

path_entries <- function(env_path = Sys.getenv("PATH")) {
  normalizePath(raw_path_entries(env_path), mustWork = FALSE)
}

is_macos <- function() {
  identical(Sys.info()[["sysname"]], "Darwin")
}

path <- function(...) {
  normalizePath(file.path(...), mustWork = FALSE)
}
