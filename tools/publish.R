#!/usr/bin/env Rscript

# Publish-stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It verifies finalize handoff state and, when explicitly
# requested, performs selected external release actions.

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

.publish_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .publish_tool_base_dirs
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

# Source the shared integrity helpers relative to this script when possible.
.bootstrap_integrity_helpers <- function() {
  base_dirs <- .publish_tool_base_dirs
  candidates <- c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "integrity.R"))),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "tools", "integrity.R"))
    ),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "..", "integrity.R"))
    ),
    file.path("tools", "integrity.R"),
    "integrity.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    source(existing[[1]])
  }
}

.bootstrap_cli_ui()
.bootstrap_integrity_helpers()
rm(.bootstrap_cli_ui, .bootstrap_integrity_helpers)

# Return the CLI usage string for the publish stage.
.publish_usage <- function() {
  paste(
    "Usage: ./tools/publish.R",
    paste(
      "[--root <path>] --release-version <version>",
      "[--dry-run] [--do-tag] [--deploy-site] [--quiet] [--help]"
    )
  )
}

# Return the short CLI description for the publish stage.
.publish_description <- function() {
  paste(
    "Verify the finalize handoff and run selected release actions such as",
    "tagging and site deployment."
  )
}

# List supported CLI options for the publish stage.
.publish_option_lines <- function() {
  c(
    paste(
      "--root <path>                 Repository root.",
      "Defaults to the current directory."
    ),
    "--release-version <version>   Release version to verify and publish.",
    "--dry-run                     Verify readiness without external actions.",
    "--do-tag                      Create and push the release tag and branch.",
    "--deploy-site                 Deploy the finalize-built website artifact.",
    "--quiet                       Suppress stage-level progress messages.",
    "--help, -h                    Print this help text."
  )
}

# Print the CLI help text for the publish stage.
.print_publish_help <- function() {
  writeLines(
    c(
      .publish_description(),
      "",
      .publish_usage(),
      "",
      "Options:",
      .publish_option_lines()
    )
  )
}

# Define default CLI option values for the publish stage.
.publish_defaults <- function() {
  list(
    root = ".",
    release_version = NULL,
    dry_run = FALSE,
    do_tag = FALSE,
    deploy_site = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the publish stage.
.parse_publish_args <- function(args) {
  options <- .publish_defaults()
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

    if (arg == "--do-tag") {
      options$do_tag <- TRUE
      next
    }

    if (arg == "--deploy-site") {
      options$deploy_site <- TRUE
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

    if (arg %in% c("--root", "--release-version")) {
      if (i == length(args)) {
        stop(sprintf("Missing value for %s.", arg), call. = FALSE)
      }

      value <- args[[i + 1L]]
      if (identical(arg, "--root")) {
        options$root <- value
      } else {
        options$release_version <- value
      }

      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--root=")) {
      options$root <- sub("^--root=", "", arg)
      next
    }

    if (startsWith(arg, "--release-version=")) {
      options$release_version <- sub("^--release-version=", "", arg)
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .publish_usage()),
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

# Return the finalize manifest directory.
.finalize_manifest_dir <- function(root) {
  file.path(root, "manifests", "finalize")
}

# Return the machine-readable finalize handoff path.
.finalize_handoff_path <- function(root) {
  file.path(.finalize_manifest_dir(root), "release-handoff.yaml")
}

# Return the publish manifest directory.
.publish_manifest_dir <- function(root) {
  file.path(root, "manifests", "publish")
}

# Return the publish report directory.
.publish_report_dir <- function(root) {
  file.path(root, "reports", "publish")
}

# Return the machine-readable publish record path.
.publish_record_path <- function(root) {
  file.path(.publish_manifest_dir(root), "release-publish.yaml")
}

# Return the human-readable publish summary path.
.publish_summary_path <- function(root) {
  file.path(.publish_report_dir(root), "summary.md")
}

# Resolve one repository-local artifact path against the root when needed.
.resolve_repo_path <- function(root, path) {
  if (is.null(path) || !nzchar(path)) {
    return(NULL)
  }

  if (grepl("^(/|[A-Za-z]:[/\\\\])", path)) {
    return(path)
  }

  file.path(root, path)
}

# Remove stale publish outputs before a new run.
.remove_publish_outputs <- function(root) {
  paths <- c(.publish_record_path(root), .publish_summary_path(root))
  removed <- character()

  for (path in paths[file.exists(paths)]) {
    unlink(path, recursive = TRUE, force = TRUE)
    removed <- c(removed, .strip_root_prefix(path, root))
  }

  removed
}

# Run one child command using processx.
.run_process <- function(command,
                         args = character(),
                         wd = ".",
                         env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to run publish commands.",
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

# Collapse child command output into a deterministic character vector.
.process_output_lines <- function(result) {
  combined <- c(result$stdout, result$stderr)
  lines <- unlist(
    strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE)
  )
  unique(lines[nzchar(lines)])
}

# Return the package version from DESCRIPTION.
.package_version <- function(root) {
  read.dcf(file.path(root, "DESCRIPTION"))[[1, "Version"]]
}

# Return trimmed file lines when one file exists, otherwise an empty vector.
.read_trimmed_lines <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }

  trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

# Return the latest NEWS heading version when present.
.news_version <- function(root) {
  path <- file.path(root, "NEWS.md")
  lines <- .read_trimmed_lines(path)

  if (length(lines) == 0L) {
    return(NA_character_)
  }

  patterns <- c(
    "^#\\s+Version\\s+([0-9][0-9A-Za-z.\\-]*)\\s*$",
    "^#\\s+[A-Za-z][A-Za-z0-9._\\-]*\\s+([0-9][0-9A-Za-z.\\-]*)\\s*$"
  )

  for (pattern in patterns) {
    headings <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
    versions <- vapply(
      headings,
      function(match) {
        if (length(match) >= 2L) {
          match[[2]]
        } else {
          NA_character_
        }
      },
      character(1)
    )
    versions <- versions[!is.na(versions) & nzchar(versions)]

    if (length(versions) > 0L) {
      return(versions[[1]])
    }
  }

  NA_character_
}

# Read the finalize handoff record from disk.
.read_finalize_handoff <- function(root) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to read finalize handoff records.",
      call. = FALSE
    )
  }

  path <- .finalize_handoff_path(root)
  if (!file.exists(path)) {
    stop("Finalize handoff record does not exist.", call. = FALSE)
  }

  yaml::read_yaml(path)
}

