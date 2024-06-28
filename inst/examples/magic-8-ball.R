#!/usr/bin/env Rapp
#| name: magic-8-ball
#| description: |
#|   Ask a yes-no question and get your answer.

#| description: The question you want to ask.
question <- NULL

if(is.null(question)) {
  question <- if(interactive()) {
    readline("question: ")
  } else {
    cat("question: ")
    question <- readLines(file("stdin"), 1)
  }
} else {
  cat("question:", question, "\n")
}

## pulled from wikipedia
choices <- c(
  "It is certain.",
  "It is decidedly so.",
  "Without a doubt.",
  "Yes definitely.",
  "You may rely on it.",
  "As I see it, yes.",
  "Most likely.",
  "Outlook good.",
  "Yes.",
  "Signs point to yes.",
  "Reply hazy, try again.",
  "Ask again later.",
  "Better not tell you now.",
  "Cannot predict now.",
  "Concentrate and ask again.",
  "Don't count on it.",
  "My reply is no.",
  "My sources say no.",
  "Outlook not so good.",
  "Very doubtful."
)


cat("answer:", sample(choices, 1), "\n")
