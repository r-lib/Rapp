ls_app <- test_path("apps", "ls.R")

run_ls_app <- function(args = character()) {
  invisible(Rapp::run(ls_app, args))
}

test_that("ls app accepts same option multiple times", {
  dir <- tempfile("rapp-ls")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  files <- c("alpha.txt", "alphabet.txt", "beta.R", "beta.txt", "notes.md")
  file.create(file.path(dir, files))

  # run_ls_app(c(dir, "-p", "alpha", "-p", "\\.txt$"))

  # TODO: arg_type, we should be able to pass yaml-like name `arg-type`
  # TODO: if action==append, then the help should indicate it can be supplied multiple times.
  expect_snapshot(run_ls_app(c(dir, "-p", "alpha", "-p", "\\.txt$")))
  expect_snapshot(run_ls_app(c(dir, "--pattern", "t$", "-p", "^beta")))
})