# Return the current git HEAD commit.
.git_head_commit <- function(root, runner = .run_process) {
  result <- runner("git", c("rev-parse", "HEAD"), wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  trimws(paste(result$stdout, collapse = "\n"))
}

# Return the current git branch name.
.git_current_branch <- function(root, runner = .run_process) {
  result <- runner("git", c("rev-parse", "--abbrev-ref", "HEAD"), wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  trimws(paste(result$stdout, collapse = "\n"))
}

# Return whether the git working tree is clean.
.git_is_clean <- function(root, runner = .run_process) {
  result <- runner("git", c("status", "--porcelain"), wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  !nzchar(trimws(paste(result$stdout, collapse = "\n")))
}

# Return one deterministic record for the current website tree.
.website_tree_record <- function(root) {
  relative_files <- .integrity_list_relative_files(root, "website")
  .build_integrity_record(
    root = root,
    stage = "publish",
    surface_name = "website",
    surface_roots = "website",
    relative_files = relative_files
  )
}

# Return one deterministic record for the current tracked git tree.
.tracked_tree_record <- function(root, runner = .run_process) {
  result <- runner("git", "ls-files", wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  output <- paste(c(result$stdout, result$stderr), collapse = "\n")
  relative_files <- strsplit(output, "\n", fixed = TRUE)[[1]]
  relative_files <- sort(relative_files[nzchar(relative_files)])

  .build_integrity_record(
    root = root,
    stage = "publish",
    surface_name = "tracked_git_tree",
    surface_roots = ".",
    relative_files = relative_files
  )
}

# Return whether one local git tag already exists.
.git_local_tag_exists <- function(root, tag, runner = .run_process) {
  result <- runner("git", c("tag", "--list", tag), wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  any(trimws(unlist(strsplit(
    paste(result$stdout, collapse = "\n"),
    "\n",
    fixed = TRUE
  ))) == tag)
}

# Return whether one remote git tag already exists on origin.
.git_remote_tag_exists <- function(root, tag, runner = .run_process) {
  result <- runner(
    "git",
    c("ls-remote", "--tags", "--refs", "origin", paste0("refs/tags/", tag)),
    wd = root
  )

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  nzchar(trimws(paste(result$stdout, collapse = "\n")))
}

# Create one release git tag.
.git_create_tag <- function(root, tag, runner = .run_process) {
  result <- runner("git", c("tag", tag), wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  invisible(tag)
}

# Push one branch to origin.
.git_push_branch <- function(root, branch, runner = .run_process) {
  result <- runner("git", c("push", "origin", branch), wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  invisible(branch)
}

# Push one git tag to origin.
.git_push_tag <- function(root, tag, runner = .run_process) {
  result <- runner(
    "git",
    c("push", "origin", paste0("refs/tags/", tag)),
    wd = root
  )

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  invisible(tag)
}

# Deploy the finalize-built website using a dedicated wrapper when available.
.deploy_publish_site <- function(root,
                                 dry_run = FALSE,
                                 runner = .run_process) {
  wrapper <- file.path(root, "tools", "deploy_site_netlify.R")

  if (!file.exists(wrapper)) {
    stop(
      paste(
        "Website deployment wrapper `tools/deploy_site_netlify.R` is not",
        "implemented yet."
      ),
      call. = FALSE
    )
  }

  args <- c("--root", root)
  if (isTRUE(dry_run)) {
    args <- c(args, "--dry-run")
  }

  result <- runner(wrapper, args, wd = root)

  if (!identical(result$status, 0L)) {
    stop(paste(.process_output_lines(result), collapse = "\n"), call. = FALSE)
  }

  invisible(TRUE)
}

# Add one named warning message to the current warning set.
.add_publish_warning <- function(warnings, name, detail) {
  warnings[[name]] <- detail
  warnings
}

# Add one named check record to the current check set.
.add_publish_check <- function(checks, name, status, details = NULL) {
  checks[[name]] <- list(
    status = status,
    details = details
  )
  checks
}

# Return one overall publish status from checks and warnings.
.publish_status <- function(checks, warnings) {
  check_statuses <- vapply(
    checks,
    function(check) check$status %||% "pass",
    character(1)
  )

  if (length(check_statuses) > 0L && any(check_statuses == "fail")) {
    return("fail")
  }

  if (
    length(check_statuses) > 0L &&
      any(check_statuses == "warn") ||
      length(warnings) > 0L
  ) {
    return("warn")
  }

  "pass"
}

# Convert one named warning vector or list into a stable named list.
.warning_list <- function(warnings) {
  if (length(warnings) == 0L) {
    return(list())
  }

  as.list(warnings)
}

# Build the machine-readable publish record from the current run state.
.build_publish_record <- function(root,
                                  release_version,
                                  dry_run,
                                  do_tag,
                                  deploy_site,
                                  handoff,
                                  branch,
                                  git_head,
                                  checks,
                                  warnings,
                                  executed_actions,
                                  removed_outputs) {
  list(
    schema_version = 1L,
    record_type = "publish_record",
    generated_at = .integrity_timestamp(),
    status = .publish_status(checks, warnings),
    mode = if (isTRUE(dry_run)) "dry-run" else "publish",
    release_version = release_version,
    package_version = .package_version(root),
    branch = branch,
    git_head = git_head,
    handoff = list(
      path = .strip_root_prefix(.finalize_handoff_path(root), root),
      mode = handoff$mode %||% NULL,
      status = handoff$status %||% NULL
    ),
    requested_actions = list(
      dry_run = isTRUE(dry_run),
      do_tag = isTRUE(do_tag),
      deploy_site = isTRUE(deploy_site)
    ),
    executed_actions = list(
      do_tag = isTRUE(executed_actions$do_tag),
      deploy_site = isTRUE(executed_actions$deploy_site)
    ),
    removed_outputs = removed_outputs,
    checks = checks,
    warnings = .warning_list(warnings)
  )
}

# Write the machine-readable publish record.
.write_publish_record <- function(root, record) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to write publish records.",
      call. = FALSE
    )
  }

  path <- .publish_record_path(root)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  yaml_text <- yaml::as.yaml(
    record,
    indent.mapping.sequence = TRUE,
    line.sep = "\n"
  )
  text <- paste(
    c(
      "# Generated by tools/publish.R. Do not edit by hand.",
      yaml_text
    ),
    collapse = "\n"
  )
  writeLines(enc2utf8(text), path, useBytes = TRUE)

  .strip_root_prefix(path, root)
}

# Return human-readable summary lines for the current publish record.
.publish_summary_lines <- function(record) {
  warning_lines <- unname(unlist(record$warnings))
  check_lines <- vapply(
    names(record$checks),
    function(name) {
      check <- record$checks[[name]]
      details <- check$details %||% ""
      detail_suffix <- if (nzchar(details)) paste0(": ", details) else ""
      paste0("- `", name, "`: `", check$status, "`", detail_suffix)
    },
    character(1)
  )

  c(
    "# Publish Summary",
    "",
    "Generated by tools/publish.R. Do not edit by hand.",
    paste0("Generated at: ", record$generated_at),
    "",
    paste0("- Status: `", record$status, "`"),
    paste0("- Mode: `", record$mode, "`"),
    paste0("- Release version: `", record$release_version %||% "", "`"),
    paste0("- Package version: `", record$package_version %||% "", "`"),
    paste0("- Branch: `", record$branch %||% "", "`"),
    paste0("- Git HEAD: `", record$git_head %||% "", "`"),
    paste0(
      "- Finalize handoff: `",
      record$handoff$path %||% "Unavailable",
      "`"
    ),
    paste0(
      "- Finalize mode/status: `",
      paste(
        record$handoff$mode %||% "",
        record$handoff$status %||% "",
        sep = "/"
      ),
      "`"
    ),
    paste0(
      "- Requested actions: dry-run=",
      if (isTRUE(record$requested_actions$dry_run)) "yes" else "no",
      ", do-tag=",
      if (isTRUE(record$requested_actions$do_tag)) "yes" else "no",
      ", deploy-site=",
      if (isTRUE(record$requested_actions$deploy_site)) "yes" else "no"
    ),
    paste0(
      "- Executed actions: do-tag=",
      if (isTRUE(record$executed_actions$do_tag)) "yes" else "no",
      ", deploy-site=",
      if (isTRUE(record$executed_actions$deploy_site)) "yes" else "no"
    ),
    "",
    "## Checks",
    if (length(check_lines) > 0L) check_lines else "- None recorded.",
    "",
    "## Warnings",
    if (length(warning_lines) > 0L) {
      paste0("- ", warning_lines)
    } else {
      "- None."
    }
  )
}

# Write the human-readable publish summary.
.write_publish_summary <- function(root, record) {
  path <- .publish_summary_path(root)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(.publish_summary_lines(record)), path, useBytes = TRUE)
  .strip_root_prefix(path, root)
}

# Run one named publish step with CLI status output.
.run_publish_step <- function(ui, label, code) {
  .cli_step_start(ui, label)
  result <- tryCatch(
    force(code),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      stop(conditionMessage(condition), call. = FALSE)
    }
  )
  .cli_step_finish(ui, status = "Done")
  result
}

#' Run the publish-stage release workflow
#'
#' Verifies the recorded finalize handoff against the current repository state
#' and, when explicitly requested, performs selected release actions such as
#' creating and pushing the release tag or deploying the already-built website.
#'
#' CLI entry point:
#' `./tools/publish.R --help`
#'
#' @param release_version Required release version to verify and publish.
#' @param root Repository root directory.
#' @param dry_run Logical scalar. If `TRUE`, verifies readiness without
#'   executing external release actions.
#' @param do_tag Logical scalar. If `TRUE`, creates and pushes the release tag
#'   and current branch after verification passes.
#' @param deploy_site Logical scalar. If `TRUE`, deploys the finalize-built
#'   website after verification passes.
#' @param verbose Logical scalar. If `TRUE`, emits stage-level progress
#'   messages.
#' @param runner Function used to execute child commands. This is primarily a
#'   test seam for tool tests.
#' @param deployer Function used to deploy the built website. This is primarily
#'   a test seam for tool tests and future deployment-wrapper integration.
#'
#' @return A list describing the publish run, including the written record and
#'   summary paths, checks, warnings, and executed actions.
#'
#' @examples
#' \dontrun{
#' publish_package(release_version = "1.0.0", dry_run = TRUE)
#' publish_package(release_version = "1.0.0", do_tag = TRUE)
#' }
publish_package <- function(release_version,
                            root = ".",
                            dry_run = FALSE,
                            do_tag = FALSE,
                            deploy_site = FALSE,
                            verbose = interactive(),
                            runner = .run_process,
                            deployer = .deploy_publish_site) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  ui <- .cli_ui_new()
  if (!isTRUE(verbose)) {
    ui$quiet <- TRUE
  }

  state <- new.env(parent = emptyenv())
  state$checks <- list()
  state$warnings <- list()
  state$executed_actions <- list(do_tag = FALSE, deploy_site = FALSE)
  state$handoff <- list()
  state$branch <- NULL
  state$git_head <- NULL
  state$removed_outputs <- .remove_publish_outputs(root)
  state$error_message <- NULL
  state$record <- NULL

  on.exit(
    {
      if (!is.null(state$record)) {
        .write_publish_record(root, state$record)
        .write_publish_summary(root, state$record)
      }
    },
    add = TRUE
  )

  tryCatch(
    {
      .run_publish_step(ui, "Preparing publish outputs", {
        if (
          !isTRUE(dry_run) &&
            !isTRUE(do_tag) &&
            !isTRUE(deploy_site)
        ) {
          stop(
            paste(
              "Select at least one action:",
              "`--dry-run`, `--do-tag`, or `--deploy-site`."
            ),
            call. = FALSE
          )
        }

        if (missing(release_version) || is.null(release_version)) {
          stop("`release_version` is required.", call. = FALSE)
        }

        release_version <<- trimws(as.character(release_version))
        if (!nzchar(release_version)) {
          stop("`release_version` must not be empty.", call. = FALSE)
        }

        state$checks <- .add_publish_check(
          state$checks,
          "action_selection",
          "pass"
        )
      })

      .run_publish_step(ui, "Validating release metadata", {
        package_version <- .package_version(root)
        news_version <- .news_version(root)

        if (!identical(release_version, package_version)) {
          stop(
            paste(
              "Requested release version",
              paste0("(`", release_version, "`)"),
              "does not match DESCRIPTION version",
              paste0("(`", package_version, "`).")
            ),
            call. = FALSE
          )
        }

        if (is.na(news_version)) {
          stop(
            paste(
              "Could not determine the latest package version heading from",
              "`NEWS.md`."
            ),
            call. = FALSE
          )
        }

        if (!identical(release_version, news_version)) {
          stop(
            paste(
              "Requested release version",
              paste0("(`", release_version, "`)"),
              "does not match the latest `NEWS.md` heading version",
              paste0("(`", news_version, "`).")
            ),
            call. = FALSE
          )
        }

        state$checks <- .add_publish_check(
          state$checks,
          "release_version",
          "pass"
        )
      })

      .run_publish_step(ui, "Loading finalize handoff", {
        state$handoff <- .read_finalize_handoff(root)

        if (isTRUE(dry_run)) {
          if (!identical(state$handoff$mode %||% "", "strict")) {
            state$warnings <- .add_publish_warning(
              state$warnings,
              "handoff_mode",
              "Finalize handoff is not strict."
            )
            state$checks <- .add_publish_check(
              state$checks,
              "handoff_mode",
              "warn"
            )
          } else {
            state$checks <- .add_publish_check(
              state$checks,
              "handoff_mode",
              "pass"
            )
          }

          if (!identical(state$handoff$status %||% "", "pass")) {
            state$warnings <- .add_publish_warning(
              state$warnings,
              "handoff_status",
              paste0(
                "Finalize handoff status is `",
                state$handoff$status %||% "unknown",
                "`."
              )
            )
            state$checks <- .add_publish_check(
              state$checks,
              "handoff_status",
              "warn"
            )
          } else {
            state$checks <- .add_publish_check(
              state$checks,
              "handoff_status",
              "pass"
            )
          }
        } else {
          if (!identical(state$handoff$mode %||% "", "strict")) {
            stop(
              "Real publish actions require a strict finalize handoff.",
              call. = FALSE
            )
          }

          if (!identical(state$handoff$status %||% "", "pass")) {
            stop(
              "Real publish actions require a passing finalize handoff.",
              call. = FALSE
            )
          }

          state$checks <- .add_publish_check(
            state$checks,
            "handoff_mode",
            "pass"
          )
          state$checks <- .add_publish_check(
            state$checks,
            "handoff_status",
            "pass"
          )
        }

        handoff_warnings <- state$handoff$warnings %||% list()
        if (isTRUE(dry_run) && length(handoff_warnings) > 0L) {
          warning_lines <- vapply(
            names(handoff_warnings),
            function(name) {
              paste0(name, ": ", handoff_warnings[[name]])
            },
            character(1)
          )
          state$warnings <- .add_publish_warning(
            state$warnings,
            "handoff_warnings",
            paste(warning_lines, collapse = " | ")
          )
        }
      })

      .run_publish_step(ui, "Verifying repository state", {
        if (!.git_is_clean(root, runner = runner)) {
          stop("Git working tree is not clean.", call. = FALSE)
        }
        state$checks <- .add_publish_check(
          state$checks,
          "git_worktree",
          "pass"
        )

        state$git_head <- .git_head_commit(root, runner = runner)
        if (!identical(state$git_head, state$handoff$git_head %||% "")) {
          stop(
            "Current git HEAD does not match the finalize handoff.",
            call. = FALSE
          )
        }
        state$checks <- .add_publish_check(state$checks, "git_head", "pass")

        tracked_tree <- .tracked_tree_record(root, runner = runner)
        tracked_digest <- tracked_tree$summary$tree_digest %||% ""
        handoff_tracked_digest <-
          state$handoff$artifacts$tracked_tree$tree_digest %||% ""
        if (!identical(tracked_digest, handoff_tracked_digest)) {
          stop(
            "Tracked git tree digest does not match the finalize handoff.",
            call. = FALSE
          )
        }
        state$checks <- .add_publish_check(
          state$checks,
          "tracked_tree",
          "pass"
        )

        tarball_path <- .resolve_repo_path(
          root,
          state$handoff$artifacts$tarball$path %||% NULL
        )
        if (is.null(tarball_path) || !file.exists(tarball_path)) {
          stop("Recorded finalize tarball does not exist.", call. = FALSE)
        }
        tarball_digest <- .file_sha256(tarball_path)
        if (!identical(
          tarball_digest,
          state$handoff$artifacts$tarball$digest %||% ""
        )) {
          stop(
            "Tarball digest does not match the finalize handoff.",
            call. = FALSE
          )
        }
        state$checks <- .add_publish_check(state$checks, "tarball", "pass")

        website_path <- .resolve_repo_path(
          root,
          state$handoff$artifacts$website$path %||% NULL
        )
        if (is.null(website_path) || !dir.exists(website_path)) {
          stop(
            "Recorded finalize website artifact does not exist.",
            call. = FALSE
          )
        }
        website_record <- .website_tree_record(root)
        website_digest <- website_record$summary$tree_digest %||% ""
        if (!identical(
          website_digest,
          state$handoff$artifacts$website$tree_digest %||% ""
        )) {
          stop(
            "Website tree digest does not match the finalize handoff.",
            call. = FALSE
          )
        }
        state$checks <- .add_publish_check(state$checks, "website", "pass")
      })

      .run_publish_step(ui, "Checking branch and tag readiness", {
        state$branch <- .git_current_branch(root, runner = runner)

        if (!identical(state$branch, "main")) {
          if (isTRUE(dry_run)) {
            state$warnings <- .add_publish_warning(
              state$warnings,
              "branch",
              paste0("Current branch is `", state$branch, "`, not `main`.")
            )
            state$checks <- .add_publish_check(
              state$checks,
              "branch",
              "warn"
            )
          } else {
            stop(
              "Real publish actions require the current branch to be `main`.",
              call. = FALSE
            )
          }
        } else {
          state$checks <- .add_publish_check(state$checks, "branch", "pass")
        }

        local_tag_exists <- .git_local_tag_exists(
          root,
          release_version,
          runner = runner
        )
        remote_tag_exists <- .git_remote_tag_exists(
          root,
          release_version,
          runner = runner
        )

        if (isTRUE(local_tag_exists)) {
          if (isTRUE(do_tag)) {
            stop("Release tag already exists locally.", call. = FALSE)
          }

          state$warnings <- .add_publish_warning(
            state$warnings,
            "local_tag",
            "Release tag already exists locally."
          )
          state$checks <- .add_publish_check(
            state$checks,
            "local_tag",
            "warn"
          )
        } else {
          state$checks <- .add_publish_check(
            state$checks,
            "local_tag",
            "pass"
          )
        }

        if (isTRUE(remote_tag_exists)) {
          if (isTRUE(do_tag)) {
            stop(
              "Release tag already exists on remote `origin`.",
              call. = FALSE
            )
          }

          state$warnings <- .add_publish_warning(
            state$warnings,
            "remote_tag",
            "Release tag already exists on remote `origin`."
          )
          state$checks <- .add_publish_check(
            state$checks,
            "remote_tag",
            "warn"
          )
        } else {
          state$checks <- .add_publish_check(
            state$checks,
            "remote_tag",
            "pass"
          )
        }
      })

      .run_publish_step(ui, "Checking site deployment readiness", {
        if (!isTRUE(deploy_site)) {
          state$checks <- .add_publish_check(
            state$checks,
            "site_readiness",
            "pass"
          )
        } else {
          if (!dir.exists(file.path(root, "website"))) {
            stop("`website/` does not exist for deployment.", call. = FALSE)
          }

          if (isTRUE(dry_run)) {
            deployer(
              root = root,
              dry_run = TRUE,
              runner = runner
            )
            state$checks <- .add_publish_check(
              state$checks,
              "site_readiness",
              "pass"
            )
          } else {
            state$checks <- .add_publish_check(
              state$checks,
              "site_readiness",
              "pass"
            )
          }
        }
        invisible(NULL)
      })

      if (isTRUE(dry_run)) {
        state$record <- .build_publish_record(
          root = root,
          release_version = release_version,
          dry_run = dry_run,
          do_tag = do_tag,
          deploy_site = deploy_site,
          handoff = state$handoff,
          branch = state$branch,
          git_head = state$git_head,
          checks = state$checks,
          warnings = state$warnings,
          executed_actions = state$executed_actions,
          removed_outputs = state$removed_outputs
        )
        return(invisible(list(
          record = state$record,
          record_path = .publish_record_path(root),
          summary_path = .publish_summary_path(root),
          checks = state$checks,
          warnings = state$warnings,
          executed_actions = state$executed_actions
        )))
      }

      if (isTRUE(do_tag)) {
        .run_publish_step(ui, "Creating and pushing release tag", {
          .git_create_tag(root, release_version, runner = runner)
          .git_push_branch(root, state$branch, runner = runner)
          .git_push_tag(root, release_version, runner = runner)
          state$executed_actions$do_tag <- TRUE
          state$checks <- .add_publish_check(state$checks, "do_tag", "pass")
        })
      }

      if (isTRUE(deploy_site)) {
        .run_publish_step(ui, "Deploying website", {
          deployer(root = root, dry_run = FALSE, runner = runner)
          state$executed_actions$deploy_site <- TRUE
          state$checks <- .add_publish_check(
            state$checks,
            "deploy_site",
            "pass"
          )
        })
      }
    },
    error = function(condition) {
      state$error_message <- conditionMessage(condition)
    }
  )

  if (!is.null(state$error_message)) {
    state$checks <- .add_publish_check(
      state$checks,
      "publish",
      "fail",
      state$error_message
    )
  }

  state$record <- .build_publish_record(
    root = root,
    release_version = release_version,
    dry_run = dry_run,
    do_tag = do_tag,
    deploy_site = deploy_site,
    handoff = state$handoff,
    branch = state$branch,
    git_head = state$git_head,
    checks = state$checks,
    warnings = state$warnings,
    executed_actions = state$executed_actions,
    removed_outputs = state$removed_outputs
  )

  result <- list(
    record = state$record,
    record_path = .publish_record_path(root),
    summary_path = .publish_summary_path(root),
    checks = state$checks,
    warnings = state$warnings,
    executed_actions = state$executed_actions
  )

  if (!is.null(state$error_message)) {
    stop(state$error_message, call. = FALSE)
  }

  if (!isTRUE(ui$quiet)) {
    message(
      "Publish complete: mode=",
      state$record$mode,
      ", status=",
      state$record$status,
      ", do-tag=",
      if (isTRUE(state$executed_actions$do_tag)) "yes" else "no",
      ", deploy-site=",
      if (isTRUE(state$executed_actions$deploy_site)) "yes" else "no"
    )
  }

  invisible(result)
}

# Run the publish stage from the command line.
run_publish_package <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_publish_args(args)

  if (isTRUE(options$help)) {
    .print_publish_help()
    return(invisible(NULL))
  }

  .cli_run_main(function() {
    invisible(
      publish_package(
        release_version = options$release_version,
        root = options$root,
        dry_run = options$dry_run,
        do_tag = options$do_tag,
        deploy_site = options$deploy_site,
        verbose = options$verbose
      )
    )
  })
}

if (sys.nframe() == 0L) {
  run_publish_package()
}
# nolint end
