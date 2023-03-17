
print.yaml <- function(x, file = "", ..., append = FALSE) {
  out <- encode_yaml(x, ...)
  for (f in file)
    cat(out, file = f, sep = "\n", append = append)

  invisible(out)
}

read_yaml <- function(...) maybe_as_yaml(yaml::read_yaml(...))

parse_yaml <-  function(...) maybe_as_yaml(yaml::yaml.load(...))

parse_hashpipe_yaml <- function(x, ...) {
  stopifnot(startsWith(x, "#| "))
  x <- substr(x, 4L, .Machine$integer.max)
  parse_yaml(x, ...)
}

as_yaml <- function(x) maybe_as_yaml(as.list(x))

encode_yaml <- function(x, ...) {
  as_yaml_args <- utils::modifyList(list(
    precision = 16L,
    handlers = list(complex = as.character)
  ),
  list(...))
  out <- do.call(yaml::as.yaml, c(list(x), as_yaml_args))
  out <- strsplit(out, "\n", fixed = TRUE)[[1L]]
  out
}

# yaml <- function(...)
#   as_yaml(rlang::dots_list(..., .named = TRUE))

maybe_as_yaml <- function(x) {
  if (is.null(x))
    return(NULL)

  if(is.atomic(x) && length(x) != 1L)
    x <- as.list(x)
  if(is.list(x))
    class(x) <- "yaml"
  x
}


# no partial matching, preserve 'yaml' class on sublists
`$.yaml` <- function(x, ...) maybe_as_yaml(unclass(x)[[...]])

`[[.yaml` <- function(x, ...) maybe_as_yaml(NextMethod())

`[.yaml` <- `[[.yaml`

# @importFrom utils str
# str.yaml <- function(x, ...) {
#   cat("YAML ")
#   str(unclass(x), ...)
# }

registerS3method("print", "yaml", print.yaml)
registerS3method("$", "yaml", `$.yaml`)
registerS3method("[[", "yaml", `[[.yaml`)
registerS3method("[", "yaml", `[.yaml`)
# registerS3method("str", "yaml", str.yaml)
