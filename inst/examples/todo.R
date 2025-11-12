#!/usr/bin/env Rapp
#| name: todo
#| title: Todo manager
#| description: Manage a simple todo list.

#| description: Path to the todo list file.
#| short: s
store <- ".todo.yml"

switch(
  command <- "",

  #| title: Display the todos
  #| description: Print the contents of the todo list.
  list = {
    #| description: Maximum number of entries to display (-1 for all).
    limit <- 30L

    tasks <- if (file.exists(store)) yaml::read_yaml(store) else list()
    if (!length(tasks)) {
      cat("No tasks yet.\n")
    } else {
      if (limit >= 0L) {
        tasks <- head(tasks, limit)
      }

      writeLines(sprintf("%2d. %s\n", seq_along(tasks), tasks))
    }
  },

  #| title: Add a new todo
  #| description: Append a task description to the todo list.
  add = {
    #| description: Task description to add.
    task <- NULL
    if (!length(task)) {
      stop("Please supply a task description.", call. = FALSE)
    }

    tasks <- if (file.exists(store)) yaml::read_yaml(store) else list()
    if (is.null(tasks)) {
      tasks <- list()
    }
    if (!is.list(tasks)) {
      tasks <- as.list(tasks)
    }
    tasks[[length(tasks) + 1L]] <- task
    yaml::write_yaml(tasks, store)
    cat("Added:", task, "\n")
  },

  #| title: Mark a task as completed
  #| description: Remove a task from the todo list using its index.
  done = {
    #| description: Index of the task to complete.
    #| short: i
    index <- 1L

    tasks <- if (file.exists(store)) yaml::read_yaml(store) else list()
    if (is.null(tasks)) {
      tasks <- list()
    }
    if (!is.list(tasks)) {
      tasks <- as.list(tasks)
    }
    index <- as.integer(index)
    if (!length(tasks)) {
      stop("No tasks to complete.", call. = FALSE)
    }
    if (is.na(index) || index < 1L || index > length(tasks)) {
      stop("Task index out of range.", call. = FALSE)
    }

    task <- tasks[[index]]
    tasks[[index]] <- NULL
    yaml::write_yaml(tasks, store)
    cat("Completed:", task, "\n")
  },

  help = {}
)
