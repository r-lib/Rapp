# --help snapshots

    Code
      write_cli_output("flip-coin", "--help")
    Output
      Usage: flip-coin [OPTIONS]
      
      Flip a coin.
      
      Options:
        -n, --flips <FLIPS>  Number of coin flips [default: 1] [type: integer]
        --sep <SEP>          [default: " "] [type: string]
        --wrap / --no-wrap   [default: true] Disable with `--no-wrap`.
        --seed <SEED>        [default: NA] [type: integer]

---

    Code
      write_cli_output("todo", "--help")
    Output
      Todo manager
      
      Usage: todo [OPTIONS] <COMMAND>
      
      Manage a simple todo list.
      
      Commands:
        list  Display the todos
        add   Add a new todo
        done  Mark a task as completed
        help  
      
      Options:
        -s, --store <STORE>  Path to the todo list file.
                             [default: ".todo.yml"] [type: string]
      
      For help with a specific command, run: `todo <command> --help`.

---

    Code
      write_cli_output("nested-commands", "--help")
    Output
      Usage: nested-commands [OPTIONS] <COMMAND>
      
      nested-commands
      
      Commands:
        parent  
        help    
      
      Options:
        --top-opt <TOP-OPT>  [default: "top-default"] [type: string]
      
      For help with a specific command, run: `nested-commands <command> --help`.

# command --help snapshots

    Code
      write_cli_output("todo", c("list", "--help"))
    Output
      Display the todos
      
      Usage: todo list [OPTIONS]
      
      Print the contents of the todo list.
      
      Options:
        --limit <LIMIT>  Maximum number of entries to display (-1 for all).
                         [default: 30] [type: integer]
      
      Global options:
        -s, --store <STORE>  Path to the todo list file.
                             [default: ".todo.yml"] [type: string]

---

    Code
      write_cli_output("todo", c("done", "--help"))
    Output
      Mark a task as completed
      
      Usage: todo done [OPTIONS]
      
      Remove a task from the todo list using its index.
      
      Options:
        -i, --index <INDEX>  Index of the task to complete.
                             [default: 1] [type: integer]
      
      Global options:
        -s, --store <STORE>  Path to the todo list file.
                             [default: ".todo.yml"] [type: string]

---

    Code
      write_cli_output("nested-commands", c("parent", "child2", "--help"))
    Output
      Usage: nested-commands parent child2 [OPTIONS] <CHILD2-ARG>
      
      child2 command
      
      Options:
        --child2-opt <CHILD2-OPT>       [default: "child2-default"] [type: string]
        --child2-switch / --no-child2-switch  [default: false]
                                        Enable with `--child2-switch`.
      
      Parent options:
        --parent-opt <PARENT-OPT>       [default: "parent-default"] [type: string]
        --parent-switch / --no-parent-switch  [default: true]
                                        Disable with `--no-parent-switch`.
      
      Global options:
        --top-opt <TOP-OPT>  [default: "top-default"] [type: string]

# --help-yaml snapshots

    Code
      write_cli_output("flip-coin", "--help-yaml")
    Output
      launcher:
        default_packages:
        - base
        - utils
      name: flip-coin
      description: Flip a coin.
      options:
        flips:
          default: 1
          val_type: integer
          arg_type: option
          action: replace
          description: Number of coin flips
          short: 'n'
        sep:
          default: ' '
          val_type: string
          arg_type: option
          action: replace
        wrap:
          default: yes
          val_type: bool
          arg_type: switch
          action: replace
        seed:
          default: .na.integer
          val_type: integer
          arg_type: option
          action: replace
      arguments: ~
      commands: ~

