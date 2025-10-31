# Rapp <img src="man/figures/logo.png" align="right" height="138"/>

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-lib/Rapp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/Rapp/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

Rapp (short for "R application") makes it fun to write and share command
line applications in R.

It is an alternative front end to R, a drop-in replacement for `Rscript`
that parses command line arguments automatically. The goal is to make it
easy to build a polished CLI application from a simple R script.

Here is a simple example Rapp:

``` r
#!/usr/bin/env Rapp
#| name: flip-coin
#| description: Flip a coin.

#| description: Number of coin flips
n <- 1L

cat(sample(c("heads", "tails"), n, TRUE), fill = TRUE)
```

Then you can invoke it from the command line:

``` bash
$ flip-coin
tails

$ flip-coin --n=3
tails heads tails

$ flip-coin --help
Flip a coin.

Usage: flip-coin [options]

Options:
  --n <value>  (Default: 1, Type: integer)
      Number of coin flips

$ flip-coin --help --yaml
name: flip-coin
description: Flip a coin.
options:
  'n':
    default: 1
    val_type: integer
    arg_type: option
    description: Number of coin flips
arguments: {}
```

Application options and arguments work like this:

| Script declaration | CLI usage | Effect |
| --- | --- | --- |
| `foo <- NULL` | `APP <FOO>` | Positional argument with a default value |
| `foo <- TRUE` / `foo <- FALSE` | `APP --foo` / `APP --no-foo` | Boolean switch |
| `foo <- 1`, `foo <- 1.5`, `foo <- "value"` | `APP --foo VALUE` | Single-value option |
| `foo <- c()` / `foo <- list()` | `APP --foo value1 --foo value2` | Repeatable option that appends each value |

## Options

Simple assignments of scalar (length-1) literals at the top level of the
R script are automatically treated as command line *options*.

``` r
n <- 1
```

becomes an option at the command line:

``` bash
flip-coin --n 1
```

Option values passed from the command line are parsed as yaml/json, and
then coerced to the original R type. The following option value types
are supported: int, float, string, and bool. Values can be supplied
after the option, or as part of the option with `=`. The following two
usages are the same:

``` bash
flip-coin --n=1
flip-coin --n 1
```

Bool options, (that is, assignments of `TRUE` or `FALSE` in an R app)
are a little different. They support usage as switches at the command
line. For example in an R script:

``` r
echo <- TRUE
```

means that at the command line the following are supported:

``` r
my-app --echo       # TRUE
my-app --echo=yes   # TRUE
my-app --echo=true  # TRUE
my-app --echo=1     # TRUE

my-app --no-echo     # FALSE
my-app --echo=no     # FALSE
my-app --echo=false  # FALSE
my-app --echo=0      # FALSE
```

Hash-pipe annotations are parsed as YAML values. Quote scalars such as
`'n'` or `'yes'` when you need a literal string instead of YAML's boolean
interpretation.

Assigning `c()` or `list()` now declares a repeatable option. Each time
the option is supplied, its value is appended in order. For example:

``` r
pattern <- c()
```

becomes:

``` bash
ls-r --pattern alpha --pattern ".*\\.txt$"
```

## Positional arguments

