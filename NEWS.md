# Rapp 0.3.0

# Rapp 0.3.0

## Breaking changes

- Positional arguments are now required by default. Use `#| required: false` to
  make an argument optional (#13).

## New features

- `#| short` now adds a short option alias like `-n` (#4, #5).
- `c()` and `list()` assignments now declare repeatable options.
- `install_pkg_cli_apps()` installs launchers for `Rapp` and `Rscript` apps in
  a package's `exec/` directory on the user's `PATH` (#3, #7).
- `switch()` blocks can now declare commands in Rapp applications (#8, #11).

# Rapp 0.2.0

-   Updated default `--help` output.
-   Added a package logo.
-   Moved repository to 'r-lib' on Github
-   Added a `NEWS.md` file to track changes to the package.

# Rapp 0.1.0

-   Initial release
