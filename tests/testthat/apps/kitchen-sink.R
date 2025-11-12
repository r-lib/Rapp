#!/usr/bin/env Rapp
#| name: kitchen-sink
#| title: Kitchen Sink CLI
#| description: Comprehensive argument coverage for testing.

#| short: s
#| description: opt that can be supplied once
opt_replace <- "default"

#| short: p
#| description: opt that can be supplied multiple times
opt_append <- c()

#| description: Enable or disable the feature flag.
opt_switch <- FALSE

#| description: Integer option to exercise coercion.
opt_integer <- 1L

#| description: Floating point option to exercise coercion.
opt_numeric <- 1.5

#| description: Parsed as YAML when supplied.
opt_yaml_parsed <- "{}"

#| description: Kept as literal string even if YAML-like.
opt_yaml_literal <- "[1,2]"

#| description: optional arg
#| required: false
optional_positional <- NULL

#| description: optional arg with non-null default
#| arg-type: positional
#| required: false
optional_positional_default <- "foo"

switch(
  mode <- "",
  #| title: Summary Mode
  #| description: Summarise captured metrics.
  summary = {
    #| description: Override the primary target when summarising.
    summary_target <- "summary-default"

    #| description: Additional filters that append.
    summary_filter <- c()
  },
  #| title: Detail Mode
  detail = {
    #| description: Required detail identifier.
    detail_id <- NULL

    #| description: Optional detail payload.
    #| required: false
    detail_payload <- NULL
  },
  #| title: Config Mode
  #| description: Update configuration inputs.
  config = {
    #| description: Optional config file path.
    #| required: false
    config_path <- NULL
  },
  help = {}
)
