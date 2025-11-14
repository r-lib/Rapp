test_that("non-literal unary minus defaults are ignored without error", {
  app_path <- tempfile("rapp-unary-minus-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "fallback_default <- 1L",
      "opt <- -fallback_default",
      "cat('ran\\n')"
    ),
    con = app_path
  )

  expect_output(Rapp::run(app_path, character()), "ran")
})

test_that("launcher names containing quotes survive launcher export", {
  skip_on_os("windows")

  app_path <- tempfile("rapp-launcher-quotes-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "#| launcher: { name: \"Acme's CLI\" }",
      "cat('launcher test\\n')"
    ),
    con = app_path
  )

  launcher_lines <- Rapp:::launcher_contents(app_path, package = "Rapp")
  launcher_path <- tempfile("rapp-launcher-script-")
  on.exit(unlink(launcher_path), add = TRUE)
  writeLines(launcher_lines, launcher_path)
  Sys.chmod(launcher_path, "755")

  launcher_result <- system2(launcher_path, stdout = TRUE, stderr = TRUE)
  expect_type(launcher_result, "character")
  expect_identical(launcher_result, "launcher test")
  expect_null(attr(launcher_result, "status"))
})

test_that("literal unary minus defaults are parsed as scalars", {
  app_path <- tempfile("rapp-unary-literal-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "limit <- -1L",
      "cat(limit, '\\n')"
    ),
    con = app_path
  )

  app <- Rapp:::as_app(app_path)
  expect_identical(app$opts$limit$default, -1L)
  expect_output(Rapp::run(app_path, character()), "-1")
})

test_that("variadic positional collectors declared with NULL accumulate args", {
  app_path <- tempfile("rapp-variadic-null-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "prefix <- NULL",
      "extras... <- NULL",
      "stopifnot(identical(prefix, 'alpha'))",
      "stopifnot(identical(extras..., c('beta', 'gamma')))",
      "cat('ok\\n')"
    ),
    con = app_path
  )

  expect_output(Rapp::run(app_path, c("alpha", "beta", "gamma")), "ok")
})

test_that("variadic positional collectors declared with c() accumulate args", {
  app_path <- tempfile("rapp-variadic-null-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "prefix <- NULL",
      "extras... <- c()",
      "stopifnot(identical(prefix, 'alpha'))",
      "stopifnot(identical(extras..., c('beta', 'gamma')))",
      "cat('ok\\n')"
    ),
    con = app_path
  )

  expect_output(Rapp::run(app_path, c("alpha", "beta", "gamma")), "ok")
})
