# missing literal command switch prints help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: "#!/usr/bin/env Rapp\\n#| name: required-command-test\\n#| description: Exercise missing command help.\\n\\nswitch('',\\n  #| title: List entries\\n  list = { cat('list called\\n') }\\n)"
      invocation: $ required-command-test
      output: "Usage: required-command-test <COMMAND>\\n\\nExercise missing command help.\\n\\nCommands:\\n  list  List entries\\n\\nFor help with a specific command, run: `required-command-test <command> --help`."
      ...

# missing command assignment prints help by default

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: "#!/usr/bin/env Rapp\\n#| name: assigned-command-test\\n#| description: Exercise missing command help.\\n\\nswitch(command <- '',\\n  #| title: List entries\\n  list = { cat(command, '\\n', sep = '') }\\n)"
      invocation: $ assigned-command-test
      output: "Usage: assigned-command-test <COMMAND>\\n\\nExercise missing command help.\\n\\nCommands:\\n  list  List entries\\n\\nFor help with a specific command, run: `assigned-command-test <command> --help`."
      ...

# required false command switch allows missing command

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: "#!/usr/bin/env Rapp\\n#| name: optional-command-test\\n\\n#| required: false\\nswitch(command <- '',\\n  #| title: List entries\\n  list = { cat(command, '\\n', sep = '') }\\n)\\ncat('no command\\n')"
      invocation: $ optional-command-test
      output: no command
      ...

# missing command prints help before matching positionals

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: "#!/usr/bin/env Rapp\\n#| name: command-with-positional-test\\n\\n#| description: Input path.\\ninput <- NULL\\n\\nswitch('',\\n  #| title: Run command\\n  run = { cat('run ', input, '\\n', sep = '') }\\n)\\ncat('no command\\n')"
      invocation: $ command-with-positional-test data.csv
      output: "Usage: command-with-positional-test <COMMAND> <INPUT>\\n\\ncommand-with-positional-test\\n\\nCommands:\\n  run  Run command\\n\\nArguments:\\n  <INPUT>  Input path.\\n\\nFor help with a specific command, run: `command-with-positional-test <command> --help`."
      ...

# missing nested command prints scoped help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: "#!/usr/bin/env Rapp\\n#| name: nested-required-command-test\\n\\nswitch('',\\n  #| title: Parent command\\n  parent = {\\n    switch('',\\n      #| title: Child command\\n      child = { cat('child called\\n') }\\n    )\\n  }\\n)"
      invocation: $ nested-required-command-test parent
      output: "Parent command\\n\\nUsage: nested-required-command-test parent <COMMAND>\\n\\nCommands:\\n  child  Child command\\n\\nFor help with a specific command, run: `nested-required-command-test parent <command> --help`."
      ...

# optional parent command preserves required child help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: "#!/usr/bin/env Rapp\\n#| name: optional-parent-required-child-test\\n\\n#| required: false\\nswitch(parent_cmd <- '',\\n  #| title: Parent command\\n  parent = {\\n    switch(child_cmd <- NULL,\\n      #| title: Child command\\n      child = { cat('child called\\n') }\\n    )\\n  }\\n)"
      invocation: $ optional-parent-required-child-test parent
      output: "Parent command\\n\\nUsage: optional-parent-required-child-test parent <COMMAND>\\n\\nCommands:\\n  child  Child command\\n\\nFor help with a specific command, run: `optional-parent-required-child-test parent <command> --help`."
      ...

