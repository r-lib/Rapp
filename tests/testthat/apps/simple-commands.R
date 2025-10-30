#!/usr/bin/env Rapp

global_opt <- "global_opt_default"

switch(
  cmd <- "",
  cmd1 = {
    cmd1_opt <- "cmd1_opt_default"
    cat("cmd1 called!\n")
  },
  cmd2 = {
    cmd2_positional <- character()
    cmd2_opt <- "cmd2_opt_default"
    cmd2_positional2 <- character()
    cat("cmd2 called!\n")
  },
  help = {}
)

# cat(yaml::as.yaml(as.list(environment())))
print(as.list(environment(), all.names = TRUE))
print(loadedNamespaces()) # confirm only base,Rapp,compiler

# run("tests/testthat/apps/simple-commands.R", c("cmd1"))
# run("tests/testthat/apps/simple-commands.R", c("cmd1", "--cmd1-opt", "foo"))
# run("tests/testthat/apps/simple-commands.R", c("cmd2", "--cmd2-opt", "foo"))
# run("tests/testthat/apps/simple-commands.R", c("cmd2", "--cmd2-opt", "foo", "baz"))
