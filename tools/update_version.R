#!/usr/bin/env Rscript

# Version mirror update helper for the shiny.webawesome maintenance workflow.
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

.update_version_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .update_version_tool_base_dirs
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

# Return the CLI usage string for the version update helper.
.update_version_usage <- function() {
  paste(
    "Usage: ./tools/update_version.R",
    paste(
      "[--root <path>] [--package-ver <version>]",
      "[--upstream-ver <version>] [--allow-main] [--allow-dirty]",
      "[--check] [--quiet] [--help]"
    )
  )
}

# Return the short CLI description for the version update helper.
.update_version_description <- function() {
  paste(
    "Update handwritten package and bundled-upstream version mirrors",
    "consistently across the repository."
  )
}

# List supported CLI options for the version update helper.
.update_version_option_lines <- function() {
  c(
    paste(
      "--root <path>             Repository root.",
      "Defaults to the current directory."
    ),
    "--package-ver <version>   Target package version.",
    "--upstream-ver <version>  Target bundled upstream Web Awesome version.",
    "--allow-main              Permit running from the `main` branch.",
    "--allow-dirty             Permit running with a dirty git worktree.",
    "--check                   Report targeted rewrites without writing files.",
    "--quiet                   Suppress stage-level progress messages.",
    "--help, -h                Print this help text."
  )
}

# Print the CLI help text for the version update helper.
.print_update_version_help <- function() {
  writeLines(
    c(
      .update_version_description(),
      "",
      .update_version_usage(),
      "",
      "Options:",
      .update_version_option_lines()
    )
  )
}

# Define default CLI option values for the version update helper.
.update_version_defaults <- function() {
  list(
    root = ".",
    package_ver = NULL,
    upstream_ver = NULL,
    allow_main = FALSE,
    allow_dirty = FALSE,
    check = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the version update helper.
.parse_update_version_args <- function(args) {
  options <- .update_version_defaults()
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

    if (arg == "--allow-dirty") {
      options$allow_dirty <- TRUE
      next
    }

    if (arg == "--check") {
      options$check <- TRUE
      next
    }

    if (arg == "--quiet") {
      options$verbose <- FALSE
      next
    }

    if (arg %in% c("--root", "--package-ver", "--upstream-ver")) {
      if (i == length(args)) {
        stop(sprintf("Missing value for %s.", arg), call. = FALSE)
      }

      value <- args[[i + 1L]]
      if (!nzchar(value)) {
        stop(sprintf("Missing value for %s.", arg), call. = FALSE)
      }

      if (identical(arg, "--root")) {
        options$root <- value
      } else if (identical(arg, "--package-ver")) {
        options$package_ver <- value
      } else {
        options$upstream_ver <- value
      }

      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--root=")) {
      options$root <- sub("^--root=", "", arg)
      next
    }

    if (startsWith(arg, "--package-ver=")) {
      options$package_ver <- sub("^--package-ver=", "", arg)
      next
    }

    if (startsWith(arg, "--upstream-ver=")) {
      options$upstream_ver <- sub("^--upstream-ver=", "", arg)
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .update_version_usage()),
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
      "The `processx` package is required to run version-update commands.",
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

# Return UTF-8 lines from one file.
.read_lines_utf8 <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

# Write one text file deterministically.
.write_text_lines <- function(path, lines) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(lines), path, useBytes = TRUE)
  invisible(path)
}

# Return the package version from DESCRIPTION.
.description_version <- function(root) {
  read.dcf(file.path(root, "DESCRIPTION"))[[1, "Version"]]
}

# Return the bundled upstream version from the canonical handwritten source.
.upstream_version <- function(root) {
  trimws(
    .read_lines_utf8(file.path(root, "dev", "webawesome-version.txt"))[[1]]
  )
}

# Return trimmed file lines when one file exists, otherwise an empty vector.
.read_trimmed_lines <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }

  trimws(.read_lines_utf8(path))
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

    versions <- versions[!is.na(versions)]
    if (length(versions) > 0L) {
      return(versions[[1]])
    }
  }

  NA_character_
}

