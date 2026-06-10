# examples work

    Code
      writeLines(run_app("flip-coin.R --help"))
    Output
      Usage: flip-coin [OPTIONS]
      
      Flip a coin.
      
      Options:
        -n, --flips <FLIPS>  Number of coin flips [default: 1] [type: integer]
        --sep <SEP>          [default: " "] [type: string]
        --no-wrap
        --seed <SEED>        [default: NA] [type: integer]
      
      Examples:
        flip-coin --flips 3
        flip-coin -n 30 --no-wrap

