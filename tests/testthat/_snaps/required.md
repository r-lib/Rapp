# missing required positional triggers a helpful error

    Code
      Rapp::run(app_path, character())
    Condition
      Error:
      ! Missing required argument: NAME

# missing required positional in a command triggers a helpful error

    Code
      Rapp::run(app_path, c("add"))
    Condition
      Error:
      ! Missing required argument: TASK

