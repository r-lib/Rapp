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
  expect_true(any(grepl("--wrap <WRAP>", true_default_help, fixed = TRUE)))
  expect_true(any(grepl(
    "[enabled by default]",
    true_default_help,
    fixed = TRUE
  )))

  negative_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| description: Legacy spelling is ignored.",
      "#| negative: false",
      "legacy <- TRUE"
    ),
    prefix = "rapp-negative-ignored-"
  )
  negative_help <- capture.output(Rapp::run(negative_app, "--help"))
  expect_true(any(grepl("--no-legacy", negative_help, fixed = TRUE)))
})

test_that("boolean switches accept default-driven and explicit value forms", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "disabled <- FALSE",
      "enabled <- TRUE",
      "unknown <- NA",
      "cat(",
      "  sprintf(",
      "    'disabled=%s enabled=%s unknown=%s\\n',",
      "    disabled,",
      "    enabled,",
      "    unknown",
      "  )",
      ")"
    ),
    prefix = "rapp-bool-default-aliases-"
  )

  expect_output(
    Rapp::run(app_path, character()),
    "disabled=FALSE enabled=TRUE unknown=NA"
  )
  expect_output(
    Rapp::run(app_path, c("--disabled", "--no-enabled", "--unknown")),
    "disabled=TRUE enabled=FALSE unknown=TRUE"
  )
  expect_output(
    Rapp::run(app_path, c("--disabled", "false", "--enabled", "false")),
    "disabled=FALSE enabled=FALSE unknown=NA"
  )
  expect_output(
    Rapp::run(app_path, c("--disabled=false", "--enabled=false")),
    "disabled=FALSE enabled=FALSE unknown=NA"
  )
  expect_output(
    Rapp::run(app_path, c("--no-disabled", "--enabled", "--unknown=false")),
    "disabled=FALSE enabled=TRUE unknown=FALSE"
  )
  expect_output(
    Rapp::run(app_path, c("--unknown", "false")),
    "disabled=FALSE enabled=TRUE unknown=FALSE"
  )

  help <- capture.output(Rapp::run(app_path, "--help"))
  expect_true(any(grepl("--disabled", help, fixed = TRUE)))
  expect_false(any(grepl("--no-disabled", help, fixed = TRUE)))
  expect_false(any(grepl("--enabled", help, fixed = TRUE)))
  expect_true(any(grepl("--no-enabled", help, fixed = TRUE)))
  expect_true(any(grepl("--unknown / --no-unknown", help, fixed = TRUE)))
})

test_that("short aliases follow the default-driven help spelling", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| short: d",
      "disabled <- FALSE",
      "#| short: e",
      "enabled <- TRUE",
      "cat(sprintf('disabled=%s enabled=%s\\n', disabled, enabled))"
    ),
    prefix = "rapp-bool-short-aliases-"
  )

  expect_output(
    Rapp::run(app_path, c("-d", "-e")),
    "disabled=TRUE enabled=FALSE"
  )
})

test_that("annotated NA boolean switches use explicit switch aliases", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| arg_type: switch",
      "flag <- NA",
      "cat(sprintf('flag=%s\\n', flag))"
    ),
    prefix = "rapp-annotated-na-switch-"
  )

  help <- capture.output(Rapp::run(app_path, "--help"))
  expect_true(any(grepl("--flag / --no-flag", help, fixed = TRUE)))

  expect_output(Rapp::run(app_path, character()), "flag=NA")
  expect_output(Rapp::run(app_path, "--flag"), "flag=TRUE")
  expect_output(Rapp::run(app_path, "--no-flag"), "flag=FALSE")
})