# Build the canonical pkgdown description mirror string.
.pkgdown_description_text <- function(package_ver, upstream_ver) {
  paste(
    "Shiny bindings for Web Awesome components.",
    sprintf(
      "Package version %s; bundled upstream Web Awesome version %s.",
      package_ver,
      upstream_ver
    )
  )
}

# Build the canonical pkgdown subtitle mirror string.
.pkgdown_subtitle_text <- function(package_ver, upstream_ver) {
  paste(
    "Shiny bindings for Web Awesome components.",
    sprintf(
      "Package %s with bundled Web Awesome %s.",
      package_ver,
      upstream_ver
    )
  )
}

# Build the canonical pkgdown upstream navbar label.
.pkgdown_upstream_text <- function(upstream_ver) {
  sprintf("Web Awesome %s", upstream_ver)
}

# Return the indentation width for one line.
.line_indent <- function(line) {
  attr(regexpr("[^ ]", line), "match.length")
  nchar(sub("^([ ]*).*", "\\1", line))
}

# Return the last line index belonging to one indentation-based section.
.section_end_index <- function(lines, start_index, indent) {
  if (start_index >= length(lines)) {
    return(start_index)
  }

  for (i in seq.int(start_index + 1L, length(lines))) {
    line <- lines[[i]]

    if (!nzchar(trimws(line))) {
      next
    }

    if (.line_indent(line) <= indent) {
      return(i - 1L)
    }
  }

  length(lines)
}

# Find one child key line inside an indentation-based YAML section.
.find_child_line <- function(lines, parent_index, parent_indent, key, indent) {
  section_end <- .section_end_index(lines, parent_index, parent_indent)
  if (parent_index >= section_end) {
    stop(sprintf("Could not find `%s` in `_pkgdown.yml`.", key), call. = FALSE)
  }

  pattern <- sprintf("^%s%s:\\s*(.*)?$", strrep(" ", indent), key)
  matches <- which(grepl(pattern, lines))
  matches <- matches[matches > parent_index & matches <= section_end]

  if (length(matches) != 1L) {
    stop(sprintf("Could not find `%s` in `_pkgdown.yml`.", key), call. = FALSE)
  }

  matches[[1]]
}

# Return the text content for one folded YAML scalar field.
.read_yaml_block_text <- function(lines, header_index) {
  header_indent <- .line_indent(lines[[header_index]])
  end_index <- .section_end_index(lines, header_index, header_indent)

  if (end_index <= header_index) {
    return("")
  }

  body <- trimws(lines[seq.int(header_index + 1L, end_index)])
  paste(body[nzchar(body)], collapse = " ")
}

# Rewrite one folded YAML scalar field deterministically.
.rewrite_yaml_block <- function(lines, header_index, text) {
  header_indent <- .line_indent(lines[[header_index]])
  end_index <- .section_end_index(lines, header_index, header_indent)
  body_indent <- header_indent + 2L
  wrapped <- strwrap(
    text,
    width = max(20L, 78L - body_indent),
    simplify = FALSE
  )[[1]]
  replacement <- paste0(strrep(" ", body_indent), wrapped)

  if (end_index <= header_index) {
    append(lines, replacement, after = header_index)
  } else {
    c(
      lines[seq_len(header_index)],
      replacement,
      lines[seq.int(end_index + 1L, length(lines))]
    )
  }
}

# Return the inline scalar value for one YAML key line.
.read_yaml_inline_value <- function(line) {
  trimws(sub("^[^:]+:\\s*", "", line))
}

# Rewrite one inline YAML scalar field deterministically.
.rewrite_yaml_inline <- function(lines, line_index, key, indent, value) {
  lines[[line_index]] <- sprintf(
    "%s%s: %s",
    strrep(" ", indent),
    key,
    value
  )
  lines
}

