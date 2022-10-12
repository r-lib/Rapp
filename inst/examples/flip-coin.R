#!/usr/bin/env Rapp
#| name: flip-coin
#| description: |
#|   flip a coin.


#| description: number of coin flips
n <- 1

sep <- " "
wrap <- TRUE

cat(sample(c("heads", "tails"), n, TRUE),
    sep = sep, fill = wrap)


# Rapp flip-coin.R
# Rapp flip-coin.R --n 3
# Rapp flip-coin.R --n=30
# Rapp flip-coin.R --n=30 --wrap
# Rapp flip-coin.R --n 30 --no-wrap --sep __
# Rapp flip-coin.R --n 30 --no-wrap
