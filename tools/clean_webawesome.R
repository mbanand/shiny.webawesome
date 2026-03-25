#!/usr/bin/env Rscript

# Clean stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It is not package runtime code.

# nolint start: object_usage_linter.
# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  command_file <- if (length(file_arg) > 0L) {
    sub("^--file=", "", tail(file_arg, 1))
  } else {
    ""
  }

  ofiles <- vapply(
    sys.frames(),
    function(frame) if (is.null(frame$ofile)) "" else frame$ofile,
    character(1)
  )
  source_file <- tail(ofiles[nzchar(ofiles)], 1)
  known_files <- c(command_file, source_file)
  known_files <- known_files[nzchar(known_files)]
  current_dir <- if (length(known_files) == 0L) {
    "."
  } else {
    dirname(normalizePath(known_files[[1]], winslash = "/", mustWork = FALSE))
  }

  candidates <- c(
    file.path(current_dir, "cli_ui.R"),
    file.path(current_dir, "tools", "cli_ui.R"),
    file.path(current_dir, "..", "cli_ui.R"),
    file.path("tools", "cli_ui.R"),
    "cli_ui.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    source(existing[[1]])
  }
}

.bootstrap_cli_ui()
rm(.bootstrap_cli_ui)

# Return the CLI usage string for the clean stage.
.clean_usage <- function() {
  paste(
    "Usage: ./tools/clean_webawesome.R",
    "[--level clean|distclean] [--dry-run] [--root <path>]",
    "[--quiet] [--help]"
  )
}

# Return the short CLI description for the clean stage.
.clean_description <- function() {
  "Remove generated build artifacts from the shiny.webawesome repository."
}

# List supported CLI options for the clean stage.
.clean_option_lines <- function() {
  c(
    "--level, -l <clean|distclean>  Cleanup level to run.",
    "--dry-run                      Report actions without deleting files.",
    paste(
      "--root <path>                  Repository root.",
      "Defaults to the current directory."
    ),
    "--quiet                        Suppress stage-level progress messages.",
    "--help, -h                     Print this help text."
  )
}

# Print the CLI help text for the clean stage.
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

# Define default CLI option values for the clean stage.
.clean_defaults <- function() {
  list(
    level = "clean",
    dry_run = FALSE,
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the clean stage.
.parse_clean_args <- function(args) {
  options <- .clean_defaults()
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

    if (arg == "--root") {
      if (i == length(args)) {
        stop("Missing value for --root.", call. = FALSE)
      }

      options$root <- args[[i + 1L]]
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--root=")) {
      options$root <- sub("^--root=", "", arg)
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .clean_usage()),
      call. = FALSE
    )
  }

  options
}

# Define the path sets removed by each clean level.
.clean_target_sets <- function() {
  list(
    clean = list(
      remove = c(
        "R/generated",
        "R/generated_updates",
        "inst/bindings",
        "inst/extdata/webawesome",
        "inst/www/wa",
        "manifests",
        "report"
      )
    ),
    distclean = list(
      remove = c(
        "R/generated",
        "R/generated_updates",
        "inst/bindings",
        "inst/extdata/webawesome",
        "inst/www/wa",
        "manifests",
        "report",
        "vendor/webawesome"
      )
    )
  )
}

# Discover top-level generated R files owned by generate_components().
.generated_r_files <- function(root) {
  r_dir <- file.path(root, "R")
  if (!dir.exists(r_dir)) {
    return(character())
  }

  paths <- list.files(r_dir, pattern = "\\.[Rr]$", full.names = TRUE)
  if (length(paths) == 0L) {
    return(character())
  }

  owned <- vapply(
    paths,
    function(path) {
      lines <- readLines(path, n = 1L, warn = FALSE)
      length(lines) > 0L &&
        identical(
          lines[[1]],
          "# Generated by tools/generate_components.R. Do not edit by hand."
        )
    },
    logical(1)
  )

  sort(paths[owned])
}

# Check whether a path looks like the repository root.
.is_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "docs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

# Remove one path unless running in dry-run mode.
.remove_path <- function(path, dry_run = FALSE) {
  if (!dry_run) {
    unlink(path, recursive = TRUE, force = TRUE)
  }

  path
}