test_that("negative_alias false only rejects negative aliases", {
  true_default_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| negative_alias: false",
      "flag <- TRUE",
      "file <- NULL",
      "cat(sprintf('flag=%s file=%s\\n', flag, file))"
    ),
    prefix = "rapp-disabled-positive-alias-positional-"
  )

  expect_output(
    Rapp::run(true_default_app, c("--flag=false", "input")),
    "flag=FALSE file=input"
  )
  expect_output(
    Rapp::run(true_default_app, c("--flag", "false", "input")),
    "flag=FALSE file=input"
  )
  expect_output(
    Rapp::run(true_default_app, c("--flag", "input")),
    "flag=TRUE file=input"
  )

  expect_error(
    Rapp::run(true_default_app, "--no-flag"),
    "Arguments not recognized: --no-flag",
    fixed = TRUE
  )

  false_default_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| negative_alias: false",
      "flag <- FALSE",
      "file <- NULL",
      "cat(sprintf('flag=%s file=%s\\n', flag, file))"
    ),
    prefix = "rapp-disabled-negative-alias-positional-"
  )

  expect_error(
    Rapp::run(false_default_app, "--no-flag"),
    "Arguments not recognized: --no-flag",
    fixed = TRUE
  )
  expect_error(
    Rapp::run(false_default_app, "--no-flag=false"),
    "Arguments not recognized: --no-flag=false",
    fixed = TRUE
  )
})

test_that("boolean options can require explicit values", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| arg_type: option",
      "flag <- NA",
      "file <- NULL",
      "cat(sprintf('flag=%s file=%s\\n', flag, file))"
    ),
    prefix = "rapp-explicit-bool-option-"
  )

  expect_output(
    Rapp::run(app_path, c("--flag", "false", "input")),
    "flag=FALSE file=input"
  )
  expect_output(
    Rapp::run(app_path, c("--flag=false", "input")),
    "flag=FALSE file=input"
  )
  expect_error(
    Rapp::run(app_path, "--flag"),
    "Missing value for --flag.",
    fixed = TRUE
  )
  expect_error(
    Rapp::run(app_path, "--no-flag"),
    "Arguments not recognized: --no-flag",
    fixed = TRUE
  )
  expect_error(
    Rapp::run(app_path, "--no-flag=false"),
    "Arguments not recognized: --no-flag=false",
    fixed = TRUE
  )
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

test_that("YAML 1.1 bool aliases are accepted for bool option values", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "flag <- FALSE"
    ),
    prefix = "rapp-yaml11-bool-aliases-"
  )

  true_values <- c(
    "y", "Y", "yes", "Yes", "YES",
    "true", "True", "TRUE",
    "on", "On", "ON",
    "1"
  )
  false_values <- c(
    "n", "N", "no", "No", "NO",
    "false", "False", "FALSE",
    "off", "Off", "OFF",
    "0"
  )

  for (value in true_values) {
    env <- Rapp::run(app_path, paste0("--flag=", value))
    expect_identical(env$flag, TRUE, info = value)
  }

  for (value in false_values) {
    env <- Rapp::run(app_path, paste0("--flag=", value))
    expect_identical(env$flag, FALSE, info = value)
  }
})

test_that("YAML 1.1 bool aliases stay strings for parsed non-bool options", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "value <- list()"
    ),
    prefix = "rapp-yaml11-string-aliases-"
  )

  env <- Rapp::run(
    app_path,
    c("--value", "on", "--value", "off", "--value", "y", "--value", "n")
  )
  expect_identical(env$value, list("on", "off", "y", "n"))
})

test_that("any options keep raw strings when YAML parsing fails", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "value <- list()"
    ),
    prefix = "rapp-any-invalid-yaml-"
  )

  env <- Rapp::run(
    app_path,
    c("--value", "[not closed", "--value", "{ok: true}")
  )
  expect_identical(env$value, list("[not closed", list(ok = TRUE)))
})

test_that("integer options require YAML integer values", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "flips <- 1L"
    ),
    prefix = "rapp-lossy-integer-"
  )

  env <- Rapp::run(app_path, c("--flips", "2"))
  expect_identical(env$flips, 2L)

  expect_snapshot(error = TRUE, Rapp::run(app_path, c("--flips", "10.2")))
  expect_snapshot(error = TRUE, Rapp::run(app_path, c("--flips", "TRUE")))
})

test_that("float options accept YAML integer values", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "rate <- 0.25"
    ),
    prefix = "rapp-float-integer-"
  )

  env <- Rapp::run(app_path, c("--rate", "1"))
  expect_identical(env$rate, 1)
})