# Return current mirrored values from `_pkgdown.yml`.
.pkgdown_mirrors <- function(root) {
  lines <- .read_lines_utf8(file.path(root, "_pkgdown.yml"))

  home_index <- .find_child_line(lines, 0L, -1L, "home", 0L)
  description_index <- .find_child_line(
    lines,
    home_index,
    0L,
    "description",
    2L
  )
  strip_index <- .find_child_line(lines, home_index, 0L, "strip", 2L)
  subtitle_index <- .find_child_line(lines, strip_index, 2L, "subtitle", 4L)

  navbar_index <- .find_child_line(lines, 0L, -1L, "navbar", 0L)
  components_index <- .find_child_line(
    lines,
    navbar_index,
    0L,
    "components",
    2L
  )
  upstream_index <- .find_child_line(
    lines,
    components_index,
    2L,
    "upstream",
    4L
  )
  upstream_text_index <- .find_child_line(lines, upstream_index, 4L, "text", 6L)

  list(
    description = .read_yaml_block_text(lines, description_index),
    subtitle = .read_yaml_block_text(lines, subtitle_index),
    upstream_text = .read_yaml_inline_value(lines[[upstream_text_index]])
  )
}

# Rewrite targeted `_pkgdown.yml` mirrors and return old/new values plus lines.
.rewrite_pkgdown <- function(root, package_ver, upstream_ver) {
  path <- file.path(root, "_pkgdown.yml")
  lines <- .read_lines_utf8(path)

  home_index <- .find_child_line(lines, 0L, -1L, "home", 0L)
  description_index <- .find_child_line(
    lines,
    home_index,
    0L,
    "description",
    2L
  )
  strip_index <- .find_child_line(lines, home_index, 0L, "strip", 2L)
  subtitle_index <- .find_child_line(lines, strip_index, 2L, "subtitle", 4L)

  old_description <- .read_yaml_block_text(lines, description_index)
  new_description <- .pkgdown_description_text(package_ver, upstream_ver)
  lines <- .rewrite_yaml_block(lines, description_index, new_description)

  home_index <- .find_child_line(lines, 0L, -1L, "home", 0L)
  strip_index <- .find_child_line(lines, home_index, 0L, "strip", 2L)
  subtitle_index <- .find_child_line(lines, strip_index, 2L, "subtitle", 4L)
  old_subtitle <- .read_yaml_block_text(lines, subtitle_index)
  new_subtitle <- .pkgdown_subtitle_text(package_ver, upstream_ver)
  lines <- .rewrite_yaml_block(lines, subtitle_index, new_subtitle)

  navbar_index <- .find_child_line(lines, 0L, -1L, "navbar", 0L)
  components_index <- .find_child_line(
    lines,
    navbar_index,
    0L,
    "components",
    2L
  )
  upstream_index <- .find_child_line(
    lines,
    components_index,
    2L,
    "upstream",
    4L
  )
  upstream_text_index <- .find_child_line(lines, upstream_index, 4L, "text", 6L)
  old_upstream_text <- .read_yaml_inline_value(lines[[upstream_text_index]])
  new_upstream_text <- .pkgdown_upstream_text(upstream_ver)
  lines <- .rewrite_yaml_inline(
    lines,
    line_index = upstream_text_index,
    key = "text",
    indent = 6L,
    value = new_upstream_text
  )

  list(
    lines = lines,
    records = list(
      list(
        key = "_pkgdown.yml home.description",
        path = "_pkgdown.yml",
        old = old_description,
        new = new_description
      ),
      list(
        key = "_pkgdown.yml home.strip.subtitle",
        path = "_pkgdown.yml",
        old = old_subtitle,
        new = new_subtitle
      ),
      list(
        key = "_pkgdown.yml navbar.components.upstream.text",
        path = "_pkgdown.yml",
        old = old_upstream_text,
        new = new_upstream_text
      )
    )
  )
}

# Rewrite the DESCRIPTION version field.
.rewrite_description <- function(root, package_ver) {
  path <- file.path(root, "DESCRIPTION")
  lines <- .read_lines_utf8(path)
  matches <- grep("^Version:\\s+.*$", lines)

  if (length(matches) != 1L) {
    stop("Could not find `Version:` in `DESCRIPTION`.", call. = FALSE)
  }

  old <- trimws(sub("^Version:\\s+", "", lines[[matches[[1]]]]))
  lines[[matches[[1]]]] <- sprintf("Version: %s", package_ver)

  list(
    lines = lines,
    record = list(
      key = "DESCRIPTION Version",
      path = "DESCRIPTION",
      old = old,
      new = package_ver
    )
  )
}

