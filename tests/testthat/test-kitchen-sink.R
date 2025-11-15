kitchen_app <- test_path("apps", "kitchen-sink.R")

capture_kitchen_env <- function(args = character()) {
  capture_app_env(kitchen_app, args)
}

test_that("kitchen sink defaults apply", {
  env <- capture_kitchen_env()

  expect_identical(env$opt_replace, "default")
  expect_null(env$opt_append)
  expect_false(env$opt_switch)
  expect_identical(env$opt_integer, 1L)
  expect_identical(env$opt_numeric, 1.5)
  expect_identical(env$opt_yaml_parsed, "{}")
  expect_identical(env$opt_yaml_literal, "[1,2]")
  expect_null(env$optional_positional)
  expect_identical(env$optional_positional_default, "foo")
  expect_identical(env$mode, "")
})

test_that("options, append actions, and parsing behave as expected", {
  # fmt: table
  args <- c(
    "--opt-replace"      , "override"         ,
    "--opt-append"       , "alpha"            ,
    "-p"                 , "beta"             ,
    "--opt-switch"       ,
    "--opt-integer"      , "7"                ,
    "--opt-numeric"      , "3.14"             ,
    "--opt-yaml-parsed"  , "{answer: [1, 2]}" ,
    "--opt-yaml-literal" , "[keep, literal]"  ,
    "main-target"
  )

  env <- capture_kitchen_env(args)

  expect_identical(env$opt_replace, "override")
  expect_identical(env$opt_append, c("alpha", "beta"))
  expect_true(env$opt_switch)
  expect_identical(env$opt_integer, 7L)
  expect_equal(env$opt_numeric, 3.14)
  expect_identical(env$opt_yaml_parsed, "{answer: [1, 2]}")
  expect_identical(env$opt_yaml_literal, "[keep, literal]")
  expect_identical(env$optional_positional, "main-target")
  expect_identical(env$optional_positional_default, "foo")
})

test_that("yaml literal accepts scalar overrides without parsing lists", {
  env <- capture_kitchen_env(c("--opt-yaml-literal", "52"))
  expect_identical(env$opt_yaml_literal, "52")

  env_list <- capture_kitchen_env(c("--opt-yaml-literal", "[not, numeric]"))
  expect_identical(env_list$opt_yaml_literal, "[not, numeric]")
})

test_that("summary command overrides defaults and appends filters", {
  env <- capture_kitchen_env("summary")
  expect_identical(env$mode, "summary")
  expect_identical(env$summary_target, "summary-default")
  expect_null(env$summary_filter)

  # fmt: table
  args <- c(
    "summary"          , "--summary-target" ,
    "explicit"         ,
    "--summary-filter" , "a"                ,
    "--summary-filter" , "b"
  )
  env_overrides <- capture_kitchen_env(args)
  expect_identical(env_overrides$summary_target, "explicit")
  expect_identical(env_overrides$summary_filter, c("a", "b"))
})

test_that("detail command enforces required id and optional payload", {
  expect_error(
    capture_kitchen_env("detail"),
    "Missing required argument: DETAIL-ID"
  )

  env_required <- capture_kitchen_env(c("detail", "record-id"))
  expect_identical(env_required$mode, "detail")
  expect_identical(env_required$detail_id, "record-id")
  expect_null(env_required$detail_payload)

  env_payload <- capture_kitchen_env(c(
    "detail",
    "global-target",
    "override-default",
    "record-id",
    "payload"
  ))
  expect_identical(env_payload$optional_positional, "global-target")
  expect_identical(env_payload$optional_positional_default, "override-default")
  expect_identical(env_payload$detail_payload, "payload")
})

test_that("config command accepts an optional config path", {
  env_default <- capture_kitchen_env("config")
  expect_identical(env_default$mode, "config")
  expect_null(env_default$config_path)

  env_with_path <- capture_kitchen_env(c(
    "config",
    "global-target",
    "override-default",
    "cfg.yml"
  ))
  expect_identical(env_with_path$optional_positional, "global-target")
  expect_identical(
    env_with_path$optional_positional_default,
    "override-default"
  )
  expect_identical(env_with_path$config_path, "cfg.yml")
})

test_that("help output surfaces titles", {
  lines <- help_lines(kitchen_app)
  expect_identical(lines[1], "Kitchen Sink CLI")
  command_block <- lines[
    (which(lines == "Commands:") + 1L):length(lines)
  ]
  expect_true(any(grepl("^\\s+summary\\s+Summary Mode$", command_block)))

  summary_lines <- help_lines(kitchen_app, "summary")
  expect_identical(summary_lines[1], "Summary Mode")

  detail_lines <- help_lines(kitchen_app, "detail")
  expect_identical(detail_lines[1], "Detail Mode")
})

# run(kitchen_app, "--help")
# run(kitchen_app, "foo")
