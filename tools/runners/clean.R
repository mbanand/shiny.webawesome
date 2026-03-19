#!/usr/bin/env Rscript

# nolint start: object_usage_linter.
# Source the shared CLI helpers from whichever path is available.
.bootstrap_cli_ui <- function() {
  ofiles <- vapply(
    sys.frames(),
    function(frame) if (is.null(frame$ofile)) "" else frame$ofile,
    character(1)
  )
  current_file <- tail(ofiles[nzchar(ofiles)], 1)
  current_dir <- if (length(current_file) == 0L) "." else dirname(current_file)

  candidates <- c(
    file.path("tools", "cli_ui.R"),
    file.path(current_dir, "cli_ui.R"),
    file.path(current_dir, "..", "cli_ui.R"),
    "cli_ui.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    source(existing[[1]])
  }
}

.bootstrap_cli_ui()
rm(.bootstrap_cli_ui)

# Return the CLI usage string for the clean runner.
.clean_usage <- function() {
  paste(
    "Usage: Rscript tools/runners/clean.R",
    "[--level clean|distclean] [--dry-run] [--quiet] [--help]"
  )
}

# Return the short CLI description for the clean runner.
.clean_description <- function() {
  "Remove generated build artifacts from the shiny.webawesome repository."
}

# List supported CLI options for the clean runner.
.clean_option_lines <- function() {
  c(
    "--level, -l <clean|distclean>  Cleanup level to run.",
    "--dry-run                      Report actions without deleting files.",
    "--quiet                        Suppress stage-level progress messages.",
    "--help, -h                     Print this help text."
  )
}

# Print the CLI help text for the clean runner.
.print_clean_help <- function() {
  writeLines(
    c(
      .clean_description(),
      "",
      .clean_usage(),
      "",
      "Options:",
      .clean_option_lines()
    )
  )
}

# Define default CLI option values for the clean runner.
.clean_runner_defaults <- function() {
  list(
    level = "clean",
    dry_run = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the clean runner.
.parse_clean_args <- function(args) {
  options <- .clean_runner_defaults()
  skip_next <- FALSE

  for (i in seq_along(args)) {
    if (skip_next) {
      skip_next <- FALSE
      next
    }

    arg <- args[[i]]

    if (arg == "--dry-run") {
      options$dry_run <- TRUE
      next
    }

    if (arg %in% c("--help", "-h")) {
      options$help <- TRUE
      next
    }

    if (arg == "--quiet") {
      options$verbose <- FALSE
      next
    }

    if (arg %in% c("--level", "-l")) {
      if (i == length(args)) {
        stop("Missing value for --level.", call. = FALSE)
      }

      options$level <- args[[i + 1L]]
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--level=")) {
      options$level <- sub("^--level=", "", arg)
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .clean_usage()),
      call. = FALSE
    )
  }

  options
}

# Emit a short summary for the clean runner result.
.emit_clean_runner_summary <- function(result) {
  summary_prefix <- if (result$dry_run) "Dry run complete" else "Clean complete"
  message(
    summary_prefix,
    ": level=", result$level,
    ", removed=", length(result$removed),
    ", missing=", length(result$missing)
  )
}

#' Run the clean stage from the command line
#'
#' Parses CLI arguments, executes `clean_webawesome()`, and prints a short
#' status summary for the requested cleanup level.
#'
#' Supported options are:
#' - `--level` / `-l` for `clean` or `distclean`
#' - `--dry-run` to report actions without deleting files
#' - `--quiet` to suppress stage-level progress messages
#' - `--help` / `-h` to print CLI help
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the result from `clean_webawesome()`. If `--help`
#'   or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_clean()
#' run_clean(c("--level", "distclean", "--dry-run"))
#' run_clean("--help")
#' }
run_clean <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_clean_args(args)

  if (isTRUE(options$help)) {
    .print_clean_help()
    return(invisible(NULL))
  }

  source(file.path("tools", "clean_webawesome.R"))
  ui <- .cli_ui_new()

  .cli_step_start(ui, "Cleaning repository")

  result <- tryCatch(
    {
      clean_webawesome(
        level = options$level,
        dry_run = options$dry_run,
        verbose = FALSE,
        root = "."
      )
    },
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  if (isTRUE(options$verbose) && !isTRUE(ui$fancy)) {
    .emit_clean_summary(result)
  }

  .cli_step_finish(
    ui,
    status = if (isTRUE(result$dry_run)) "Done" else "Done"
  )
  .emit_clean_runner_summary(result)

  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_clean)
}
# nolint end
