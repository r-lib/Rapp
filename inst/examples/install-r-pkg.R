#!/usr/bin/env Rapp

library(remotes)

force <- FALSE
Ncpus <- 4L

pkgs... <- c()

options("Ncpus" = Ncpus)

install <- function(pkg, ...) {
  if (grepl("^[./]", pkg))
    return(install_local(pkg, ...))

  if (grepl("/", pkg, fixed = TRUE))
    return(install_github(pkg, ...))

  version_spec_idx <- regexec(">|<|=", pkg)
  if(identical(version_spec_idx, -1L))
    return(install_cran(pkg, ...))

  package <- substr(pkg, 1L, version_spec_idx - 1L)
  version <- substr(pkg, version_spec_idx, .Machine$integer.max)
  install_version(package = package, version = version, ...)
}

for (pkg in pkgs...)
  install(pkg, force = force)
