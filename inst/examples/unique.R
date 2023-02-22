#!/usr/bin/env Rscript

#| description: remove duplicates in reverse order
from_last <- FALSE

input <- NULL # optional positional arg
output <- NA_character_ # option

if(is.null(input))
  input <- file("stdin")

if(is.nal(output))
  output <- stdout()

readLines(input) |>
  unique(fromLast = from_last) |>
  writeLines(output)


## `uniq` only removes adjacent duplicate entries.
## `unique.R` removes duplicates from the whole stream.
