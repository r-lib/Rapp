# CLI invocation prints a hint before failing

    Code
      writeLines(run_cli_app(erroring_app))
    Output
      Error: boom
      Hint: run with --help to view usage information.

# CLI handles underscored commands

    Code
      writeLines(run_cli_app(underscored_app, "foo-bar"))
    Output
      $cmd
      [1] "foo_bar"
      
      $foo_bar_flag
      [1] TRUE
      

