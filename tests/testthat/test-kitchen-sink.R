kitchen_app <- test_path("apps", "kitchen-sink.R")

capture_kitchen_env <- function(args = character()) {
  app <- Rapp:::as_app(kitchen_app)
  Rapp:::process_args(args, app)
  run_env <- new.env(parent = baseenv())
  capture.output(
    for (expr in app$exprs) {
      eval(expr, run_env)
    }
  )
  as.list(run_env, all.names = TRUE)
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

test_that("help output surfaces titles", {
  lines <- capture_help_lines(kitchen_app)
  expect_identical(lines[1], "Kitchen Sink CLI")
  command_block <- lines[
    (which(lines == "Commands:") + 1L):length(lines)
  ]
  expect_true(any(grepl("^\\s+summary\\s+Summary Mode$", command_block)))

  summary_lines <- capture_help_lines(kitchen_app, "summary")
  expect_identical(summary_lines[1], "Summary Mode")

  detail_lines <- capture_help_lines(kitchen_app, "detail")
  expect_identical(detail_lines[1], "Detail Mode")
})

# run(kitchen_app, "--help")
# run(kitchen_app, "foo")
