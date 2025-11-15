test_that("missing required positional triggers a helpful error", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: required-test",
      "#| description: Check required positional enforcement.",
      "",
      "#| description: Name to greet.",
      "#| required: true",
      "name <- NULL",
      "",
      "cat('Hello ', name, '!\\n', sep = '')"
    ),
    prefix = "rapp-required-pos-"
  )

  expect_snapshot(error = TRUE, Rapp::run(app_path, character()))
})

test_that("missing required positional in a command triggers a helpful error", {
  app_path <- local_rapp_app(
    c(
      "#!/usr/bin/env Rapp",
      "#| name: cmd-required-test",
      "#| description: Ensure required enforcement within a command.",
      "",
      "switch('',",
      "  add = {",
      "    #| description: Task description.",
      "    #| required: true",
      "    task <- NULL",
      "  }",
      ")"
    ),
    prefix = "rapp-required-cmd-"
  )

  expect_snapshot(error = TRUE, Rapp::run(app_path, c("add")))
})
