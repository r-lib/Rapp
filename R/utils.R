
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
