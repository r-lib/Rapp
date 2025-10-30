# --help snapshots

    Code
      writeLines(system2("flip-coin", "--help", stdout = TRUE))
    Output
      flip-coin: Flip a coin.
      
      Usage: flip-coin [OPTIONS]
      
      Options:
        -n, --flips <FLIPS>  Number of coin flips [default: 1] [type: integer]
        --sep <SEP>          [default: " "] [type: string]
        --wrap / --no-wrap   [default: true] Disable with `--no-wrap`.
        --seed <SEED>        [default: NA] [type: integer]

---

    Code
      writeLines(system2("todo", "--help", stdout = TRUE))
    Output
      todo: Manage a simple todo list.
      
      Usage: todo [OPTIONS] <COMMAND>
      
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
      writeLines(system2("nested-commands", "--help", stdout = TRUE))
    Output
      nested-commands.R
      
      Usage: nested-commands.R [OPTIONS] <COMMAND>
      
      Commands:
        parent  
        help    
      
      Options:
        --top-opt <TOP-OPT>  [default: "top-default"] [type: string]
      
      For help with a specific command, run: `nested-commands.R <command> --help`.

# command --help snapshots

    Code
      writeLines(system2("todo", "list --help", stdout = TRUE))
    Output
      Display the todos
      
      Print the contents of the todo list.
      
      Usage: todo list [OPTIONS]
      
      Options:
        --limit <LIMIT>  Maximum number of entries to display (-1 for all).
                         [default: 30] [type: integer]
      
      Global options:
        -s, --store <STORE>  Path to the todo list file.
                             [default: ".todo.yml"] [type: string]

---

    Code
      writeLines(system2("todo", "done --help", stdout = TRUE))
    Output
      Mark a task as completed
      
      Remove a task from the todo list using its index.
      
      Usage: todo done [OPTIONS]
      
      Options:
        -i, --index <INDEX>  Index of the task to complete.
                             [default: 1] [type: integer]
      
      Global options:
        -s, --store <STORE>  Path to the todo list file.
                             [default: ".todo.yml"] [type: string]

---

    Code
      writeLines(system2("nested-commands", "parent child2 --help", stdout = TRUE))
    Output
      child2 command
      
      Usage: nested-commands.R parent child2 [OPTIONS] [<CHILD2-ARG>]
      
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
      writeLines(system2("flip-coin", "--help-yaml", stdout = TRUE))
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
          description: Number of coin flips
          short: 'n'
        sep:
          default: ' '
          val_type: string
          arg_type: option
        wrap:
          default: yes
          val_type: bool
          arg_type: switch
        seed:
          default: .na.integer
          val_type: integer
          arg_type: option
      arguments: ~

---

    Code
      writeLines(system2("todo", "--help-yaml", stdout = TRUE))
    Output
      launcher:
        default_packages:
        - base
        - utils
        - yaml
      name: todo
      description: Manage a simple todo list.
      options:
        store:
          default: .todo.yml
          val_type: string
          arg_type: option
          description: Path to the todo list file.
          short: s
      arguments: ~

---

    Code
      writeLines(system2("nested-commands", "--help-yaml", stdout = TRUE))
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
      arguments: ~

# --help --yaml snapshots

    Code
      writeLines(system2("flip-coin", "--help --yaml", stdout = TRUE))
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
          description: Number of coin flips
          short: 'n'
        sep:
          default: ' '
          val_type: string
          arg_type: option
        wrap:
          default: yes
          val_type: bool
          arg_type: switch
        seed:
          default: .na.integer
          val_type: integer
          arg_type: option
      arguments: ~

---

    Code
      writeLines(system2("todo", "--help --yaml", stdout = TRUE))
    Output
      launcher:
        default_packages:
        - base
        - utils
        - yaml
      name: todo
      description: Manage a simple todo list.
      options:
        store:
          default: .todo.yml
          val_type: string
          arg_type: option
          description: Path to the todo list file.
          short: s
      arguments: ~

---

    Code
      writeLines(system2("nested-commands", "--help --yaml", stdout = TRUE))
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
      arguments: ~

