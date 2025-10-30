# todo help output

    Code
      cat(capture_help_lines(app_path), sep = "\n")
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
      cat(capture_help_lines(app_path, "list"), sep = "\n")
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
      cat(capture_help_lines(app_path, "done"), sep = "\n")
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

