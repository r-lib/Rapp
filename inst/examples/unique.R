#!/usr/bin/env Rapp

#| description: remove duplicates in reverse order
from_last <- FALSE

input <- NULL # optional positional arg
output <- NA_character_ # option

if(is.null(input))
  input <- file("stdin")

if(is.na(output))
  output <- stdout()

# message("from_last = ", from_last)

readLines(input) |>
  unique(fromLast = from_last) |>
  writeLines(output)


## `uniq` only removes adjacent duplicate entries.
## `unique.R` removes duplicates from the whole stream.
