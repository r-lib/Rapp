#!/usr/bin/env Rapp

top_opt <- "top-default"

switch(
  top_cmd <- "",
  parent = {
    parent_opt <- "parent-default"
    parent_switch <- TRUE

    switch(
      child_cmd <- "",
      child1 = {
        child1_flag <- "child1-default"
      },
      child2 = {
        child2_opt <- "child2-default"
        child2_switch <- FALSE
        child2_arg <- NULL
      },
      help = {}
    )
  },
  help = {}
)

print(as.list(environment(), all.names = TRUE))