# Remove the repository root prefix from one or more absolute paths.
.strip_root_prefix <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

# Emit a short summary for a clean operation result.
.emit_clean_summary <- function(result) {
  action <- if (result$dry_run) "Would remove" else "Removed"

  if (length(result$removed) > 0L) {
    message(action, ": ", paste(result$removed, collapse = ", "))
  }

  if (length(result$missing) > 0L) {
    message("Already absent: ", paste(result$missing, collapse = ", "))
  }
}

# Emit a short CLI summary for a clean operation result.
.emit_clean_cli_summary <- function(result) {
  summary_prefix <- if (result$dry_run) "Dry run complete" else "Clean complete"
  message(
    summary_prefix,
    ": level=", result$level,
    ", removed=", length(result$removed),
    ", missing=", length(result$missing)
  )
}

#' Remove generated build artifacts from the repository
#'
#' Executes the `clean` stage of the build pipeline. The default `clean` level
#' removes generated package artifacts, copied generation metadata, and the
#' pruned runtime bundle.
#' `distclean` additionally removes fetched upstream inputs and copied metadata.
#'
#' @param level Cleanup level. Must be one of `"clean"` or `"distclean"`.
#' @param dry_run Logical scalar. If `TRUE`, reports the paths that would be
#'   removed without deleting them.
#' @param verbose Logical scalar. If `TRUE`, emits a short summary of removed
#'   and already-absent paths.
#' @param root Repository root directory.
#'
#' @return A list describing the cleanup operation, including removed and
#'   missing paths.
#'
#' @examples
#' \dontrun{
#' clean_webawesome()
#' clean_webawesome(level = "distclean", dry_run = TRUE)
#' }
clean_webawesome <- function(level = c("clean", "distclean"),
                             dry_run = FALSE,
                             verbose = interactive(),
                             root = ".") {
  level <- match.arg(level)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  target_set <- .clean_target_sets()[[level]]

  remove_targets <- file.path(root, target_set$remove)
  generated_r_targets <- .generated_r_files(root)
  remove_targets <- unique(c(remove_targets, generated_r_targets))
  existing_remove <- remove_targets[file.exists(remove_targets)]
  missing <- remove_targets[!file.exists(remove_targets)]

  removed_paths <- character()
  if (length(existing_remove) > 0L) {
    for (path in sort(existing_remove)) {
      removed_paths <- c(
        removed_paths,
        .remove_path(path, dry_run = dry_run)
      )
    }
  }

  result <- list(
    level = level,
    root = root,
    requested_remove = sort(target_set$remove),
    existing_remove = sort(.strip_root_prefix(existing_remove, root)),
    removed = sort(.strip_root_prefix(removed_paths, root)),
    missing = sort(.strip_root_prefix(missing, root)),
    dry_run = dry_run
  )

  if (isTRUE(verbose)) {
    .emit_clean_summary(result)
  }

  result
}

#' Run the clean stage from the command line
#'
#' Parses CLI arguments, executes [clean_webawesome()], and prints a short
#' status summary for the requested cleanup level.
#'
#' Supported options are:
#' - `--level` / `-l` for `clean` or `distclean`
#' - `--dry-run` to report actions without deleting files
#' - `--root` to point at a repository root other than the current directory
#' - `--quiet` to suppress stage-level progress messages
#' - `--help` / `-h` to print CLI help
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the result from [clean_webawesome()]. If `--help`
#'   or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_clean_webawesome()
#' run_clean_webawesome(c("--level", "distclean", "--dry-run"))
#' run_clean_webawesome(c("--root", "/path/to/repo"))
#' run_clean_webawesome("--help")
#' }
run_clean_webawesome <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_clean_args(args)

  if (isTRUE(options$help)) {
    .print_clean_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  .cli_step_start(ui, "Cleaning repository")

  result <- tryCatch(
    {
      clean_webawesome(
        level = options$level,
        dry_run = options$dry_run,
        verbose = FALSE,
        root = options$root
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

  .cli_step_finish(ui, status = "Done")
  .emit_clean_cli_summary(result)

  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_clean_webawesome)
}
# nolint end
