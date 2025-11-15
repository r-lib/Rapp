test_that("usage reflects positional argument requiredness", {
  base_lines <- c(
    "#!/usr/bin/env Rapp",
    "#| name: usage-test",
    "#| description: Check required placeholder formatting.",
    "",
    "#| description: Root directory.",
    "#| arg_type: positional",
    "root <- \".\""
  )

  make_app <- function(required_flag) {
    lines <- append(
      base_lines,
      values = sprintf("#| required: !!bool %s", required_flag),
      after = 6
    )
    app_path <- local_rapp_app(
      lines,
      prefix = "rapp-usage-",
      .local_envir = parent.frame()
    )
    capture_help_lines(app_path)
  }

  usage_required <- make_app("true")
  usage_optional <- make_app("false")
  # Default (no required annotation) should be required by default
  app_path_default <- local_rapp_app(
    base_lines,
    prefix = "rapp-usage-default-"
  )
  usage_default <- capture_help_lines(app_path_default)

  usage_line <- function(lines) {
    lines[startsWith(lines, "Usage: ")]
  }

  expect_match(usage_line(usage_required), " <ROOT>$")
  expect_match(usage_line(usage_default), " <ROOT>$")
  expect_match(usage_line(usage_optional), " \\[<ROOT>\\]$")
})

test_that("short annotation values stay character", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: short-test",
      "#| description: Ensure short flag coercion.",
      "",
      "#| short: 1",
      "#| description: Example option.",
      "option <- \"\""
    ),
    prefix = "rapp-short-"
  )

  lines <- capture_help_lines(app_path)
  expect_true(any(grepl("-1, --option <OPTION>", lines, fixed = TRUE)))
})

test_that("list-like annotations are parsed via yaml", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: list-test",
      "#| description: Ensure list parsing.",
      "",
      "#| arg_type: positional",
      "#| info: [alpha, beta]",
      "root <- ''"
    ),
    prefix = "rapp-list-"
  )

  app <- Rapp:::as_app(app_path)
  expect_identical(unclass(app$args$root$info), list("alpha", "beta"))
})

test_that("launcher name is used in help when provided", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "flag <- TRUE"
    ),
    prefix = "rapp-launcher-"
  )

  withr::local_envvar(RAPP_LAUNCHER_NAME = "launcher-test")
  lines <- capture_help_lines(app_path)
  expect_true("Usage: launcher-test [OPTIONS]" %in% lines)
  expect_identical(
    Sys.getenv("RAPP_LAUNCHER_NAME", NA_character_),
    NA_character_
  )
})

test_that("parent and global option sections appear only when relevant", {
  parent_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "switch('',",
      "  parent = {",
      "    parent_only <- \"parent\"",
      "    switch('', child = { child_flag <- TRUE })",
      "  }",
      ")"
    ),
    prefix = "rapp-parent-options-"
  )
  parent_child_lines <- capture_help_lines(parent_app, c("parent", "child"))
  expect_true(any(grepl("^Parent options:", parent_child_lines)))
  expect_false(any(grepl("^Global options:", parent_child_lines)))

  global_app <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "global_only <- \"global\"",
      "switch('',",
      "  parent = {",
      "    switch('', child = { child_flag <- TRUE })",
      "  }",
      ")"
    ),
    prefix = "rapp-global-options-"
  )
  global_child_lines <- capture_help_lines(global_app, c("parent", "child"))
  expect_true(any(grepl("^Global options:", global_child_lines)))
  expect_false(any(grepl("^Parent options:", global_child_lines)))
})
