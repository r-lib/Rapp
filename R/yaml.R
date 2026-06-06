#' @export
print.rapp_yaml <- function(x, ...) {
  out <- yaml12::format_yaml(x, ...)
  writeLines(out)

  invisible(out)
}

parse_yaml <- function(...) maybe_as_yaml(yaml12::parse_yaml(...))

parse_hashpipe_yaml <- function(x, ...) {
  x <- sub("^[ \t]+", "", x, perl = TRUE)
  stopifnot(startsWith(x, "#| "))
  x <- substr(x, 4L, .Machine$integer.max)
  parse_yaml(x, ...)
}

as_yaml <- function(x) maybe_as_yaml(as.list(x))

maybe_as_yaml <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.atomic(x) && length(x) != 1L) {
    x <- as.list(x)
  }
  if (is.list(x)) {
    class(x) <- "rapp_yaml"
  }
  x
}


# no partial matching, preserve 'rapp_yaml' class on sublists
#' @export
`$.rapp_yaml` <- function(x, ...) maybe_as_yaml(unclass(x)[[...]])

#' @export
`[[.rapp_yaml` <- function(x, ...) maybe_as_yaml(NextMethod())

#' @export
`[.rapp_yaml` <- `[[.rapp_yaml`
