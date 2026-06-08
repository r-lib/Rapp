# integer options require YAML integer values

    Code
      Rapp::run(app_path, c("--flips", "10.2"))
    Condition
      Error:
      ! Invalid value for --flips: expected integer, received "10.2".

---

    Code
      Rapp::run(app_path, c("--flips", "TRUE"))
    Condition
      Error:
      ! Invalid value for --flips: expected integer, received "TRUE".

