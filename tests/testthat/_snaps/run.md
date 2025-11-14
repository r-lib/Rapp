# CLI invocation prints a hint before failing

    Code
      writeLines(run_cli_app(erroring_app))
    Output
      Error: boom
      Hint: run with --help to view usage information.

# CLI handles underscored commands

    Code
      cat("-- foo-bar --\n")
    Output
      -- foo-bar --
    Code
      writeLines(kebab_result)
    Output
      $cmd
      [1] "foo_bar"
      
      $foo_bar_flag
      [1] TRUE
      
    Code
      cat("\n-- foo_bar --\n")
    Output
      
      -- foo_bar --
    Code
      writeLines(snake_result)
    Output
      $cmd
      [1] "foo_bar"
      
      $foo_bar_flag
      [1] TRUE
      

