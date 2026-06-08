parse_yaml <- function(text, ..., simplify = FALSE) {
  yaml12::parse_yaml(text, ..., simplify = simplify)
}

parse_hashpipe_yaml <- function(x, ...) {
  x <- hashpipe_yaml_lines(x)
  parse_yaml(x, ...)
}

parse_hashpipe_anno <- function(x, ...) {
  x <- hashpipe_yaml_lines(x)
  example_idx <- startsWith(x, "example:")
  if (sum(example_idx) <= 1L) {
    return(parse_yaml(x, ...))
  }

  examples <- trimws(
    substr(
      x[example_idx],
      nchar("example:") + 1L,
      .Machine$integer.max
    ),
    which = "left"
  )
  stopifnot(all(nzchar(examples)))

  x <- x[!example_idx]
  anno <- if (length(x)) {
    parse_yaml(x, ...)
  } else {
    structure(list(), names = character())
  }
  anno[["example"]] <- examples
  anno
}

hashpipe_yaml_lines <- function(x) {
  x <- sub("^[ \t]+", "", x, perl = TRUE)
  stopifnot(startsWith(x, "#| "))
  substr(x, 4L, .Machine$integer.max)
}
