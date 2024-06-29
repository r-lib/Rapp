
str_drop_prefix <- function (x, prefix) {
  if (is.character(prefix)) {
    if (!startsWith(x, prefix))
      return(x)
    prefix <- nchar(prefix)
  }
  substr(x, as.integer(prefix) + 1L, .Machine$integer.max)
}

`subtract<-` <- function(x, value) x - value

`append<-` <- function(x, after = length(x), value)
  append(x, values = value, after = after)

`%||%` <- function(x, y) if(is.null(x)) y else x

imap <- function(.x, .f, ...) {
  out <- .mapply(.f, list(.x, names(.x) %||% seq_along(.x)), list(...))
  names(out) <- names(.x)
  out
}

imap_chr <- function(.x, .f, ...) {
  idx <- names(.x) %||% seq_along(.x)
  out <- vapply(
    X = seq_along(.x),
    FUN = function(i) forceAndCall(n = 2L, FUN = .f, .x[[i]], idx[[i]], ...),
    FUN.VALUE = "", USE.NAMES = FALSE)
  names(out) <- names(.x)
  out
}

map_chr <- function(.x, .f, ...) {
  out <- vapply(X = .x, FUN = .f, FUN.VALUE = "", USE.NAMES = FALSE)
  names(out) <- names(.x)
  out
}
