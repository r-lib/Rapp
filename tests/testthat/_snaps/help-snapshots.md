# --help snapshots

    Code
      write_cli_output("flip-coin", "--help")
    Output
      Usage: flip-coin [OPTIONS]
      
      Flip a coin.
      
      Options:
        -n, --flips <FLIPS>  Number of coin flips [default: 1] [type: integer]
        --sep <SEP>          [default: " "] [type: string]
        --no-wrap
        --seed <SEED>        [default: NA] [type: integer]
      
      Examples:
        flip-coin --flips 3
        flip-coin -n 30 --no-wrap

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
      
      Examples:
        todo add write-tests
        todo list
      
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
      
      Examples:
        todo list --limit 5

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
      
      Examples:
        todo done --index 1

---

    Code
      write_cli_output("nested-commands", c("parent", "child2", "--help"))
    Output
      Usage: nested-commands parent child2 [OPTIONS] <CHILD2-ARG>
      
      child2 command
      
      Options:
        --child2-opt <CHILD2-OPT>  [default: "child2-default"] [type: string]
        --child2-switch
      
      Parent options:
        --parent-opt <PARENT-OPT>  [default: "parent-default"] [type: string]
        --no-parent-switch
      
      Global options:
        --top-opt <TOP-OPT>  [default: "top-default"] [type: string]

