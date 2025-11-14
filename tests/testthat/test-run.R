erroring_app <- path(test_path("apps", "erroring-app.R"))
underscored_app <- path(test_path("apps", "underscored-command.R"))
cli_runner <- path(test_path("helpers", "rapp-cli-runner.R"))
exec_dir <- path(system.file("exec", package = "Rapp"))

run_cli_app <- function(app_path, args = character()) {
  res <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c("-e", shQuote(c("Rapp::run()", app_path)), args),
    stdout = TRUE,
    stderr = TRUE
  ))
  res
}

test_that("CLI invocation prints a hint before failing", {
  result <- run_cli_app(erroring_app)
  expect_true(attr(result, "status") != 0L)
  expect_snapshot(writeLines(run_cli_app(erroring_app)))
})

test_that("CLI handles underscored commands", {
  kebab_result <- run_cli_app(underscored_app, "foo-bar")
  snake_result <- run_cli_app(underscored_app, "foo_bar")
  expect_null(attr(kebab_result, "status"))
  expect_null(attr(snake_result, "status"))
  expect_snapshot({
    cat("-- foo-bar --\n")
    writeLines(kebab_result)
    cat("\n-- foo_bar --\n")
    writeLines(snake_result)
  })
})
