# todo help output

    Code
      cat(help_lines(app_path), sep = "\n")
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
      cat(help_lines(app_path, "list"), sep = "\n")
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
      cat(help_lines(app_path, "done"), sep = "\n")
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

