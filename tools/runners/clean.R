#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

level <- "clean"
dry_run <- FALSE
verbose <- TRUE

parse_arg <- function(i) {
  arg <- args[[i]]

  if (arg == "--dry-run") {
    dry_run <<- TRUE
    return(invisible(NULL))
  }

  if (arg == "--quiet") {
    verbose <<- FALSE
    return(invisible(NULL))
  }

  if (arg %in% c("--level", "-l")) {
    if (i == length(args)) {
      stop("Missing value for --level.", call. = FALSE)
    }

    level <<- args[[i + 1L]]
    return(invisible("skip-next"))
  }

  if (startsWith(arg, "--level=")) {
    level <<- sub("^--level=", "", arg)
    return(invisible(NULL))
  }

  stop(
    paste0(
      "Unknown argument: ", arg, "\n",
      "Usage: Rscript tools/runners/clean.R ",
      "[--level clean|distclean] [--dry-run] [--quiet]"
    ),
    call. = FALSE
  )
}

skip_next <- FALSE
for (i in seq_along(args)) {
  if (skip_next) {
    skip_next <- FALSE
    next
  }

  parsed <- parse_arg(i)
  if (identical(parsed, "skip-next")) {
    skip_next <- TRUE
  }
}

source(file.path("tools", "clean_webawesome.R"))

result <- clean_webawesome(
  level = level,
  dry_run = dry_run,
  verbose = verbose,
  root = "."
)

summary_prefix <- if (dry_run) "Dry run complete" else "Clean complete"
message(
  summary_prefix,
  ": level=", result$level,
  ", removed=", length(result$removed),
  ", missing=", length(result$missing)
)
