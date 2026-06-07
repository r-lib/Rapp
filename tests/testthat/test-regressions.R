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

test_that("YAML 1.2 strings are preserved in parsed option values", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "value <- list()"
    ),
    prefix = "rapp-yaml12-"
  )

  env <- Rapp::run(app_path, c("--value", "no"))
  expect_identical(env$value, list("no"))
})

test_that("YAML help records typed NA defaults as null", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "unset <- NA",
      "integer <- NA_integer_",
      "real <- NA_real_",
      "character <- NA_character_"
    ),
    prefix = "rapp-yaml-na-"
  )

  spec <- yaml12::parse_yaml(capture.output(Rapp::run(app_path, "--help-yaml")))
  defaults <- lapply(spec[["options"]], `[[`, "default")
  val_types <- lapply(spec[["options"]], `[[`, "val_type")

  expect_null(defaults[["unset"]])
  expect_null(defaults[["integer"]])
  expect_null(defaults[["real"]])
  expect_null(defaults[["character"]])

  # YAML null is enough because val_type carries the declared input type.
  expect_false(any(vapply(
    spec[["options"]],
    function(option) "default_type" %in% names(option),
    logical(1)
  )))

  expect_identical(val_types[["unset"]], "bool")
  expect_identical(val_types[["integer"]], "integer")
  expect_identical(val_types[["real"]], "float")
  expect_identical(val_types[["character"]], "string")
})
