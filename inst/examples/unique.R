#!/usr/bin/env Rapp
#| description: |
#|   Remove duplicate values from a file or input

#| description: remove duplicates in reverse order
from_last <- FALSE # optional bool switch

#| description: Filepath. If omitted, output is written to stdout.
output <- NA_character_ # scalar constant == optional option

#| description: Filepath. If omitted, input is read from stdin.
#| required: false
input <- NULL # NULL == positional arg; required by default unless `required: false`


if (is.null(input)) {
  input <- file("stdin")
}

if (is.na(output)) {
  output <- stdout()
}


readLines(input) |>
  unique(fromLast = from_last) |>
  writeLines(output)

## `uniq` only removes adjacent duplicate entries.
## `unique.R` removes duplicates from the whole stream.
