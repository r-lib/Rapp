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
    app_path <- tempfile("rapp-usage-", fileext = ".R")
    on.exit(unlink(app_path), add = TRUE)
    lines <- append(
      base_lines,
      values = sprintf("#| required: !!bool %s", required_flag),
      after = 6
    )
    writeLines(lines, con = app_path)
    capture_help_lines(app_path)
  }

  usage_required <- make_app("true")
  usage_optional <- make_app("false")
  # Default (no required annotation) should be required by default
  app_path_default <- tempfile("rapp-usage-default-", fileext = ".R")
  on.exit(unlink(app_path_default), add = TRUE)
  writeLines(base_lines, con = app_path_default)
  usage_default <- capture_help_lines(app_path_default)

  usage_line <- function(lines) {
    lines[startsWith(lines, "Usage: ")]
  }

  expect_match(usage_line(usage_required), " <ROOT>$")
  expect_match(usage_line(usage_default), " <ROOT>$")
  expect_match(usage_line(usage_optional), " \\[<ROOT>\\]$")
})

test_that("short annotation values stay character", {
  app_path <- tempfile("rapp-short-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: short-test",
      "#| description: Ensure short flag coercion.",
      "",
      "#| short: 1",
      "#| description: Example option.",
      "option <- \"\""
    ),
    con = app_path
  )

  lines <- capture_help_lines(app_path)
  expect_true(any(grepl("-1, --option <OPTION>", lines, fixed = TRUE)))
})

test_that("list-like annotations are parsed via yaml", {
  app_path <- tempfile("rapp-list-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: list-test",
      "#| description: Ensure list parsing.",
      "",
      "#| arg_type: positional",
      "#| info: [alpha, beta]",
      "root <- ''"
    ),
    con = app_path
  )

  app <- Rapp:::as_app(app_path)
  expect_identical(unclass(app$args$root$info), list("alpha", "beta"))
})

test_that("launcher name is used in help when provided", {
  app_path <- tempfile("rapp-launcher-", fileext = ".R")
  on.exit(unlink(app_path), add = TRUE)
  writeLines(
    c(
      "#!/usr/bin/env Rapp",
      "flag <- TRUE"
    ),
    con = app_path
  )

  withr::local_envvar(RAPP_LAUNCHER_NAME = "launcher-test")
  lines <- capture_help_lines(app_path)
  expect_true("Usage: launcher-test [OPTIONS]" %in% lines)
  expect_identical(
    Sys.getenv("RAPP_LAUNCHER_NAME", NA_character_),
    NA_character_
  )
})