---

    Code
      write_cli_output("todo", "--help-yaml")
    Output
      launcher:
        default_packages:
        - base
        - utils
        - yaml
      name: todo
      title: Todo manager
      description: Manage a simple todo list.
      options:
        store:
          default: .todo.yml
          val_type: string
          arg_type: option
          action: replace
          description: Path to the todo list file.
          short: s
      arguments: ~
      commands:
        list:
          title: Display the todos
          description: Print the contents of the todo list.
          options:
            limit:
              default: 30
              val_type: integer
              arg_type: option
              action: replace
              description: Maximum number of entries to display (-1 for all).
          arguments: ~
          commands: ~
        add:
          title: Add a new todo
          description: Append a task description to the todo list.
          options: ~
          arguments:
            task:
              default: ~
              val_type: string
              arg_type: positional
              action: replace
              description: Task description to add.
              required: yes
          commands: ~
        done:
          title: Mark a task as completed
          description: Remove a task from the todo list using its index.
          options:
            index:
              default: 1
              val_type: integer
              arg_type: option
              action: replace
              description: Index of the task to complete.
              short: i
          arguments: ~
          commands: ~
        help:
          options: ~
          arguments: ~
          commands: ~

---

    Code
      write_cli_output("nested-commands", "--help-yaml")
    Output
      launcher:
        default_packages:
        - base
        - utils
      options:
        top_opt:
          default: top-default
          val_type: string
          arg_type: option
          action: replace
      arguments: ~
      commands:
        parent:
          options:
            parent_opt:
              default: parent-default
              val_type: string
              arg_type: option
              action: replace
            parent_switch:
              default: yes
              val_type: bool
              arg_type: switch
              action: replace
          arguments: ~
          commands:
            child1:
              options:
                child1_flag:
                  default: child1-default
                  val_type: string
                  arg_type: option
                  action: replace
              arguments: ~
              commands: ~
            child2:
              options:
                child2_opt:
                  default: child2-default
                  val_type: string
                  arg_type: option
                  action: replace
                child2_switch:
                  default: no
                  val_type: bool
                  arg_type: switch
                  action: replace
              arguments:
                child2_arg:
                  default: ~
                  val_type: string
                  arg_type: positional
                  action: replace
                  required: yes
              commands: ~
            help:
              options: ~
              arguments: ~
              commands: ~
        help:
          options: ~
          arguments: ~
          commands: ~

---

    Code
      write_cli_output("todo", c("list", "--help-yaml"))
    Output
      launcher:
        default_packages:
        - base
        - utils
        - yaml
      name: todo
      title: Todo manager
      description: Manage a simple todo list.
      options:
        store:
          default: .todo.yml
          val_type: string
          arg_type: option
          action: replace
          description: Path to the todo list file.
          short: s
      arguments: ~
      commands:
        list:
          title: Display the todos
          description: Print the contents of the todo list.
          options:
            limit:
              default: 30
              val_type: integer
              arg_type: option
              action: replace
              description: Maximum number of entries to display (-1 for all).
          arguments: ~
          commands: ~
        add:
          title: Add a new todo
          description: Append a task description to the todo list.
          options: ~
          arguments:
            task:
              default: ~
              val_type: string
              arg_type: positional
              action: replace
              description: Task description to add.
              required: yes
          commands: ~
        done:
          title: Mark a task as completed
          description: Remove a task from the todo list using its index.
          options:
            index:
              default: 1
              val_type: integer
              arg_type: option
              action: replace
              description: Index of the task to complete.
              short: i
          arguments: ~
          commands: ~
        help:
          options: ~
          arguments: ~
          commands: ~

---

    Code
      write_cli_output("nested-commands", c("parent", "child2", "--help-yaml"))
    Output
      launcher:
        default_packages:
        - base
        - utils
      options:
        top_opt:
          default: top-default
          val_type: string
          arg_type: option
          action: replace
      arguments: ~
      commands:
        parent:
          options:
            parent_opt:
              default: parent-default
              val_type: string
              arg_type: option
              action: replace
            parent_switch:
              default: yes
              val_type: bool
              arg_type: switch
              action: replace
          arguments: ~
          commands:
            child1:
              options:
                child1_flag:
                  default: child1-default
                  val_type: string
                  arg_type: option
                  action: replace
              arguments: ~
              commands: ~
            child2:
              options:
                child2_opt:
                  default: child2-default
                  val_type: string
                  arg_type: option
                  action: replace
                child2_switch:
                  default: no
                  val_type: bool
                  arg_type: switch
                  action: replace
              arguments:
                child2_arg:
                  default: ~
                  val_type: string
                  arg_type: positional
                  action: replace
                  required: yes
              commands: ~
            help:
              options: ~
              arguments: ~
              commands: ~
        help:
          options: ~
          arguments: ~
          commands: ~

