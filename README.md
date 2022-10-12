

# Rapp

<!-- badges: start -->
<!-- badges: end -->

Rapp (short for "R application") makes it fun to write and share command line applications in R.

It is an alternative front end to R, a drop-in replacement for `Rscript` that
does automatic handling of command line arguments. It converts a simple
R script into a command line application with a rich and robust support for command line arguments.

It aims to provides a seamless transition from interactive repl-driven development to non-interactive execution with command line arguments.

Here is a simple example Rapp:

```R
#!/usr/bin/env Rapp
#| name: flip-coin
#| description: |
#|   flip a coin.

#| description: number of coin flips
n <- 1

cat(sample(c("heads", "tails"), n, TRUE),
    fill = TRUE)
```


Then you can invoke it from the command line:
```bash
$ flip-coin
tails

$ flip-coin --n=3
tails heads tails

$ flip-coin --help --yaml
name: flip-coin
description: flip a coin.
options:
  'n':
    default: 1.0
    val_type: float
    arg_type: option
    description: number of coin flips
arguments: {}
```

Application options and arguments work like this:

### Options

Simple assignments of scalar literals at the top level of the R script
are automatically as *options*.
```R
n <- 1
```
becomes an option at the command line:
```bash
flip-coin --n 1
```

Option values passed from the command line are parsed as yaml/json, and then coerced
to the original R option type.

### Positional Arguments

Simple assignments of length-0 objects at the top level of an R script become
positional arguments. If the R symbol has a `...` suffix or prefix, it is a collector 
for a variable number of positional arguments. Positional arguments always come into the R app as character strings.

```
args... <- c()
```

## Shipping an Rapp as part of an R package

You can easily share your R app command line executable as part of your
package as part of an R package.

-  Add {Rapp} as a dependency in your DESCRIPTION
-  Place your app in the `exec` folder in your package, e.g: `exec/myapp`.
   Apps are automatically installed as executable.
-  Instruct your users to add executables from Rapp and your package to their PATH.
   On Linux and macOS, add the following to .bashrc or .zshrc (or equivalent)

```bash
export PATH=$(Rscript -e 'cat(system.file("exec", package = "Rapp"))'):$PATH
export PATH=$(Rscript -e 'cat(system.file("exec", package = "my.package.name"))'):$PATH
```

# Windows

Rapp works on Windows. However, because there is no native support for `!#` shebang
executable on Windows, you must invoke Rapp directly.
```cmd
Rapp flip-coin --n 3
```

## More examples

See the `inst/examples` folder for more example R apps.
