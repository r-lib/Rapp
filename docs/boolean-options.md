# Boolean Option Behavior

Logical defaults become boolean command-line inputs. Help output shows the
most useful spelling for changing the default, while parsing also accepts
explicit boolean values for convenience.

Help output is intentionally narrower than parsing. For example, `foo <- TRUE`
normally shows `--no-foo`, but `--foo=false` is still accepted because it is an
explicit boolean value for `foo`.

In the table below, `TRUE`, `FALSE`, and `NA` are the resulting R values.
`reject` means the command-line form is not accepted.

| R definition | Help shows | Omitted | `--foo` | `--no-foo` | `--foo=true` | `--foo=false` | `--foo true` | `--foo false` |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `foo <- FALSE` | `--foo` | `FALSE` | `TRUE` | `FALSE` | `TRUE` | `FALSE` | `TRUE` | `FALSE` |
| `foo <- TRUE` | `--no-foo` | `TRUE` | `TRUE` | `FALSE` | `TRUE` | `FALSE` | `TRUE` | `FALSE` |
| `foo <- NA` | `--foo / --no-foo` | `NA` | `TRUE` | `FALSE` | `TRUE` | `FALSE` | `TRUE` | `FALSE` |
| `#| negative_alias: false`<br>`foo <- FALSE` | `--foo` | `FALSE` | `TRUE` | reject | `TRUE` | `FALSE` | `TRUE` | `FALSE` |
| `#| negative_alias: false`<br>`foo <- TRUE` | `--foo <FOO>` | `TRUE` | `TRUE` | reject | `TRUE` | `FALSE` | `TRUE` | `FALSE` |
| `#| negative_alias: false`<br>`foo <- NA` | `--foo` | `NA` | `TRUE` | reject | `TRUE` | `FALSE` | `TRUE` | `FALSE` |
| `#| arg_type: option`<br>`foo <- NA` | `--foo <FOO>` | `NA` | reject | reject | `TRUE` | `FALSE` | `TRUE` | `FALSE` |

Bare `--foo` and `--no-foo` count as supplied values for boolean switches.
Use `#| arg_type: option` when a boolean input should require an explicit
value after `--foo`.

`#| negative_alias: false` only disables the generated `--no-foo` spelling.
It does not disable the positive spelling or explicit value forms such as
`--foo=false`. With `foo <- TRUE`, that leaves no default-changing bare alias,
so help shows `--foo <FOO>` as an explicit-value form.
