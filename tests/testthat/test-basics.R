test_that("examples work", {
  old_path <- Sys.getenv("PATH")
  Sys.setenv(PATH = paste(system.file("examples", package = "Rapp"),
                          system.file("exec", package = "Rapp"),
                          R.home("bin"),
                          old_path,
                          sep = .Platform$path.sep))
  on.exit(Sys.setenv(PATH = old_path), add = TRUE)

  run_app <- function(name, ..., input = NULL) {

    if(is_windows())
      name <- paste("Rapp", name)

    cmd <- paste0(c(name, ...), collapse = " ")
    # message(cmd)
    system(cmd, input = input, intern = TRUE)
  }

  # browser()
  expect_equal(
    run_app("unique.R", input = c("a", "b", "c", "c", "b", "a")),
    c("a", "b", "c")
  )

  expect_equal(
    run_app("unique.R", "--from-last", input = c("a", "b", "c", "c", "b", "a")),
    c("c", "b", "a")
  )


  writeLines(c("a", "b", "c", "c", "b", "a"),
             fi <- tempfile())
  on.exit(unlink(fi), add = TRUE)


  expect_equal(
    run_app("unique.R", fi),
    c("a", "b", "c")
  )

  expect_equal(
    run_app("unique.R", "--from-last", fi),
    c("c", "b", "a")
  )

})

