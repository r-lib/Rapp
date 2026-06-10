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

  capture_usage <- function(required_flag = NULL) {
    lines <- base_lines
    if (!is.null(required_flag)) {
      lines <- append(
        lines,
        values = sprintf("#| required: %s", required_flag),
        after = 5
      )
    }
    help_lines_from_script(lines, prefix = "rapp-usage-")
  }

  usage_required <- capture_usage("true")
  usage_optional <- capture_usage("false")
  usage_default <- capture_usage()

  usage_line <- function(lines) {
    lines[startsWith(lines, "Usage: ")]
  }

  expect_match(usage_line(usage_required), " <ROOT>$")
  expect_match(usage_line(usage_default), " <ROOT>$")
  expect_match(usage_line(usage_optional), " \\[<ROOT>\\]$")
})

test_that("short annotation values stay character", {
  lines <- help_lines_from_script(
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
  expect_true(any(grepl("-1, --option <OPTION>", lines, fixed = TRUE)))
})

test_that("short-like annotation keys do not partially match", {
  app_path <- local_rapp_script(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: short-extra-test",
      "",
      "#| short-extra: x",
      "#| description: Example option.",
      "option <- \"\""
    ),
    prefix = "rapp-short-extra-"
  )

  lines <- capture.output(Rapp::run(app_path, "--help"))
  expect_true(any(grepl("--option <OPTION>", lines, fixed = TRUE)))
  expect_false(any(grepl("-x, --option <OPTION>", lines, fixed = TRUE)))
})

test_that("examples annotation appears in help", {
  lines <- c(
    "#!/usr/bin/env Rapp",
    "#| name: italyparl",
    "switch('',",
    "  #| title: Parliamentary bills",
    "  #| description: Search bills from Camera or Senato.",
    "  #| examples:",
    "  #|   - italyparl bills --approved --camera cd",
    "  #|   - italyparl bills --keyword energia --camera sn --format json",
    "  bills = {",
    "    #| description: cd or sn",
    "    #| examples: italyparl bills --camera sn",
    "    camera <- 'cd'",
    "    #| description: Only approved bills",
    "    approved <- FALSE",
    "  }",
    ")"
  )

  help <- help_lines_from_script(
    lines,
    command_path = "bills",
    prefix = "rapp-examples-"
  )

  examples <- help[seq(
    which(help == "Examples:") + 1L,
    length.out = 3L
  )]
  expect_identical(examples, c(
    "  italyparl bills --approved --camera cd",
    "  italyparl bills --keyword energia --camera sn --format json",
    "  italyparl bills --camera sn"
  ))

  yaml_lines <- help_lines_from_script(
    lines,
    format = "yaml",
    prefix = "rapp-examples-yaml-"
  )
  expect_true("        examples:" %in% yaml_lines)
  expect_true("          - italyparl bills --camera sn" %in% yaml_lines)

  yaml <- yaml12::parse_yaml(yaml_lines)
  expect_identical(yaml$commands$bills$options$camera$examples, c(
    "italyparl bills --camera sn"
  ))
  expect_identical(yaml$commands$bills$examples, c(
    "italyparl bills --approved --camera cd",
    "italyparl bills --keyword energia --camera sn --format json"
  ))
})

test_that("inherited option examples appear in command help", {
  lines <- c(
    "#!/usr/bin/env Rapp",
    "#| name: inherited-examples",
    "",
    "#| description: Config file.",
    "#| examples: inherited-examples --config config.yml child",
    "config <- \"\"",
    "",
    "switch('',",
    "  child = {",
    "    flag <- TRUE",
    "  }",
    ")"
  )

  help <- help_lines_from_script(
    lines,
    command_path = "child",
    prefix = "rapp-inherited-examples-"
  )

  examples <- help[seq(
    which(help == "Examples:") + 1L,
    length.out = 1L
  )]
  expect_identical(
    examples,
    "  inherited-examples --config config.yml child"
  )
})

test_that("YAML help preserves generated entries named examples", {
  yaml <- yaml12::parse_yaml(help_lines_from_script(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: examples-option",
      "examples <- \"\""
    ),
    format = "yaml",
    prefix = "rapp-examples-option-"
  ))

  expect_identical(yaml$options$examples$arg_type, "option")
  expect_identical(yaml$options$examples$val_type, "string")
})

