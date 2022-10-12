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


## `uniq` on unix systems only removes adjacent duplicate entries.
## `unique.R` removes duplicates from the whole stream.

# $ which -a python | unique.R
# /home/tomasz/opt/python-3.8.10/bin/python
# /home/tomasz/.virtualenvs/r-guildai/bin/python
# /usr/bin/python
# /bin/python


# $ which -a python | uniq
# /home/tomasz/opt/python-3.8.10/bin/python
# /home/tomasz/.virtualenvs/r-guildai/bin/python
# /home/tomasz/opt/python-3.8.10/bin/python
# /usr/bin/python
# /bin/python
