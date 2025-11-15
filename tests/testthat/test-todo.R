todo_app_path <- function() {
  system.file("examples/todo.R", package = "Rapp")
}

run_todo_app <- function(args = character(), capture = TRUE) {
  script <- todo_app_path()
  if (capture) {
    capture.output(Rapp::run(script, args = args))
  } else {
    Rapp::run(script, args = args)
  }
}

test_that("todo help output", {
  app_path <- todo_app_path()
  expect_snapshot(
    cat(
      help_lines(app_path),
      sep = "\n"
    )
  )
  expect_snapshot(
    cat(
      help_lines(app_path, "list"),
      sep = "\n"
    )
  )
  expect_snapshot(
    cat(
      help_lines(app_path, "done"),
      sep = "\n"
    )
  )
})

test_that("todo commands update the store", {
  store <- tempfile(fileext = ".yml")
  on.exit(unlink(store), add = TRUE)

  run_todo_app(c("add", "buy milk", "--store", store))
  expect_equal(
    yaml::read_yaml(store),
    "buy milk"
  )

  run_todo_app(c("add", "write tests", "--store", store))
  expect_equal(
    yaml::read_yaml(store),
    c("buy milk", "write tests")
  )

  run_todo_app(c("add", "call mom", "--store", store))
  expect_equal(
    yaml::read_yaml(store),
    c("buy milk", "write tests", "call mom")
  )

  done_default <- run_todo_app(c("done", "--store", store))
  expect_match(done_default[[1]], "Completed: buy milk")
  expect_equal(
    yaml::read_yaml(store),
    c("write tests", "call mom")
  )

  done_output <- run_todo_app(c("done", "-i", "2", "--store", store))
  expect_match(done_output[[1]], "Completed: call mom")
  expect_equal(yaml::read_yaml(store), "write tests")
})
