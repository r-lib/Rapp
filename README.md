# Rapp <img src="man/figures/logo.png" alt="Rapp logo" align="right" height="138"/>

<!-- badges: start -->

[![R-CMD-check](https://github.com/r-lib/Rapp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/Rapp/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

Rapp (short for "R application") makes it fun to write and share command
line applications in R.

It is an alternative front end to R, a drop-in replacement for `Rscript`
that automatically parses command line arguments into R values. The goal
is to make it easy to build a polished CLI application from a simple R
script.

It aims to provide a seamless transition from interactive repl-driven
development at the R console to non-interactive execution at the command
line.

Here is an example Rapp, a simple R script named `flip-coin.R`:

``` r
#!/usr/bin/env Rapp
#| description: Flip a coin.

#| description: Number of coin flips
n <- 1L

cat(sample(c("heads", "tails"), n, TRUE), fill = TRUE)
```

You can invoke it from the command line:

``` bash
$ flip-coin
tails
```

``` bash
$ flip-coin --n 3
tails heads tails
```

``` bash
$ flip-coin --help
Usage: flip-coin [OPTIONS]

Flip a coin.

Options:
  --n <FLIPS>    Number of coin flips
                 [default: 1] [type: integer]
```

``` bash
$ flip-coin --help-yaml
name: flip-coin
description: Flip a coin.
options:
  'n':
    default: 1
    val_type: integer
    arg_type: option
    action: replace
    description: Number of coin flips
```



## Defining the CLI

Rapp recognizes a small set of expression patterns at the top level of
your script and converts them into command-line options, flags, positional
arguments, and commands. The sections below cover the supported patterns.


### Help

All Rapps comes with built-in flags for help.

-   `--help` shows usage, description, and options for the app (and for subcommands
    when used after a command, e.g., `todo list --help`).
-   `--help-yaml` prints machine-readable metadata for the app as YAML.

### Options

Simple assignments of scalar (length-1) literals at the top level of the
R script are automatically treated as command line *options*.

``` r
n <- 1
```

becomes an option at the command line:

``` bash
flip-coin --n 1
```

Non-string option values passed from the command line are parsed as
YAML/JSON, and then coerced to the original R type. Values can be
supplied after the option flag, or as part of the option flag string
with `=`. The following two usages are the same:

``` bash
flip-coin --n=1
flip-coin --n 1
```

Bool options, (that is, assignments of `TRUE` or `FALSE` in an R app)
are a little different. They support usage as switches or toggles at the
command line. For example in an R script:

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

Assigning `c()` or `list()` declares an option that can be supplied
multiple times. Use `c()` when you want to keep the exact strings
provided on the command line, and `list()` when you want Rapp to attempt
to parse the supplied strings as YAML/JSON values and convert them into
R objects. For example, a repeatable filter option that keeps raw
strings:

``` r
#| description: File name patterns to include (repeatable).
pattern <- c()
```

can be invoked as:

``` bash
list-files --pattern '*.csv' --pattern 'sales-*'
```

Or, to collect numeric limits and have them parsed into integers:

``` r
#| description: Score thresholds (parsed as numbers, repeatable).
threshold <- list()
```

which lets callers supply structured values:

``` bash
report --threshold 5 --threshold '[10, 20, 30]'
```

### Positional arguments

Assigning `NULL` to a symbol declares a positional argument. If the
symbol has a `...` suffix or prefix, it becomes a collector for a
variable number of positional arguments. Positional arguments always
come into the R app as character strings, and they are required by
default unless you mark them as `required: false` via annotations.

For example, this small `greet` app declares a required `<NAME>` positional
argument and prints it:

``` r
#!/usr/bin/env Rapp
#| name: greet
#| description: Greet someone.

#| description: Name to greet.
name <- NULL

cat("Hello ", name, "!\n", sep = "")
```

Running it shows how positional arguments appear in `--help`:

``` bash
$ greet --help
Greet someone.

Usage: greet <NAME>

Arguments:
  <NAME>  Name to greet.
```

To make the positional argument optional, add an annotation above the
assignment:

``` r
#| required: false
name <- NULL
```
This changes the usage to `Usage: greet [<NAME>]` (with brackets).

### Commands

Use a `switch()` statement whose first argument is either a character
scalar or an assignment (for example `switch("")` or
`switch(command <- "", ...)`) to declare commands. The corresponding
branch runs when the matching command is supplied on the command line.
Declare command specific options and positional arguments with the same
rules inside the branch.

``` r
#!/usr/bin/env Rapp
#| name: todo
#| title: Todo manager
#| description: Manage a simple todo list.

#| description: Path to the todo list file.
#| short: s
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

The command shown above exposes a `todo` app with `list`, `add`, and
`done` commands. Each command can declare its own options (`limit`,
`index`) or positional arguments (`task`), and command metadata can be
documented with the same hash-pipe annotations used for options.

Command-line help reflects the available commands, and each command has
its own help page:

``` bash
$ todo --help
Todo manager

Usage: todo [OPTIONS] <COMMAND>

Manage a simple todo list.

Commands:
  list  Display the todos
  add   Add a new todo
  done  Mark a task as completed
```

``` bash
$ todo list --help
Display the todos

Usage: todo list [OPTIONS]

Print the contents of the todo list.

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

Help output automatically includes any parent and global options for
nested commands.

### Annotations

You can add YAML hash-pipe annotations in the script front matter or
right above individual options. YAML annotations are primarily used to
adjust help output. The entries you'll most commonly use are `title` and
`description`. Another YAML annotation you can provide is `short`, a
short option name. For example:

``` r
#!/usr/bin/env Rapp
#| description: Flip a coin.

#| description: Number of coin flips
#| short: n
n_flips <- 1L

cat(sample(c("heads", "tails"), n_flips, TRUE))
```

then lets you supply the alias `-n` or the full option name `--n-flips`
at the command line (note also the automatic mapping of snake case
`n_flips` to kebab-case `--n-flips`).

``` bash
$ flip-coin --help
Usage: flip-coin [OPTIONS]

Flip a coin.

Options:
  -n, --n-flips <N-FLIPS>  Number of coin flips
                           [default: 1] [type: integer]
```

``` bash
$ flip-coin -n 3
tails heads heads
```

Other YAML fields you can supply to change the behavior of Rapp

- `val_type`: expected value type (`string`, `integer`, `float`, `bool`; `any`).
- `arg_type`: how the input appears on the CLI (`option`, `switch`, `positional`).
- `action`: whether values replace or accumulate (`replace` vs `append` for
  repeatable options and collectors).

## Summary

Here is a summary table of different R expressions that Rapp treats as
command line arguments.

| R Expression | CLI surface |
|----|----|
| Assignment of scalar literal<br>`foo <- ""` | Option<br>`APP --foo value` |
| Assignment of `NULL`<br>`foo <- NULL` | Positional Arg<br>`APP foo-value` |
| Assignment of `TRUE` or `FALSE`<br>`foo <- TRUE` | Boolean switch<br>`APP --foo` or `APP --no-foo` |
| Assignment of `c()` or `list()`<br>`foo <- c()` | Repeatable option<br>`APP --foo val1 --foo val2` |
| Assignment of `NULL` to name with `...`<br>`args... <- NULL` | Positional Arg Collector<br>`APP foo bar baz` |
| Switch with string literal<br>`switch("", cmd1 = {}, cmd2 = {})` | Commands<br>`APP cmd1 --help`<br>`APP cmd2 --help` |

### Running interactively

While developing, you can drive the app directly from R:

``` r
Rapp::run("path/to/app.R", c("--help"))
Rapp::run("path/to/app.R", c("--myopt", "my-opt-val"))
```

Pass a character vector of arguments exactly as you would supply them on
the command line. Inside the app you can drop `browser()` statements to
pause execution and inspect state while `Rapp::run()` executes.

### Installation

``` r
# Install the package
install.packages("Rapp")

# Add `Rapp` to your PATH
Rapp::install_pkg_cli_apps("Rapp")
```

Alternatively, install the development version:

``` r
# pak::pak("r-lib/Rapp")
# remotes::install_github("r-lib/Rapp")
```

On macOS and Linux, make your Rapp script executable
(`chmod +x flip-coin.R`) and run them directly. On Windows, or if you
prefer, call the front end explicitly with `Rapp flip-coin.R --n 3`.

## Installing launchers

`Rapp::install_pkg_cli_apps("Rapp")` installs `Rapp` on the `PATH`.

If you are shipping Rapps via an R package, you can call
`Rapp::install_pkg_cli_apps("mypackage")` to install lightweight
launchers for every Rapp (and Rscript shebang) in the package's `exec/`
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
install_mypackage_cli <- function(...) {
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
the `destdir` argument if you prefer an alternate location. If you are
working with a standalone `.R` file on Windows, call the launcher
explicitly (`Rapp path\to\flip-coin.R --n 3`) because native shebangs
are not supported.

### Using package `exec/` directories directly

Launchers are optional. You can add `Rapp` and a package's `exec/`
directory to the `PATH` and run the apps directly from the package's
installed directory. For example, after installing {Rapp}, you can place
something like this in a shell startup script like `.bashrc`:

``` bash
export PATH="$(Rscript -e 'cat(normalizePath(system.file("exec", package = "Rapp")))'):$PATH"
export PATH="$(Rscript -e 'cat(normalizePath(system.file("exec", package = "mypackage")))'):$PATH"
```

On Windows, run
`Rscript -e "cat(normalizePath(system.file('exec', package = 'Rapp')))"`
to print the directory and add it to `PATH` via *System Properties →
Environment Variables*.

## Shipping an Rapp as part of an R package

You can easily share your R app command line executable as part of an R
package.

-   Add {Rapp} as a dependency in your DESCRIPTION.

-   Place your app in the `exec` folder in your package (for example
    `exec/myapp`). Apps are automatically installed as executables.

-   Encourage users to run `Rapp::install_pkg_cli_apps("mypackage")` or
    your own exported wrapper `mypackage::install_mypackage_cli()` after
    installing your package so the launchers land in a directory on
    their `PATH`. `install_pkg_cli_apps()` keeps existing launchers up
    to date and also deletes old launchers for apps that have been
    removed from your package.

-   If [`rig`](https://github.com/r-lib/rig) is already on the `PATH`,
    you can also use `rig` to run a script in a package's `exec`
    directory (Stay tuned, improved rig support is in flight):

    ``` bash
    rig run <pkg>::<script>
    ```

## Windows

Rapp works on Windows. Running `install_pkg_cli_apps()` creates `.bat`
wrappers for each app and installs a top-level `Rapp.bat`, adding their
location to `PATH`. After that, you can invoke apps from R packages just
like on other platforms:

``` cmd
flip-coin --n 3
```

Because Windows does not natively support shebangs, to invoke an Rapp
developed outside an R package, you'll need to invoke the `Rapp`
front-end directly (after calling `Rapp::install_pkg_cli_apps("Rapp")`):

``` cmd
Rapp path/to/flip-coin.R --n 3
```

## More examples

See the [inst/examples](inst/examples) folder for more example R apps.

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
