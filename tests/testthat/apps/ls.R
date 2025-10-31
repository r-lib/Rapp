#!/usr/bin/env Rapp
#| name: ls-r
#| description: List files matching chained regular expressions.

# c() means, option that can be supplied multiple times. c() does no parsing / yaml interpertation
#| short: p
#| description: Regular expression filter, the union of multiple matches is returned.
pattern <- c()

# message("filter patterns: ", paste0("`", pattern, "`", collapse = " "))

#| description: Directory whose files will be listed.
#| arg-type: positional
#| required: false
root <- "."

paths <- list.files(root, all.files = FALSE, no.. = TRUE)


paths <- sort(unique(unlist(
  lapply(pattern, grep, paths, value = TRUE)
)))

env <- as.list.environment(environment())
env$root <- NULL
cat(yaml::as.yaml(env))
# writeLines(paths)
