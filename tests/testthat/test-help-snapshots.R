flip_app <- system.file("examples/flip-coin.R", package = "Rapp")
todo_app <- system.file("examples/todo.R", package = "Rapp")
nested_app <- test_path("apps", "nested-commands.R")

snapshot_env <- testthat::teardown_env()

add_launcher_default_packages <- function(path, packages) {
  lines <- readLines(path)
  if (any(grepl("^#\\| launcher:", lines))) {
    return(invisible())
  }
  packages <- paste(packages, collapse = ", ")
  insert <- c("#| launcher:", paste0("#|   default_packages: [", packages, "]"))
  lines <- c(lines[1L], insert, lines[-1L])
  writeLines(lines, path)
  invisible()
}

pkg <- paste0("rappHelpSnapshot", basename(tempfile("pkg")))
fake <- setup_fake_rapp_package(tempdir(), "-help-snapshots", package = pkg)
withr::defer(unlink(fake[["lib"]], recursive = TRUE), envir = snapshot_env)

stopifnot(file.copy(
  c(flip_app, todo_app, nested_app),
  fake[["exec"]],
  overwrite = TRUE
))

add_launcher_default_packages(
  file.path(fake[["exec"]], "flip-coin.R"),
  packages = c("base", "utils")
)
add_launcher_default_packages(
  file.path(fake[["exec"]], "todo.R"),
  packages = c("base", "utils", "yaml")
)
add_launcher_default_packages(
  file.path(fake[["exec"]], "nested-commands.R"),
  packages = c("base", "utils")
)

pkg_profile <- tempfile("rapp-test-profile", fileext = ".R")
pkg_root <- normalizePath(
  test_path("..", ".."),
  winslash = "/",
  mustWork = TRUE
)
profile_lines <- c(
  "try({",
  "  if (requireNamespace(\"pkgload\", quietly = TRUE)) {",
  paste0(
    "    pkgload::load_all(\"",
    pkg_root,
    "\", export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)"
  ),
  "  }",
  "}, silent = TRUE)"
)
writeLines(profile_lines, pkg_profile)
withr::defer(unlink(pkg_profile), envir = snapshot_env)
withr::local_envvar(R_PROFILE_USER = pkg_profile, .local_envir = snapshot_env)

destdir <- tempfile("rapp-help-bin")
dir.create(destdir, recursive = TRUE, showWarnings = FALSE)
withr::defer(unlink(destdir, recursive = TRUE), envir = snapshot_env)

old_no_modify <- Sys.getenv("RAPP_NO_MODIFY_PATH", unset = NA_character_)
Sys.setenv("RAPP_NO_MODIFY_PATH" = "1")
withr::defer(
  {
    if (is.na(old_no_modify)) {
      Sys.unsetenv("RAPP_NO_MODIFY_PATH")
    } else {
      Sys.setenv("RAPP_NO_MODIFY_PATH", old_no_modify)
    }
  },
  envir = snapshot_env
)

withr::with_envvar(c("RAPP_NO_MODIFY_PATH" = "1"), {
  suppressMessages(Rapp::install_pkg_cli_apps(
    pkg,
    destdir = destdir,
    lib.loc = fake[["lib"]],
    overwrite = TRUE
  ))
})

withr::local_path(destdir, .local_envir = snapshot_env)

test_that("--help snapshots", {
  expect_snapshot(write_cli_output("flip-coin", "--help"))
  expect_snapshot(write_cli_output("todo", "--help"))
  expect_snapshot(write_cli_output("nested-commands", "--help"))
})

test_that("command --help snapshots", {
  expect_snapshot(write_cli_output("todo", c("list", "--help")))
  expect_snapshot(write_cli_output("todo", c("done", "--help")))
  expect_snapshot(
    write_cli_output("nested-commands", c("parent", "child2", "--help"))
  )
})

# test_that("--help-full snapshots", {
#   expect_snapshot(
#     writeLines(system2("flip-coin", "--help-full", stdout = TRUE))
#   )
#   expect_snapshot(
#     writeLines(system2("todo", "--help-full", stdout = TRUE))
#   )
#   expect_snapshot(
#     writeLines(system2("nested-commands", "--help-full", stdout = TRUE))
#   )
# })

test_that("--help-yaml snapshots", {
  expect_snapshot(write_cli_output("flip-coin", "--help-yaml"))
  expect_snapshot(write_cli_output("todo", "--help-yaml"))
  expect_snapshot(write_cli_output("nested-commands", "--help-yaml"))
  expect_snapshot(write_cli_output("todo", c("list", "--help-yaml")))
  expect_snapshot(
    write_cli_output("nested-commands", c("parent", "child2", "--help-yaml"))
  )
})
