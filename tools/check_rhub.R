#!/usr/bin/env Rscript

# External R-hub check helper for the shiny.webawesome release workflow.
#
# This file is sourceable by tests and directly executable as a top-level tool.

# nolint start: object_usage_linter.
# Return base directories inferred from the current script-loading context.
.script_base_dirs <- function() {
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
  known_files <- known_files[nzchar(known_files) & known_files != "-"]

  unique(c(
    vapply(
      known_files,
      function(path) {
        dirname(normalizePath(path, winslash = "/", mustWork = FALSE))
      },
      character(1)
    ),
    "."
  ))
}

.rhub_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .rhub_tool_base_dirs
  candidates <- c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "cli_ui.R"))),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "tools", "cli_ui.R"))
    ),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "..", "cli_ui.R"))),
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

# Return the CLI usage string for the rhub helper tool.
.rhub_usage <- function() {
  paste(
    "Usage: ./tools/check_rhub.R",
    "[--root <path>] [--allow-main] [--skip-doctor] [--help]"
  )
}

# Return the short CLI description for the rhub helper tool.
.rhub_desc <- function() {
  paste(
    "Run the external R-hub pre-release check workflow from the current",
    "git branch."
  )
}

# List supported CLI options for the rhub helper tool.
.rhub_opts <- function() {
  c(
    paste(
      "--root <path>   Repository root.",
      "Defaults to the current directory."
    ),
    paste(
      "--allow-main    Permit running from `main`.",
      "Use sparingly."
    ),
    "--skip-doctor    Skip `rhub::rhub_doctor()` before the check.",
    "--help, -h       Print this help text."
  )
}

# Print the CLI help text for the rhub helper tool.
.print_rhub_help <- function() {
  writeLines(
    c(
      .rhub_desc(),
      "",
      .rhub_usage(),
      "",
      "Options:",
      .rhub_opts()
    )
  )
}

# Define default CLI option values for the rhub helper tool.
.rhub_defaults <- function() {
  list(
    root = ".",
    allow_main = FALSE,
    run_doctor = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the rhub helper tool.
.parse_rhub_args <- function(args) {
  options <- .rhub_defaults()
  skip_next <- FALSE

  for (i in seq_along(args)) {
    if (skip_next) {
      skip_next <- FALSE
      next
    }

    arg <- args[[i]]

    if (arg %in% c("--help", "-h")) {
      options$help <- TRUE
      next
    }

    if (arg == "--allow-main") {
      options$allow_main <- TRUE
      next
    }

    if (arg == "--skip-doctor") {
      options$run_doctor <- FALSE
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
      paste0("Unknown argument: ", arg, "\n", .rhub_usage()),
      call. = FALSE
    )
  }

  options
}

# Check whether a path looks like the repository root.
.is_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "projectdocs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

# Run one child command using processx.
.run_process <- function(command,
                         args = character(),
                         wd = ".",
                         env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to run rhub commands.",
      call. = FALSE
    )
  }

  child_env <- if (length(env) == 0L) {
    NULL
  } else {
    current <- Sys.getenv(names = TRUE, unset = NA_character_)
    current[names(env)] <- unname(env)
    current
  }

  processx::run(
    command = command,
    args = args,
    wd = wd,
    echo = FALSE,
    error_on_status = FALSE,
    env = child_env
  )
}

# Split child command output into deterministic non-empty lines.
.process_lines <- function(result) {
  combined <- c(result$stdout, result$stderr)
  lines <- unlist(
    strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE)
  )
  unique(lines[nzchar(lines)])
}

# Run one git command in the repository root.
.git_run <- function(root, args, runner = .run_process) {
  runner(command = "git", args = args, wd = root)
}

# Return the current local git branch name.
.git_branch <- function(root, runner = .run_process) {
  result <- .git_run(
    root = root,
    args = c("rev-parse", "--abbrev-ref", "HEAD"),
    runner = runner
  )

  if (!identical(result$status, 0L)) {
    stop(
      paste(
        "Could not determine the current git branch.",
        paste(.process_lines(result), collapse = "\n")
      ),
      call. = FALSE
    )
  }

  trimws(result$stdout)
}

# Return whether the git worktree has uncommitted changes.
.git_dirty <- function(root, runner = .run_process) {
  result <- .git_run(
    root = root,
    args = c("status", "--porcelain"),
    runner = runner
  )

  if (!identical(result$status, 0L)) {
    stop(
      paste(
        "Could not inspect git status.",
        paste(.process_lines(result), collapse = "\n")
      ),
      call. = FALSE
    )
  }

  nzchar(trimws(result$stdout))
}

# Return the upstream branch configured for the current branch, if any.
.git_upstream <- function(root, runner = .run_process) {
  result <- .git_run(
    root = root,
    args = c("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"),
    runner = runner
  )

  if (identical(result$status, 0L)) {
    return(trimws(result$stdout))
  }

  NULL
}

# Return the expected R-hub workflow path.
.rhub_workflow <- function(root) {
  file.path(root, ".github", "workflows", "rhub.yaml")
}

# Strip the normalized repository root prefix from one path.
.strip_root <- function(path, root) {
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  normalized_path <- normalizePath(path, winslash = "/", mustWork = FALSE)

  if (startsWith(normalized_path, paste0(normalized_root, "/"))) {
    substr(normalized_path, nchar(normalized_root) + 2L, nchar(normalized_path))
  } else if (identical(normalized_path, normalized_root)) {
    "."
  } else {
    normalized_path
  }
}

# Return the default rhub doctor function.
.default_rhub_doctor <- function() {
  rhub::rhub_doctor()
}

