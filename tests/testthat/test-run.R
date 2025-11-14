erroring_app <- test_path("apps", "erroring-app.R")
underscored_app <- test_path("apps", "underscored-command.R")
cli_runner <- test_path("helpers", "rapp-cli-runner.R")
pkg_root <- normalizePath(test_path("..", ".."), winslash = "/", mustWork = TRUE)

run_cli_app <- function(app_path, args = character()) {
  res <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c(cli_runner, app_path, args),
    stdout = TRUE,
    stderr = TRUE,
    env = paste0("RAPP_PKG_ROOT=", pkg_root)
  ))
  status <- attr(res, "status")
  if (is.null(status)) status <- 0L
  stderr_lines <- attr(res, "stderr")
  output <- if (is.null(stderr_lines)) res else c(res, stderr_lines)
  attr(output, "status") <- status
  output
}

test_that("CLI invocation prints a hint before failing", {
  skip_if(testthat::is_parallel(), "CLI snapshot runs only in single-process mode")
  result <- run_cli_app(erroring_app)
  expect_true(attr(result, "status") != 0L)
  expect_snapshot(writeLines(run_cli_app(erroring_app)))
})

test_that("CLI handles underscored commands", {
  skip_if(testthat::is_parallel(), "CLI snapshot runs only in single-process mode")
  result <- run_cli_app(underscored_app, "foo-bar")
  expect_identical(attr(result, "status"), 0L)
  expect_snapshot(writeLines(run_cli_app(underscored_app, "foo-bar")))
})
