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

test_that("boolean switches can disable negative aliases", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: version-app",
      "#| description: Version printer.",
      "",
      "#| description: Print version and exit.",
      "#| negative_alias: false",
      "version <- FALSE",
      "",
      "if (version) cat('version-app 1.0.0\\n')"
    ),
    prefix = "rapp-no-negative-switch-"
  )

  expect_output(Rapp::run(app_path, "--version"), "version-app 1.0.0")

  help <- capture.output(Rapp::run(app_path, "--help"))
  expect_true(any(grepl("--version", help, fixed = TRUE)))
  expect_false(any(grepl("--no-version", help, fixed = TRUE)))
  expect_error(
    Rapp::run(app_path, "--no-version"),
    "Arguments not recognized: --no-version",
    fixed = TRUE
  )

  true_default_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| description: Keep output wrapped.",
      "#| negative_alias: false",
      "wrap <- TRUE"
    ),
    prefix = "rapp-no-negative-default-true-"
  )
  true_default_help <- capture.output(Rapp::run(true_default_app, "--help"))
  expect_false(any(grepl("--no-wrap", true_default_help, fixed = TRUE)))
  expect_false(any(grepl(
    "Enable with `--wrap`.",
    true_default_help,
    fixed = TRUE
  )))

  negative_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| description: Legacy spelling is ignored.",
      "#| negative: false",
      "legacy <- FALSE"
    ),
    prefix = "rapp-negative-ignored-"
  )
  negative_help <- capture.output(Rapp::run(negative_app, "--help"))
  expect_true(any(grepl("--no-legacy", negative_help, fixed = TRUE)))
})
