# missing literal command switch prints help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: required-command-test
        #| description: Exercise missing command help.
        
        switch('',
          #| title: List entries
          list = { cat('list called\n') }
        )
      invocation:
        - usage: $ required-command-test
          output: |-
            Usage: required-command-test <COMMAND>
            
            Exercise missing command help.
            
            Commands:
              list  List entries
            
            For help with a specific command, run: `required-command-test <command> --help`.
        - usage: $ required-command-test list
          output: list called
      ...

# missing command assignment prints help by default

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: assigned-command-test
        #| description: Exercise missing command help.
        
        switch(command <- '',
          #| title: List entries
          list = { cat(command, '\n', sep = '') }
        )
      invocation:
        - usage: $ assigned-command-test
          output: |-
            Usage: assigned-command-test <COMMAND>
            
            Exercise missing command help.
            
            Commands:
              list  List entries
            
            For help with a specific command, run: `assigned-command-test <command> --help`.
        - usage: $ assigned-command-test list
          output: list
      ...

# required false command switch allows missing command

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: optional-command-test
        
        #| required: false
        switch(command <- '',
          #| title: List entries
          list = { cat(command, '\n', sep = '') }
        )
        cat('no command\n')
      invocation:
        - usage: $ optional-command-test
          output: no command
        - usage: $ optional-command-test list
          output: |-
            list
            no command
        - usage: $ optional-command-test --help
          output: |-
            Usage: optional-command-test [<COMMAND>]
            
            optional-command-test
            
            Commands:
              list  List entries
            
            For help with a specific command, run: `optional-command-test <command> --help`.
      ...

# missing command prints help before matching positionals

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: command-with-positional-test
        
        #| description: Input path.
        input <- NULL
        
        switch('',
          #| title: Run command
          run = { cat('run ', input, '\n', sep = '') }
        )
        cat('no command\n')
      invocation:
        - usage: $ command-with-positional-test data.csv
          output: |-
            Usage: command-with-positional-test <COMMAND> <INPUT>
            
            command-with-positional-test
            
            Commands:
              run  Run command
            
            Arguments:
              <INPUT>  Input path.
            
            For help with a specific command, run: `command-with-positional-test <command> --help`.
        - usage: $ command-with-positional-test run data.csv
          output: |-
            run data.csv
            no command
      ...

# missing nested command prints scoped help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: nested-required-command-test
        
        switch('',
          #| title: Parent command
          parent = {
            switch('',
              #| title: Child command
              child = { cat('child called\n') }
            )
          }
        )
      invocation:
        - usage: $ nested-required-command-test parent
          output: |-
            Parent command
            
            Usage: nested-required-command-test parent <COMMAND>
            
            Commands:
              child  Child command
            
            For help with a specific command, run: `nested-required-command-test parent <command> --help`.
        - usage: $ nested-required-command-test parent child
          output: child called
      ...

# optional parent command preserves required child help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: optional-parent-required-child-test
        
        #| required: false
        switch(parent_cmd <- '',
          #| title: Parent command
          parent = {
            switch(child_cmd <- NULL,
              #| title: Child command
              child = { cat('child called\n') }
            )
          }
        )
      invocation:
        - usage: $ optional-parent-required-child-test parent
          output: |-
            Parent command
            
            Usage: optional-parent-required-child-test parent <COMMAND>
            
            Commands:
              child  Child command
            
            For help with a specific command, run: `optional-parent-required-child-test parent <command> --help`.
        - usage: $ optional-parent-required-child-test parent child
          output: child called
      ...

