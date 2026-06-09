# missing literal command switch prints help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app:
        - "#!/usr/bin/env Rapp"
        - "#| name: required-command-test"
        - "#| description: Exercise missing command help."
        - ""
        - "switch('',"
        - "  #| title: List entries"
        - "  list = { cat('list called\\n') }"
        - )
      invocation: $ required-command-test
      output:
        - "Usage: required-command-test <COMMAND>"
        - ""
        - Exercise missing command help.
        - ""
        - "Commands:"
        - "  list  List entries"
        - ""
        - "For help with a specific command, run: `required-command-test <command> --help`."
      ...

# missing command assignment prints help by default

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app:
        - "#!/usr/bin/env Rapp"
        - "#| name: assigned-command-test"
        - "#| description: Exercise missing command help."
        - ""
        - "switch(command <- '',"
        - "  #| title: List entries"
        - "  list = { cat(command, '\\n', sep = '') }"
        - )
      invocation: $ assigned-command-test
      output:
        - "Usage: assigned-command-test <COMMAND>"
        - ""
        - Exercise missing command help.
        - ""
        - "Commands:"
        - "  list  List entries"
        - ""
        - "For help with a specific command, run: `assigned-command-test <command> --help`."
      ...

# required false command switch allows missing command

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app:
        - "#!/usr/bin/env Rapp"
        - "#| name: optional-command-test"
        - ""
        - "#| required: false"
        - "switch(command <- '',"
        - "  #| title: List entries"
        - "  list = { cat(command, '\\n', sep = '') }"
        - )
        - "cat('no command\\n')"
      invocation: $ optional-command-test
      output: no command
      ...

# missing nested command prints scoped help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app:
        - "#!/usr/bin/env Rapp"
        - "#| name: nested-required-command-test"
        - ""
        - "switch('',"
        - "  #| title: Parent command"
        - "  parent = {"
        - "    switch('',"
        - "      #| title: Child command"
        - "      child = { cat('child called\\n') }"
        - "    )"
        - "  }"
        - )
      invocation: $ nested-required-command-test parent
      output:
        - Parent command
        - ""
        - "Usage: nested-required-command-test parent <COMMAND>"
        - ""
        - "Commands:"
        - "  child  Child command"
        - ""
        - "For help with a specific command, run: `nested-required-command-test parent <command> --help`."
      ...

# optional parent command preserves required child help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app:
        - "#!/usr/bin/env Rapp"
        - "#| name: optional-parent-required-child-test"
        - ""
        - "#| required: false"
        - "switch(parent_cmd <- '',"
        - "  #| title: Parent command"
        - "  parent = {"
        - "    switch(child_cmd <- NULL,"
        - "      #| title: Child command"
        - "      child = { cat('child called\\n') }"
        - "    )"
        - "  }"
        - )
      invocation: $ optional-parent-required-child-test parent
      output:
        - Parent command
        - ""
        - "Usage: optional-parent-required-child-test parent <COMMAND>"
        - ""
        - "Commands:"
        - "  child  Child command"
        - ""
        - "For help with a specific command, run: `optional-parent-required-child-test parent <command> --help`."
      ...