# Return the default rhub check function.
.default_rhub_check <- function(branch) {
  rhub::rhub_check(
    gh_url = NULL,
    platforms = NULL,
    branch = branch
  )
}

# Run the external rhub check workflow from the current git branch.
#'
#' Verifies that the repository is on a clean, pushed git branch, optionally
#' runs `rhub::rhub_doctor()`, and then launches `rhub::rhub_check()` for the
#' current branch using rhub's interactive platform selection.
#'
#' This helper intentionally does not create, push, or delete branches. Run it
#' from the branch that should own the external release check.
#'
#' CLI entry point:
#' `./tools/check_rhub.R --help`
#'
#' @param root Repository root directory.
#' @param allow_main Logical scalar. If `FALSE`, refuse to run from `main`.
#' @param run_doctor Logical scalar. If `TRUE`, call `rhub::rhub_doctor()`
#'   before `rhub::rhub_check()`.
#' @param verbose Logical scalar. If `TRUE`, emit progress messages.
#' @param git_runner Function used to execute git child commands. This is
#'   primarily a test seam.
#' @param doctor_fun Function used to run `rhub::rhub_doctor()`. This is
#'   primarily a test seam.
#' @param check_fun Function used to run `rhub::rhub_check()`. This is
#'   primarily a test seam.
#'
#' @return A list describing the branch and upstream used for the rhub run.
#'
#' @examples
#' \dontrun{
#' check_rhub()
#' check_rhub(allow_main = TRUE)
#' check_rhub(run_doctor = FALSE)
#' }
check_rhub <- function(root = ".",
                       allow_main = FALSE,
                       run_doctor = TRUE,
                       verbose = interactive(),
                       git_runner = .run_process,
                       doctor_fun = NULL,
                       check_fun = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  if (is.null(doctor_fun)) {
    if (!requireNamespace("rhub", quietly = TRUE)) {
      stop(
        "The `rhub` package is required to run external rhub checks.",
        call. = FALSE
      )
    }

    doctor_fun <- .default_rhub_doctor
  }

  if (is.null(check_fun)) {
    if (!requireNamespace("rhub", quietly = TRUE)) {
      stop(
        "The `rhub` package is required to run external rhub checks.",
        call. = FALSE
      )
    }

    check_fun <- .default_rhub_check
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(verbose)

  .cli_step_start(ui, "Inspecting git branch")
  branch <- .git_branch(root, runner = git_runner)
  upstream <- .git_upstream(root, runner = git_runner)
  dirty <- .git_dirty(root, runner = git_runner)

  if (identical(branch, "main") && !isTRUE(allow_main)) {
    .cli_step_fail(
      ui,
      details = paste(
        "Refusing to run rhub from `main` without `--allow-main`.",
        "Use a release-candidate branch instead when possible."
      )
    )
    .cli_abort_handled("Main-branch rhub runs require explicit override.")
  }

  if (isTRUE(dirty)) {
    .cli_step_fail(
      ui,
      details = paste(
        "The git worktree has uncommitted changes.",
        "Commit or stash them before running `check_rhub`."
      )
    )
    .cli_abort_handled("Rhub checks require a clean git worktree.")
  }

  if (is.null(upstream) || !nzchar(upstream)) {
    .cli_step_fail(
      ui,
      details = paste(
        "The current branch does not have an upstream tracking branch.",
        "Push the branch to GitHub before running `check_rhub`."
      )
    )
    .cli_abort_handled("Rhub checks require a pushed branch.")
  }

  workflow <- .rhub_workflow(root)
  if (!file.exists(workflow)) {
    .cli_step_fail(
      ui,
      details = paste(
        "Missing `.github/workflows/rhub.yaml`.",
        "Run `rhub::rhub_setup()` on the default branch, commit the workflow,",
        "and push it before using `check_rhub`."
      )
    )
    .cli_abort_handled("Rhub workflow file is not present in the repository.")
  }

  .cli_step_finish(
    ui,
    status = "Pass",
    comment = paste0(branch, " -> ", upstream)
  )

  if (isTRUE(run_doctor)) {
    .cli_step_start(ui, "Running rhub doctor")
    tryCatch(
      {
        doctor_fun()
      },
      error = function(condition) {
        .cli_step_fail(ui, details = conditionMessage(condition))
        .cli_abort_handled("`rhub::rhub_doctor()` failed.")
      }
    )
    .cli_step_finish(ui, status = "Done")
  }

  .cli_step_start(ui, "Starting rhub check")
  tryCatch(
    {
      check_fun(branch)
    },
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled("`rhub::rhub_check()` failed.")
    }
  )
  .cli_step_finish(ui, status = "Done", comment = branch)

  if (isTRUE(verbose)) {
    message(
      "R-hub check submitted for branch `",
      branch,
      "`. Watch the repository's GitHub Actions page for live logs."
    )
  }

  invisible(
    list(
      root = root,
      branch = branch,
      upstream = upstream,
      workflow = .strip_root(workflow, root),
      ran_doctor = isTRUE(run_doctor)
    )
  )
}

# Run the rhub helper from the command line.
run_check_rhub <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_rhub_args(args)

  if (isTRUE(options$help)) {
    .print_rhub_help()
    return(invisible(NULL))
  }

  .cli_run_main(function() {
    invisible(
      check_rhub(
        root = options$root,
        allow_main = options$allow_main,
        run_doctor = options$run_doctor
      )
    )
  })
}

if (sys.nframe() == 0L) {
  run_check_rhub()
}
# nolint end
