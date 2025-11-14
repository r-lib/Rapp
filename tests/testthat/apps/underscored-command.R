#!/usr/bin/env Rapp

switch(
  cmd <- "",
  foo_bar = {
    foo_bar_flag <- TRUE
  },
  help = {}
)

print(as.list(environment(), all.names = TRUE))