test_that("required-like annotation keys do not partially match", {
  app_path <- local_rapp_script(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: required-extra-test",
      "",
      "#| required-extra: false",
      "name <- NULL",
      "cat(name, '\\n')"
    ),
    prefix = "rapp-required-extra-"
  )

  expect_error(
    Rapp::run(app_path, character()),
    "Missing required argument: NAME"
  )
})

test_that("help output lists option defaults, types, and switch descriptions", {
  build_help <- function(option_block, prefix) {
    help_lines_from_script(
      c(
        "#!/usr/bin/env Rapp",
        "#| name: metadata-test",
        "#| description: Inspect option metadata.",
        "",
        option_block
      ),
      prefix = prefix
    )
  }

  cases <- list(
    string = list(
      option = c(
        "#| description: Example string option.",
        "name <- \"alpha\""
      ),
      patterns = c("[default: \"alpha\"]", "[type: string]")
    ),
    integer = list(
      option = c(
        "#| description: Example integer option.",
        "limit <- 5L"
      ),
      patterns = c("[default: 5]", "[type: integer]")
    ),
    float = list(
      option = c(
        "#| description: Example float option.",
        "rate <- 0.25"
      ),
      patterns = c("[default: 0.25]", "[type: float]")
    ),
    switch_true = list(
      option = c(
        "#| description: Wrap output.",
        "wrap <- TRUE"
      ),
      patterns = c("Wrap output."),
      absent_patterns = c("[default: true]", "[enabled by default]")
    ),
    switch_false = list(
      option = c(
        "#| description: Verbose output.",
        "verbose <- FALSE"
      ),
      patterns = c("Verbose output."),
      absent_patterns = c("[default: false]", "[disabled by default]")
    )
  )

  for (case_name in names(cases)) {
    case <- cases[[case_name]]
    lines <- build_help(
      option_block = case$option,
      prefix = paste0("rapp-metadata-", case_name, "-")
    )
    for (pattern in case$patterns) {
      expect_true(
        any(grepl(pattern, lines, fixed = TRUE)),
        info = sprintf("Missing pattern '%s' for case '%s'", pattern, case_name)
      )
    }
    for (pattern in case[["absent_patterns"]] %||% character()) {
      expect_false(
        any(grepl(pattern, lines, fixed = TRUE)),
        info = sprintf(
          "Unexpected pattern '%s' for case '%s'",
          pattern,
          case_name
        )
      )
    }
  }
})

test_that("list-like annotations are parsed via yaml", {
  app_path <- local_rapp_script(
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

test_that("help metadata keys do not partially match", {
  app_path <- local_rapp_script(
    c(
      "#!/usr/bin/env Rapp",
      "#| title-extra: Do not use as title.",
      "#| description-extra: Do not use as description.",
      "",
      "flag <- TRUE"
    ),
    prefix = "rapp-no-partial-meta-"
  )

  lines <- capture.output(Rapp::run(app_path, "--help"))
  expect_match(lines[[1]], "^Usage: ")
  expect_false(any(lines %in% c(
    "Do not use as title.",
    "Do not use as description."
  )))
})

test_that("launcher name is used in help when provided", {
  withr::local_envvar(RAPP_LAUNCHER_NAME = "launcher-test")
  lines <- help_lines_from_script(
    c(
      "#!/usr/bin/env Rapp",
      "flag <- TRUE"
    ),
    prefix = "rapp-launcher-"
  )
  expect_true("Usage: launcher-test [OPTIONS]" %in% lines)
  expect_identical(
    Sys.getenv("RAPP_LAUNCHER_NAME", NA_character_),
    NA_character_
  )
})

test_that("parent and global option sections appear only when relevant", {
  parent_app <- local_rapp_script(
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
  parent_child_lines <- help_lines(parent_app, c("parent", "child"))
  expect_true(any(grepl("^Parent options:", parent_child_lines)))
  expect_false(any(grepl("^Global options:", parent_child_lines)))

  global_app <- local_rapp_script(
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
  global_child_lines <- help_lines(global_app, c("parent", "child"))
  expect_true(any(grepl("^Global options:", global_child_lines)))
  expect_false(any(grepl("^Parent options:", global_child_lines)))
})
