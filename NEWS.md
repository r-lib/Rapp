# Rapp (development version)

## Breaking changes

-   Rapp now parses YAML with YAML 1.2 semantics. Bare `yes` and `no`
    non-bool option values are strings, not boolean aliases. Declared
    bool options still accept YAML 1.1 bool aliases such as `yes`, `no`,
    `y`, `n`, `on`, and `off` for backward compatibility.
-   Rapp now checks parsed command line values against declared option
    types instead of coercing them. Integer options no longer accept
    float or logical values such as `10.2` or `true`; float options still
    accept integer values (#18).

## New features

-   `#| examples` annotations now add usage examples to `--help` output
    (#23).

## Bug fixes

-   On macOS, `install_pkg_cli_apps()` now adds the default `~/.local/bin`
    install directory to `~/.zprofile` when it is not already on `PATH`
    (#35).
-   Launcher front matter now accepts documented kebab-case option names
    such as `default-packages`. Installation docs now clarify that package
    apps are discovered as `exec/*.R`, installed without the `.R` extension
    by default, and installed to `RAPP_BIN_DIR` when set (#19, #20).
-   Running tests no longer modifies the user `PATH` on Windows (#26).
-   Rapp now installs from source on R versions before 4.0.0 by avoiding
    raw string literal syntax (#30).

# Rapp 0.3.0

## Breaking changes

-   Positional arguments are now required by default. Use
    `#| required: false` to make an argument optional (#13).

## New features

-   `#| short` now adds a short option alias like `-n` (#4, #5).
-   `c()` and `list()` assignments now declare repeatable options.
-   `install_pkg_cli_apps()` installs launchers for `Rapp` and `Rscript`
    apps in a package's `exec/` directory on the user's `PATH` (#3, #7).
-   `switch()` blocks can now declare commands in Rapp applications (#8,
    #11).

# Rapp 0.2.0

-   Updated default `--help` output.
-   Added a package logo.
-   Moved repository to 'r-lib' on Github
-   Added a `NEWS.md` file to track changes to the package.

# Rapp 0.1.0

-   Initial release