# Rewrite the NEWS latest version heading.
.rewrite_news <- function(root, package_ver) {
  path <- file.path(root, "NEWS.md")
  lines <- .read_lines_utf8(path)
  patterns <- c(
    "^#\\s+Version\\s+([0-9][0-9A-Za-z.\\-]*)\\s*$",
    "^#\\s+[A-Za-z][A-Za-z0-9._\\-]*\\s+([0-9][0-9A-Za-z.\\-]*)\\s*$"
  )
  match_index <- NA_integer_
  old <- NA_character_

  for (pattern in patterns) {
    matches <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
    found <- which(vapply(matches, length, integer(1)) >= 2L)
    if (length(found) > 0L) {
      match_index <- found[[1]]
      old <- matches[[match_index]][[2]]
      break
    }
  }

  if (is.na(match_index)) {
    stop(
      "Could not find the latest release heading in `NEWS.md`.",
      call. = FALSE
    )
  }

  lines[[match_index]] <- sprintf("# Version %s", package_ver)

  list(
    lines = lines,
    record = list(
      key = "NEWS.md latest heading",
      path = "NEWS.md",
      old = old,
      new = package_ver
    )
  )
}

# Rewrite the canonical handwritten upstream version file.
.rewrite_upstream_version <- function(root, upstream_ver) {
  path <- file.path(root, "dev", "webawesome-version.txt")
  lines <- .read_lines_utf8(path)

  if (length(lines) == 0L) {
    stop("`dev/webawesome-version.txt` is empty.", call. = FALSE)
  }

  old <- trimws(lines[[1]])
  lines[[1]] <- upstream_ver

  list(
    lines = lines,
    record = list(
      key = "dev/webawesome-version.txt",
      path = file.path("dev", "webawesome-version.txt"),
      old = old,
      new = upstream_ver
    )
  )
}

# Append one rewrite record with a derived changed flag.
.record_with_changed <- function(record) {
  record$changed <- !identical(record$old, record$new)
  record
}

# Emit old-to-new summaries for changed targeted records.
.emit_update_version_summary <- function(records, check = FALSE) {
  changed <- Filter(function(record) isTRUE(record$changed), records)

  if (length(changed) == 0L) {
    message("No targeted version records needed changes.")
    return(invisible(NULL))
  }

  prefix <- if (isTRUE(check)) "Would update" else "Updated"
  for (record in changed) {
    message(
      sprintf(
        "%s %s: %s -> %s",
        prefix,
        record$key,
        record$old,
        record$new
      )
    )
  }
}

# Compute planned file rewrites for the requested version targets.
.plan_version_updates <- function(root,
                                  package_ver = NULL,
                                  upstream_ver = NULL) {
  current_package <- .description_version(root)
  current_upstream <- .upstream_version(root)
  target_package <- package_ver %||% current_package
  target_upstream <- upstream_ver %||% current_upstream

  records <- list()
  writes <- list()

  if (!is.null(package_ver)) {
    description <- .rewrite_description(root, package_ver)
    news <- .rewrite_news(root, package_ver)

    writes[[description$record$path]] <- description$lines
    writes[[news$record$path]] <- news$lines
    records <- c(
      records,
      list(
        .record_with_changed(description$record),
        .record_with_changed(news$record)
      )
    )
  }

  if (!is.null(upstream_ver)) {
    upstream <- .rewrite_upstream_version(root, upstream_ver)
    writes[[upstream$record$path]] <- upstream$lines
    records <- c(records, list(.record_with_changed(upstream$record)))
  }

  if (!is.null(package_ver) || !is.null(upstream_ver)) {
    pkgdown <- .rewrite_pkgdown(root, target_package, target_upstream)
    writes[["_pkgdown.yml"]] <- pkgdown$lines
    records <- c(
      records,
      lapply(pkgdown$records, .record_with_changed)
    )
  }

  list(
    writes = writes,
    records = records,
    target_package = target_package,
    target_upstream = target_upstream
  )
}

