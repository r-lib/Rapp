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
      invocation: $ required-command-test
      output: |-
        Usage: required-command-test <COMMAND>
        
        Exercise missing command help.
        
        Commands:
          list  List entries
        
        For help with a specific command, run: `required-command-test <command> --help`.
      ...

# missing NULL command assignment prints help

    Code
      yaml12::write_yaml(snapshot)
    Output
      ---
      app: |-
        #!/usr/bin/env Rapp
        #| name: null-command-test
        #| description: Exercise missing command help.
        
        switch(command <- NULL,
          #| title: List entries
          list = { cat(command, '\n', sep = '') }
        )
      invocation: $ null-command-test
      output: |-
        Usage: null-command-test <COMMAND>
        
        Exercise missing command help.
        
        Commands:
          list  List entries
        
        For help with a specific command, run: `null-command-test <command> --help`.
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
      invocation: $ nested-required-command-test parent
      output: |-
        Parent command
        
        Usage: nested-required-command-test parent <COMMAND>
        
        Commands:
          child  Child command
        
        For help with a specific command, run: `nested-required-command-test parent <command> --help`.
      ...

