test_that("non-literal unary minus defaults are ignored without error", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "fallback_default <- 1L",
      "opt <- -fallback_default",
      "cat('ran\\n')"
    ),
    prefix = "rapp-unary-minus-"
  )

  expect_output(Rapp::run(app_path, character()), "ran")
})

test_that("launcher names containing quotes survive launcher export", {
  skip_on_os("windows")

  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| launcher: { name: \"Acme's CLI\" }",
      "cat('launcher test\\n')"
    ),
    prefix = "rapp-launcher-quotes-"
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
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "limit <- -1L",
      "cat(limit, '\\n')"
    ),
    prefix = "rapp-unary-literal-"
  )

  app <- Rapp:::as_app(app_path)
  expect_identical(app$opts$limit$default, -1L)
  expect_output(Rapp::run(app_path, character()), "-1")
})

test_that("variadic positional collectors declared with NULL accumulate args", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "prefix <- NULL",
      "extras... <- NULL",
      "stopifnot(identical(prefix, 'alpha'))",
      "stopifnot(identical(extras..., c('beta', 'gamma')))",
      "cat('ok\\n')"
    ),
    prefix = "rapp-variadic-null-"
  )

  expect_output(Rapp::run(app_path, c("alpha", "beta", "gamma")), "ok")
})

test_that("variadic positional collectors declared with c() accumulate args", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "prefix <- NULL",
      "extras... <- c()",
      "stopifnot(identical(prefix, 'alpha'))",
      "stopifnot(identical(extras..., c('beta', 'gamma')))",
      "cat('ok\\n')"
    ),
    prefix = "rapp-variadic-null-"
  )

  expect_output(Rapp::run(app_path, c("alpha", "beta", "gamma")), "ok")
})

test_that("leading variadic positional collectors accumulate args", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "...extras <- NULL",
      "suffix <- NULL",
      "stopifnot(identical(...extras, c('alpha', 'beta')))",
      "stopifnot(identical(suffix, 'gamma'))",
      "cat('ok\\n')"
    ),
    prefix = "rapp-leading-variadic-"
  )

  expect_output(Rapp::run(app_path, c("alpha", "beta", "gamma")), "ok")
})
