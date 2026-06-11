# Rapp (development version)

## Breaking changes

- Rapp now checks parsed command line values against declared option
  types instead of coercing them. Integer options require integer
  values, so values like `10.2` or `true` produce an error; float
  options still accept integer values (#18).
- Rapp now parses YAML with YAML 1.2 semantics. Bare `yes` and `no`
  non-Boolean option values are strings, not Boolean aliases. Boolean
  options still accept YAML 1.1 aliases such as `yes`, `no`, `y`, `n`,
  `on`, and `off` for backward compatibility.
- Command switches are now required by default. If a command is omitted,
  Rapp prints scoped help. Add `#| required: false` above the `switch()`
  to allow running without a command (#21).
- Boolean switch help now shows the command-line form that changes the
  default: `foo <- FALSE` shows `--foo`, `foo <- TRUE` shows `--no-foo`,
  and `foo <- NA` shows `--foo / --no-foo`. Passing values remains more
  permissive: switches accept explicit values such as `--foo=false` and
  `--foo false`. See the
  [Boolean option behavior](docs/boolean-options.md) table for the full
  set of accepted forms (#28).

## New features

- `#| examples:` annotations now add usage examples to `--help` output
  (#23).
- Boolean switches now do the expected thing for most users without
  additional configuration. For exceptional needs,
  `#| negative_alias: false` disables generated `--no-*` command-line
  aliases while keeping the positive alias and explicit value forms such
  as `--foo=false` (#24, #28).

## Bug fixes

- Launcher front matter now accepts documented kebab-case option names,
  such as `default-packages` (#19).
- On Windows, tests now preserve the user `PATH` (#26).
- Rapp can now be installed from source on R versions before 4.0.0
  (#30).
- The installation docs now clarify that package apps are discovered as
  `exec/*.R`, installed without the `.R` extension by default, and
  installed to `RAPP_BIN_DIR` when set (#20).
- `install_pkg_cli_apps()` now adds the default `~/.local/bin` install
  directory to the user's zsh profile on macOS when it is not already on
  `PATH`. It respects `ZDOTDIR` and warns if the profile cannot be
  updated (#35).
- On Windows, `install_pkg_cli_apps()` no longer replaces the current
  process `PATH` with only the user-level `Path` after adding launcher
  directories. It now avoids duplicate entries, uses a short path when
  available, and reports too-long user-level `Path` values with a
  remediation hint (#38).

# Rapp 0.3.0

## Breaking changes

- Positional arguments are now required by default. Use
  `#| required: false` to make an argument optional (#13).

## New features

- `#| short` now adds a short option alias like `-n` (#4, #5).
- `c()` and `list()` assignments now declare repeatable options.
- `install_pkg_cli_apps()` installs launchers for `Rapp` and `Rscript`
  apps in a package's `exec/` directory on the user's `PATH` (#3, #7).
- `switch()` blocks can now declare commands in Rapp applications (#8,
  #11).

# Rapp 0.2.0

- The default `--help` output is updated.
- Rapp gains a package logo.
- Rapp is now part of the `r-lib` organization on GitHub.
- Rapp now includes `NEWS.md` to track changes to the package.

# Rapp 0.1.0

- Initial release.
