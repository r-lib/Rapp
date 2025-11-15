simple_app <- test_path("apps", "simple-commands.R")
nested_app <- test_path("apps", "nested-commands.R")
underscored_app <- test_path("apps", "underscored-command.R")

capture_simple_env <- function(args = character()) {
  capture_app_env(simple_app, args)
}

capture_nested_env <- function(args = character()) {
  capture_app_env(nested_app, args)
}

test_that("simple app uses defaults without args", {
  env <- capture_simple_env()
  expect_identical(env$cmd, "")
  expect_identical(env$global_opt, "global_opt_default")
})

test_that("global option is recognised before and after a command", {
  env_pre <- capture_simple_env(c("--global-opt", "override", "cmd1"))
  env_post <- capture_simple_env(c("cmd1", "--global-opt", "late"))

  expect_identical(env_pre$global_opt, "override")
  expect_identical(env_post$global_opt, "late")
})

test_that("cmd1 command-specific option overrides defaults", {
  default_env <- capture_simple_env("cmd1")
  override_env <- capture_simple_env(c("cmd1", "--cmd1-opt", "custom"))

  expect_identical(default_env$cmd1_opt, "cmd1_opt_default")
  expect_identical(override_env$cmd1_opt, "custom")
})

test_that("cmd2 positional arguments and options map correctly", {
  default_env <- capture_simple_env("cmd2")
  expect_identical(default_env$cmd2_opt, "cmd2_opt_default")
  expect_length(default_env$cmd2_positional, 0)

  override_env <- capture_simple_env(c(
    "cmd2",
    "--cmd2-opt=custom",
    "alpha",
    "beta"
  ))
  expect_identical(override_env$cmd2_opt, "custom")
  expect_identical(override_env$cmd2_positional, "alpha")
  expect_identical(override_env$cmd2_positional2, "beta")
})

test_that("cmd2 rejects extra positional arguments", {
  expect_error(
    capture_simple_env(c("cmd2", "one", "two", "three")),
    "Arguments not recognized"
  )
})

test_that("parent command executes without nested selection", {
  env <- capture_nested_env("parent")
  expect_identical(env$top_cmd, "parent")
  expect_identical(env$child_cmd, "")
  expect_identical(env$parent_opt, "parent-default")
})

test_that("nested command options and switches cascade correctly", {
  env <- capture_nested_env(
    c(
      "--top-opt",
      "override",
      "parent",
      "--no-parent-switch",
      "--parent-opt",
      "pval",
      "child2",
      "--child2-opt",
      "C2",
      "--child2-switch",
      "payload"
    )
  )

  expect_identical(env$top_opt, "override")
  expect_identical(env$parent_switch, FALSE)
  expect_identical(env$parent_opt, "pval")
  expect_identical(env$child_cmd, "child2")
  expect_identical(env$child2_opt, "C2")
  expect_identical(env$child2_switch, TRUE)
  expect_identical(env$child2_arg, "payload")
})

test_that("snake case subcommands expose kebab-case cli names", {
  app <- Rapp:::as_app(underscored_app)
  expect_true("foo-bar" %in% names(app$commands))
  expect_false("foo_bar" %in% names(app$commands))
})

test_that("underscored commands accept snake_case and kebab-case", {
  snake_env <- capture_app_env(underscored_app, "foo_bar")
  kebab_env <- capture_app_env(underscored_app, "foo-bar")
  expect_identical(snake_env$foo_bar_flag, TRUE)
  expect_identical(kebab_env$foo_bar_flag, TRUE)
})