test_that("typed options accept YAML sequences with matching values", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "flips <- 1L",
      "rate <- 0.25",
      "flags <- FALSE"
    ),
    prefix = "rapp-typed-sequence-"
  )

  env <- Rapp::run(app_path, c("--flips", "[1, 2]"))
  expect_identical(env$flips, c(1L, 2L))

  env <- Rapp::run(app_path, c("--rate", "[1, 2.5]"))
  expect_identical(env$rate, c(1, 2.5))

  env <- Rapp::run(app_path, "--flags=[true, false]")
  expect_identical(env$flags, c(TRUE, FALSE))
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

test_that("YAML help serializes complex defaults as strings", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "z <- 1i"
    ),
    prefix = "rapp-yaml-complex-"
  )

  spec <- yaml12::parse_yaml(capture.output(Rapp::run(app_path, "--help-yaml")))

  expect_identical(spec[["options"]][["z"]][["default"]], "0+1i")
})

test_that("YAML help preserves non-finite numeric defaults", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "limit <- Inf",
      "floor <- -Inf",
      "bad <- NaN"
    ),
    prefix = "rapp-yaml-non-finite-"
  )

  spec <- yaml12::parse_yaml(capture.output(Rapp::run(app_path, "--help-yaml")))

  expect_identical(spec[["options"]][["limit"]][["default"]], Inf)
  expect_identical(spec[["options"]][["floor"]][["default"]], -Inf)
  expect_true(is.nan(spec[["options"]][["bad"]][["default"]]))
})

test_that("YAML help preserves strings matching non-finite sentinels", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| sentinel: \"@@RAPP_YAML_NONFINITE_INF@@\"",
      "limit <- Inf",
      "string_inf <- \"@@RAPP_YAML_NONFINITE_INF@@\"",
      "string_neg_inf <- \"@@RAPP_YAML_NONFINITE_NEG_INF@@\"",
      "string_nan <- \"@@RAPP_YAML_NONFINITE_NAN@@\""
    ),
    prefix = "rapp-yaml-non-finite-sentinel-"
  )

  spec <- yaml12::parse_yaml(capture.output(Rapp::run(app_path, "--help-yaml")))

  expect_identical(spec[["sentinel"]], "@@RAPP_YAML_NONFINITE_INF@@")
  expect_identical(spec[["options"]][["limit"]][["default"]], Inf)
  expect_identical(
    spec[["options"]][["string_inf"]][["default"]],
    "@@RAPP_YAML_NONFINITE_INF@@"
  )
  expect_identical(
    spec[["options"]][["string_neg_inf"]][["default"]],
    "@@RAPP_YAML_NONFINITE_NEG_INF@@"
  )
  expect_identical(
    spec[["options"]][["string_nan"]][["default"]],
    "@@RAPP_YAML_NONFINITE_NAN@@"
  )
})

test_that("YAML help preserves non-finite metadata without rewriting text", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| description: |",
      "#|   limit: inf",
      "#| values: [.inf, -.inf, .nan]",
      "flag <- TRUE"
    ),
    prefix = "rapp-yaml-metadata-non-finite-"
  )

  spec <- yaml12::parse_yaml(capture.output(Rapp::run(app_path, "--help-yaml")))

  expect_identical(spec[["description"]], "limit: inf\n")
  expect_identical(spec[["values"]][[1L]], Inf)
  expect_identical(spec[["values"]][[2L]], -Inf)
  expect_true(is.nan(spec[["values"]][[3L]]))
})

test_that("YAML help keeps generated keys when metadata names collide", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| options: metadata-options",
      "#| arguments: metadata-arguments",
      "#| commands: metadata-commands",
      "flag <- TRUE",
      "arg <- NULL"
    ),
    prefix = "rapp-yaml-duplicate-help-"
  )

  spec <- yaml12::parse_yaml(capture.output(Rapp::run(app_path, "--help-yaml")))

  expect_identical(spec[["options"]][["flag"]][["arg_type"]], "switch")
  expect_identical(spec[["arguments"]][["arg"]][["arg_type"]], "positional")
  expect_null(spec[["commands"]])
})
