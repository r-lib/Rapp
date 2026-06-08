parse_yaml <- function(text, ..., simplify = FALSE) {
  yaml12::parse_yaml(text, ..., simplify = simplify)
}

parse_hashpipe_yaml <- function(x, ...) {
  x <- sub("^[ \t]+", "", x, perl = TRUE)
  stopifnot(startsWith(x, "#| "))
  x <- substr(x, 4L, .Machine$integer.max)
  parse_yaml(x, ...)
}