# Update known handwritten version mirrors in one repository worktree.
#'
#' Updates the canonical handwritten version records plus the small set of
#' handwritten mirrors described in the deferred `update-version` plan. The
#' helper intentionally excludes generated, prune-owned, and finalize-owned
#' artifacts from its write scope.
#'
#' CLI entry point:
#' `./tools/update_version.R --help`
#'
#' @param root Repository root directory.
#' @param package_ver Optional target package version. When supplied, updates
#'   `DESCRIPTION`, `NEWS.md`, and the mirrored package-version text embedded in
#'   `_pkgdown.yml`.
#' @param upstream_ver Optional target bundled upstream Web Awesome version.
#'   When supplied, updates `dev/webawesome-version.txt` and the mirrored
#'   upstream-version text embedded in `_pkgdown.yml`.
#' @param allow_main Logical scalar. If `FALSE`, refuse to run from `main`.
#' @param allow_dirty Logical scalar. If `FALSE`, refuse to run with a dirty
#'   git worktree.
#' @param check Logical scalar. If `TRUE`, report targeted rewrites without
#'   writing files.
#' @param verbose Logical scalar. If `TRUE`, emit progress and rewrite
#'   summaries.
#' @param git_runner Function used to execute git child commands. This is
#'   primarily a test seam.
#'
#' @return A list describing the targeted versions and affected records.
#'
#' @examples
#' \dontrun{
#' update_version(package_ver = "1.0.1")
#' update_version(upstream_ver = "3.5.1")
#' update_version(package_ver = "1.1.0", upstream_ver = "3.6.0")
#' update_version(package_ver = "1.1.0", check = TRUE)
#' }
update_version <- function(root = ".",
                           package_ver = NULL,
                           upstream_ver = NULL,
                           allow_main = FALSE,
                           allow_dirty = FALSE,
                           check = FALSE,
                           verbose = interactive(),
                           git_runner = .run_process) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  if (is.null(package_ver) && is.null(upstream_ver)) {
    stop(
      "Supply at least one of `package_ver` or `upstream_ver`.",
      call. = FALSE
    )
  }

  branch <- .git_branch(root, runner = git_runner)
  dirty <- .git_dirty(root, runner = git_runner)

  if (identical(branch, "main") && !isTRUE(allow_main)) {
    stop(
      "Refusing to run from `main` without `allow_main = TRUE`.",
      call. = FALSE
    )
  }

  if (isTRUE(dirty) && !isTRUE(allow_dirty)) {
    stop(
      "Refusing to run with a dirty git worktree without `allow_dirty = TRUE`.",
      call. = FALSE
    )
  }

  plan <- .plan_version_updates(
    root = root,
    package_ver = package_ver,
    upstream_ver = upstream_ver
  )

  if (!isTRUE(check)) {
    for (path in names(plan$writes)) {
      .write_text_lines(file.path(root, path), plan$writes[[path]])
    }
  }

  if (isTRUE(verbose)) {
    .emit_update_version_summary(plan$records, check = check)
  }

  invisible(
    list(
      root = root,
      branch = branch,
      dirty = dirty,
      package_ver = plan$target_package,
      upstream_ver = plan$target_upstream,
      check = check,
      records = plan$records
    )
  )
}

# Run the version update helper from the command line.
run_update_version <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_update_version_args(args)

  if (isTRUE(options$help)) {
    .print_update_version_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  step_label <- if (isTRUE(options$check)) {
    "Checking version mirrors"
  } else {
    "Updating version mirrors"
  }

  .cli_step_start(ui, step_label)

  result <- tryCatch(
    update_version(
      root = options$root,
      package_ver = options$package_ver,
      upstream_ver = options$upstream_ver,
      allow_main = options$allow_main,
      allow_dirty = options$allow_dirty,
      check = options$check,
      verbose = options$verbose
    ),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  .cli_step_finish(ui, status = if (isTRUE(options$check)) "Pass" else "Done")
  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_update_version)
}
# nolint end
