str_drop_prefix <- function(x, prefix) {
  if (is.character(prefix)) {
    if (!startsWith(x, prefix)) {
      return(x)
    }
    prefix <- nchar(prefix)
  }
  substr(x, as.integer(prefix) + 1L, .Machine$integer.max)
}


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
    FUN.VALUE = "",
    USE.NAMES = FALSE
  )
  names(out) <- names(.x)
  out
}

map2 <- function(.x, .y, .f, ...) {
  out <- .mapply(.f, list(.x, .y), list(...))
  if (length(.x) == length(out)) {
    names(out) <- names(.x)
  }
  out
}

prune_empty <- function(x) {
  if (is.list(x)) {
    x <- lapply(x, prune_empty)
  }
  x <- x[lengths(x) > 0L]
  if (length(x)) x else NULL
}

map_chr <- function(.x, .f, ...) {
  out <- vapply(X = .x, FUN = .f, FUN.VALUE = "", USE.NAMES = FALSE)
  names(out) <- names(.x)
  out
}

map_lgl <- function(.x, .f, ...) {
  out <- vapply(X = .x, FUN = .f, FUN.VALUE = TRUE, USE.NAMES = FALSE)
  names(out) <- names(.x)
  out
}

parent.pkg <- function(env = parent.frame(2)) {
  if (isNamespace(env <- topenv(env))) {
    as.character(getNamespaceName(env))
  } else {
    NULL
  }
}

is_windows <- function() identical(.Platform$OS.type, "windows")
compact <- function(x) x[lengths(x) > 0]
`%||%` <- function(x, y) if (is.null(x)) y else x
`subtract<-` <- function(x, value) x - value

`append<-` <- function(x, after = NULL, value) {
  if (is.null(after)) c(x, value) else append(x, value, after)
}

`append_arg<-` <- function(x, value) {
  if (is.null(x)) {
    return(call("c", value))
  }
  stopifnot(is.call(x))
  x[[length(x) + 1L]] <- value
  x
}
