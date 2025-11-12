# Rapp (development version)

-   New `install_pkg_cli_apps()` installs Rapps and R scripts in a
    package's `exec/` directory onto the users `PATH` (#7, #3).
-   Added support for commands in Rapp applications (#8, #11).
-   Added support for short opts (#4, #5).
-   Simple assignment of `c()` or `list()` now creates a repeatable CLI
    option.
-   Positional arguments are now required by default, unless annotation
    `#| required: false` is supplied (#13).

# Rapp 0.2.0

-   Updated default `--help` output.
-   Added a package logo.
-   Moved repository to 'r-lib' on Github
-   Added a `NEWS.md` file to track changes to the package.

# Rapp 0.1.0

-   Initial release