Assigning `NULL` to a symbol declares a positional argument. If the symbol has a `...` suffix or prefix, it becomes
a collector for a variable number of positional arguments. Positional
arguments always come into the R app as character strings. Mark a
positional argument as required with `#| required: true` (this only adjusts help output, you'll still need to throw an appropriate error form your app).

``` r
args... <- NULL
```

or

``` r
first_arg      <- NULL
...middle_args <- NULL
last_arg       <- NULL
```

## Commands

Use a `switch()` statement whose first argument is either a character
scalar or an assignment (for example `switch("")` or
`switch(command <- "", ...)`) to declare commands. The corresponding
branch runs when the matching command is supplied on the command line.
Declare command specific options and positional arguments with the same
rules inside the branch.

``` r
#!/usr/bin/env Rapp
#| name: todo
#| title: Manage a simple todo list.
#| description: Manage a simple todo list.

store <- ".todo.yml"

switch(
  "",

  #| title: Display the todos
  #| description: Print the contents of the todo list.
  list = {
    limit <- 30L
    ...
  },

  #| title: Add a new todo
  add = {
    task <- NULL
    ...
  },

  #| title: Mark a task as completed
  done = {
    index <- 1L
    ...
  }
)
```

The command shown above exposes a `todo` launcher with `list`, `add`,
and `done` commands. Each command can declare its own options (`limit`,
`index`) or positional arguments (`task`), and command metadata can be
documented with the same hash-pipe annotations used for options.

Command-line help reflects the available commands, and each command has
its own help page:

``` bash
$ todo --help
todo: Manage a simple todo list.

Usage: todo [OPTIONS] <COMMAND>

Commands:
  list  Display the todos
  add   Add a new todo
  done  Mark a task as completed

$ todo list --help
Display the todos

Usage: todo list [OPTIONS]

Options:
  --limit <LIMIT>  Maximum number of entries to display (-1 for all).
                   [default: 30] [type: integer]

Global options:
  -s, --store <STORE>  Path to the todo list file.
                       [default: ".todo.yml"] [type: string]
```

Commands can be nested by including additional `switch()` blocks inside
a command branch; each level adds its own command-specific options,
help, and positional arguments.

## Installing launchers

Run `Rapp::install_pkg_cli_apps("Rapp")` to install `Rapp` on the
`PATH`.

If you are shipping Rapps via an R package, you can call
`Rapp::install_pkg_cli_apps("mypackage")` to create lightweight
launchers for every Rapp (and Rscript shebang) in the packages `exec/`
directory.

``` r
Rapp::install_pkg_cli_apps("mypackage")
```

You can either include the command in install instructions, or export
your own thin wrapper:

``` r
#' Install `mypackage` cli applications.
#'
#' @inheritDotParams Rapp::install_pkg_cli_apps -package -lib.loc
#' @export
#' @examples
#' \dontrun{
#' mypackage::install_cli()
#' }
install_cli <- function(...) {
  Rapp::install_pkg_cli_apps(package = "mypackage", lib.loc = NULL, ...)
}
```

App launchers are written to `destdir`, which defaults to the first
available location from `RAPP_INSTALL_DIR`, `XDG_BIN_HOME`,
`XDG_DATA_HOME/../bin`, or the default location, `~/.local/bin` on macOS
and Linux and `%LOCALAPPDATA%\Programs\R\Rapp\bin` on Windows. On
Windows the directory is automatically added to `PATH`; on macOS and
Linux the directory generally is already present on `PATH` (you may need
to restart your shell if the Rapp installer created the directory). Use
the `destdir` argument if you prefer an alternate location.

## Shipping an Rapp as part of an R package

You can easily share your R app command line executable as part of an R
package.

-   Add {Rapp} as a dependency in your DESCRIPTION.

-   Place your app in the `exec` folder in your package (for example
    `exec/myapp`). Apps are automatically installed as executables.

-   Encourage users to run
    `Rapp::install_pkg_cli_apps(c("your.package.name"))` or your own
    exported wrapper `your.package.name::install_cli()` after installing
    your package so the launchers land in a directory on their `PATH`.
    This keeps existing launchers up to date and also deletes old
    launchers for apps that have been removed from your package.

-   If [`rig`](https://github.com/r-lib/rig) is already on the `PATH`,
    you can also use `rig` to run a script in a packages `exec`
    directory:

    ``` bash
    rig run <pkg>::<script>
    ```

# Windows

Rapp works on Windows. Running `install_pkg_cli_apps()` creates `.bat`
wrappers for each app and installs a top-level `Rapp.bat`, adding their
location to `PATH`. After that, you can invoke apps from R packages just
like on other platforms:

``` cmd
flip-coin --n 3
```

Because windows does not natively support shebangs, to invoke an Rapp
developed outside an R package, you'll need to invoke the `Rapp`
front-end directly (after calling `Rapp::install_pkg_cli_apps("Rapp")`):

``` cmd
Rapp path/to/flip-coin.R --n 3
```

## More examples

See the `inst/examples` folder for more example R apps.

## Other Approaches

This package is just one set of ideas for how to build command line apps
in R. Some other packages in this space:

-   [littler](https://github.com/eddelbuettel/littler) (typically paired
    with one of the below)
-   [docopt](https://github.com/docopt/docopt.R)
-   [optparse](https://github.com/trevorld/r-optparse)
-   [argparse](https://github.com/trevorld/r-argparse)
-   [argparser](https://CRAN.R-project.org/package=argparser)

Also, some interesting examples of other approaches to exporting cli
interfaces from R packages:

-   [renv](https://github.com/rstudio/renv/blob/main/inst/bin/renv)
-   [bspm](https://github.com/cran4linux/bspm/blob/master/R/scripts.R)
