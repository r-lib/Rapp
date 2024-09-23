#!/usr/bin/env Rapp
#| name: flip-coin
#| description: |
#|   Flip a coin.


#| description: Number of coin flips
#| short: n
flips <- 1L

sep <- " "
wrap <- TRUE

seed <- NA_integer_
if (!is.na(seed))
  set.seed(seed)

cat(sample(c("heads", "tails"), flips, TRUE),
    sep = sep, fill = wrap)


# flip-coin.R
# flip-coin.R --flips 3
# flip-coin.R -n 3
# flip-coin.R --flips=30
# flip-coin.R --flips=30 --wrap
# flip-coin.R -n 30 --no-wrap --sep __
# flip-coin.R -n 30 --no-wrap
