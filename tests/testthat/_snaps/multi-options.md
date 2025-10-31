# ls app accepts same option multiple times

    Code
      run_ls_app(c(dir, "-p", "alpha", "-p", "\\.txt$"))
    Output
      pattern:
      - alpha
      - \.txt$
      paths:
      - alpha.txt
      - alphabet.txt
      - beta.txt

---

    Code
      run_ls_app(c(dir, "--pattern", "t$", "-p", "^beta"))
    Output
      pattern:
      - t$
      - ^beta
      paths:
      - alpha.txt
      - alphabet.txt
      - beta.R
      - beta.txt

