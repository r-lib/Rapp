# integer options require YAML integer values

    Code
      Rapp::run(app_path, c("--flips", "10.2"))
    Condition
      Error:
      ! Invalid value for --flips: expected integer, but parsed "10.2" as float.

---

    Code
      Rapp::run(app_path, c("--flips", "TRUE"))
    Condition
      Error:
      ! Invalid value for --flips: expected integer, but parsed "TRUE" as bool.

