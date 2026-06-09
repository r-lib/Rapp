simple_app <- test_path("apps", "simple-commands.R")
nested_app <- test_path("apps", "nested-commands.R")
underscored_app <- test_path("apps", "underscored-command.R")

capture_simple_env <- function(args = character()) {
  capture_app_env(simple_app, args)
}

capture_nested_env <- function(args = character()) {
  capture_app_env(nested_app, args)
}

snapshot_missing_command_help <- function(app_path, args, invocation) {
  run <- snapshot_command_run(app_path, args, invocation)
  expect_null(run$result)

  run$output
}

snapshot_command_run <- function(app_path, args, invocation) {
  output <- capture.output(result <- Rapp::run(app_path, args))

  snapshot <- list(
    app = paste(readLines(app_path), collapse = "\\n"),
    invocation = paste0("$ ", invocation),
    output = paste(output, collapse = "\\n")
  )
  expect_snapshot(yaml12::write_yaml(snapshot))

  list(output = output, result = result)
}

test_that("simple app uses defaults without args", {
  env <- capture_simple_env()
  expect_identical(env$cmd, "")
  expect_identical(env$global_opt, "global_opt_default")
})

test_that("missing literal command switch prints help", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: required-command-test",
      "#| description: Exercise missing command help.",
      "",
      "switch('',",
      "  #| title: List entries",
      "  list = { cat('list called\\n') }",
      ")"
    ),
    prefix = "rapp-required-command-"
  )

  lines <- snapshot_missing_command_help(
    app_path,
    character(),
    "required-command-test"
  )

  expect_true(any(grepl(
    "Usage: required-command-test <COMMAND>",
    lines,
    fixed = TRUE
  )))
  expect_true(any(grepl("Commands:", lines, fixed = TRUE)))
  expect_true(any(grepl("list", lines, fixed = TRUE)))
})

test_that("missing command assignment prints help by default", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: assigned-command-test",
      "#| description: Exercise missing command help.",
      "",
      "switch(command <- '',",
      "  #| title: List entries",
      "  list = { cat(command, '\\n', sep = '') }",
      ")"
    ),
    prefix = "rapp-assigned-command-"
  )

  lines <- snapshot_missing_command_help(
    app_path,
    character(),
    "assigned-command-test"
  )

  expect_true(any(grepl(
    "Usage: assigned-command-test <COMMAND>",
    lines,
    fixed = TRUE
  )))
  expect_true(any(grepl("Commands:", lines, fixed = TRUE)))
  expect_true(any(grepl("list", lines, fixed = TRUE)))

  run_lines <- capture.output(env <- Rapp::run(app_path, "list"))
  expect_identical(run_lines, "list")
  expect_identical(env$command, "list")
})

test_that("required false command switch allows missing command", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: optional-command-test",
      "",
      "#| required: false",
      "switch(command <- '',",
      "  #| title: List entries",
      "  list = { cat(command, '\\n', sep = '') }",
      ")",
      "cat('no command\\n')"
    ),
    prefix = "rapp-optional-command-"
  )

  run <- snapshot_command_run(
    app_path,
    character(),
    "optional-command-test"
  )

  expect_identical(run$output, "no command")
  expect_identical(run$result$command, "")

  help_output <- capture.output(help_result <- Rapp::run(app_path, "--help"))
  expect_null(help_result)
  expect_true(any(grepl(
    "Usage: optional-command-test [<COMMAND>]",
    help_output,
    fixed = TRUE
  )))
})

test_that("missing command prints help before matching positionals", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: command-with-positional-test",
      "",
      "#| description: Input path.",
      "input <- NULL",
      "",
      "switch('',",
      "  #| title: Run command",
      "  run = { cat('run ', input, '\\n', sep = '') }",
      ")",
      "cat('no command\\n')"
    ),
    prefix = "rapp-command-with-positional-"
  )

  lines <- snapshot_missing_command_help(
    app_path,
    "data.csv",
    "command-with-positional-test data.csv"
  )

  expect_true(any(grepl(
    "Usage: command-with-positional-test <COMMAND> <INPUT>",
    lines,
    fixed = TRUE
  )))
  expect_true(any(grepl("Commands:", lines, fixed = TRUE)))
  expect_true(any(grepl("run", lines, fixed = TRUE)))
})

test_that("missing nested command prints scoped help", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: nested-required-command-test",
      "",
      "switch('',",
      "  #| title: Parent command",
      "  parent = {",
      "    switch('',",
      "      #| title: Child command",
      "      child = { cat('child called\\n') }",
      "    )",
      "  }",
      ")"
    ),
    prefix = "rapp-nested-required-command-"
  )

  lines <- snapshot_missing_command_help(
    app_path,
    "parent",
    "nested-required-command-test parent"
  )

  expect_true(any(grepl(
    "Usage: nested-required-command-test parent <COMMAND>",
    lines,
    fixed = TRUE
  )))
  expect_true(any(grepl("Commands:", lines, fixed = TRUE)))
  expect_true(any(grepl("child", lines, fixed = TRUE)))
})

test_that("optional parent command preserves required child help", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: optional-parent-required-child-test",
      "",
      "#| required: false",
      "switch(parent_cmd <- '',",
      "  #| title: Parent command",
      "  parent = {",
      "    switch(child_cmd <- NULL,",
      "      #| title: Child command",
      "      child = { cat('child called\\n') }",
      "    )",
      "  }",
      ")"
    ),
    prefix = "rapp-optional-parent-required-child-"
  )

  lines <- snapshot_missing_command_help(
    app_path,
    "parent",
    "optional-parent-required-child-test parent"
  )

  expect_true(any(grepl(
    "Usage: optional-parent-required-child-test parent <COMMAND>",
    lines,
    fixed = TRUE
  )))
  expect_true(any(grepl("Commands:", lines, fixed = TRUE)))
  expect_true(any(grepl("child", lines, fixed = TRUE)))
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
