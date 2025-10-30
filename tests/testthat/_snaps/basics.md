# examples work

    Code
      cat(capture_help_lines(system.file("examples/flip-coin.R", package = "Rapp")),
      sep = "\n")
    Output
      flip-coin: Flip a coin.
      
      Usage: flip-coin [OPTIONS]
      
      Options:
        -n, --flips <FLIPS>  Number of coin flips [default: 1] [type: integer]
        --sep <SEP>          [default: " "] [type: string]
        --wrap / --no-wrap   [default: true] Disable with `--no-wrap`.
        --seed <SEED>        [default: NA] [type: integer]

