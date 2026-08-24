# --help-yaml snapshots

    Code
      write_cli_output("flip-coin", "--help-yaml")
    Output
      launcher:
        default_packages:
          - base
          - utils
      name: flip-coin
      description: |
        Flip a coin.
      examples:
        - flip-coin --flips 3
      options:
        flips:
          default: 1
          val_type: integer
          arg_type: option
          action: replace
          description: Number of coin flips
          short: n
          examples:
            - flip-coin -n 30 --no-wrap
        sep:
          default: " "
          val_type: string
          arg_type: option
          action: replace
        wrap:
          default: true
          val_type: bool
          arg_type: switch
          action: replace
        seed:
          default: ~
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
          - yaml12
      name: todo
      title: Todo manager
      description: Manage a simple todo list.
      examples:
        - todo add write-tests
        - todo list
      options:
        store:
          default: ".todo.yml"
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
          examples:
            - todo list --limit 5
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
              required: true
          commands: ~
        done:
          title: Mark a task as completed
          description: Remove a task from the todo list using its index.
          examples:
            - todo done --index 1
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
              default: true
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
                  default: false
                  val_type: bool
                  arg_type: switch
                  action: replace
              arguments:
                child2_arg:
                  default: ~
                  val_type: string
                  arg_type: positional
                  action: replace
                  required: true
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
          - yaml12
      name: todo
      title: Todo manager
      description: Manage a simple todo list.
      examples:
        - todo add write-tests
        - todo list
      options:
        store:
          default: ".todo.yml"
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
          examples:
            - todo list --limit 5
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
              required: true
          commands: ~
        done:
          title: Mark a task as completed
          description: Remove a task from the todo list using its index.
          examples:
            - todo done --index 1
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
              default: true
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
                  default: false
                  val_type: bool
                  arg_type: switch
                  action: replace
              arguments:
                child2_arg:
                  default: ~
                  val_type: string
                  arg_type: positional
                  action: replace
                  required: true
              commands: ~
            help:
              options: ~
              arguments: ~
              commands: ~
        help:
          options: ~
          arguments: ~
          commands: ~

