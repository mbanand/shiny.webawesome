#!/usr/bin/env Rscript

# Prune stage implementation for the shiny.webawesome build pipeline.
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

# Return the CLI usage string for the prune stage.
.prune_usage <- function() {
  paste(
    "Usage: ./tools/prune_webawesome.R",
    "[--version <version>] [--root <path>] [--quiet] [--help]"
  )
}

# Return the short CLI description for the prune stage.
.prune_description <- function() {
  "Prune a fetched Web Awesome dist-cdn bundle into package runtime assets."
}

# List supported CLI options for the prune stage.
.prune_option_lines <- function() {
  c(
    "--version, -v <version>  Upstream Web Awesome version to prune.",
    paste(
      "--root <path>            Repository root.",
      "Defaults to the current directory."
    ),
    "--quiet                  Suppress stage-level progress messages.",
    "--help, -h               Print this help text."
  )
}

# Print the CLI help text for the prune stage.
.print_prune_help <- function() {
  writeLines(
    c(
      .prune_description(),
      "",
      .prune_usage(),
      "",
      "Options:",
      .prune_option_lines()
    )
  )
}

# Define default CLI option values for the prune stage.
.prune_defaults <- function() {
  list(
    version = NULL,
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the prune stage.
.parse_prune_args <- function(args) {
  options <- .prune_defaults()
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

    if (arg == "--quiet") {
      options$verbose <- FALSE
      next
    }

    if (arg %in% c("--version", "-v")) {
      if (i == length(args)) {
        stop("Missing value for --version.", call. = FALSE)
      }

      options$version <- args[[i + 1L]]
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--version=")) {
      options$version <- sub("^--version=", "", arg)
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
      paste0("Unknown argument: ", arg, "\n", .prune_usage()),
      call. = FALSE
    )
  }

  options
}

# Check whether a path looks like the repository root.
.is_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "docs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

# Remove the repository root prefix from one or more absolute paths.
.strip_root_prefix <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

# Return the default relative path to the pinned version file.
.default_version_file <- function() {
  file.path("dev", "webawesome-version.txt")
}

# Read and trim lines from a text file using UTF-8.
.read_lines_trimmed <- function(path) {
  trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

# Read the pinned Web Awesome version from the repository input file.
.read_pinned_version <- function(
  root,
  version_file = .default_version_file()
) {
  version_path <- file.path(root, version_file)

  if (!file.exists(version_path)) {
    stop(
      "Pinned Web Awesome version file does not exist: ",
      version_file,
      call. = FALSE
    )
  }

  lines <- .read_lines_trimmed(version_path)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  if (length(lines) != 1L) {
    stop(
      paste(
        "Pinned Web Awesome version file must contain exactly one",
        "version string:"
      ),
      version_file,
      call. = FALSE
    )
  }

  lines[[1]]
}

# Validate and normalize a requested Web Awesome version string.
.validate_prune_version <- function(version) {
  version <- trimws(version %||% "")

  if (!nzchar(version)) {
    stop("Web Awesome version must be a non-empty string.", call. = FALSE)
  }

  if (grepl("[/\\\\]", version)) {
    stop("Web Awesome version must not contain path separators.", call. = FALSE)
  }

  version
}

# Build the version-specific vendor target directory path.
.fetch_target_dir <- function(root, version) {
  file.path(root, "vendor", "webawesome", version)
}

# Build the version-specific vendored browser-runtime directory path.
.fetch_runtime_dir <- function(root, version) {
  file.path(.fetch_target_dir(root, version), "dist-cdn")
}

# Build the pruned runtime output directory path.
.prune_runtime_dir <- function(root) {
  file.path(root, "inst", "www", "webawesome")
}

# Build the copied metadata output directory path.
.prune_extdata_dir <- function(root) {
  file.path(root, "inst", "extdata", "webawesome")
}

# Build the version-specific prune report directory path.
.prune_report_dir <- function(root, version) {
  file.path(root, "report", "prune", version)
}

# Return the metadata files copied into inst/extdata/webawesome.
.prune_metadata_files <- function() {
  c("custom-elements.json", "VERSION")
}

# Return the runtime source directories treated as graph entry roots.
.prune_entry_directories <- function() {
  c("components", "events", "styles", "translations", "utilities")
}

# Return whether a runtime candidate lives under an entry-root directory.
.has_entry_directory_prefix <- function(relative_path) {
  any(startsWith(relative_path, paste0(.prune_entry_directories(), "/")))
}

# Return the upstream dist directories expected to exist before pruning.
.prune_expected_directories <- function() {
  c(.prune_entry_directories(), "chunks")
}

# Return the explicit top-level files excluded from runtime candidates.
.prune_excluded_files <- function() {
  c(
    "custom-elements-jsx.d.ts",
    "custom-elements.json",
    "llms.txt",
    "vscode.html-custom-data.json",
    "web-types.json",
    "webawesome.d.ts",
    "webawesome.js",
    "webawesome.loader.d.ts",
    "webawesome.ssr-loader.d.ts",
    "webawesome.ssr-loader.js"
  )
}

# Return whether a dist-relative file should be excluded from runtime analysis.
.is_excluded_runtime_file <- function(relative_path) {
  parts <- strsplit(relative_path, "/", fixed = TRUE)[[1]]
  top_level <- parts[[1]]

  if (length(parts) == 1L) {
    return(relative_path %in% .prune_excluded_files())
  }

  top_level %in% c("react", "types")
}

# Return whether a dist-relative file can participate in runtime analysis.
.is_runtime_candidate <- function(relative_path) {
  if (.is_excluded_runtime_file(relative_path)) {
    return(FALSE)
  }

  if (endsWith(relative_path, ".d.ts")) {
    return(FALSE)
  }

  tools::file_ext(relative_path) %in% c("css", "js", "json")
}

# Return whether a path currently exists and contains any entries.
.path_is_non_empty <- function(path) {
  if (!dir.exists(path)) {
    return(FALSE)
  }

  length(list.files(path, all.files = TRUE, no.. = TRUE)) > 0L
}

# Fail if prune-owned output directories already contain content.
.ensure_prune_outputs_empty <- function(root, version) {
  targets <- c(
    .prune_runtime_dir(root),
    .prune_extdata_dir(root),
    .prune_report_dir(root, version)
  )

  non_empty <- targets[vapply(targets, .path_is_non_empty, logical(1))]

  if (length(non_empty) > 0L) {
    stop(
      paste(
        "Prune output directories already contain content:",
        paste(.strip_root_prefix(non_empty, root), collapse = ", "),
        "Run clean_webawesome() before pruning."
      ),
      call. = FALSE
    )
  }
}

# List one directory tree in deterministic relative-path order.
.list_relative_files <- function(path) {
  if (!dir.exists(path)) {
    return(character())
  }

  files <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    all.files = FALSE
  )
  files <- files[file.info(files)$isdir %in% FALSE]

  if (length(files) == 0L) {
    return(character())
  }

  sort(.strip_root_prefix(
    normalizePath(files, winslash = "/", mustWork = TRUE),
    normalizePath(path, winslash = "/", mustWork = TRUE)
  ))
}

# Validate that the fetched upstream version contains the expected inputs.
.validate_prune_inputs <- function(root, version, dist_dir) {
  version_dir <- .fetch_target_dir(root, version)

  if (!dir.exists(version_dir)) {
    stop(
      "Fetched upstream version does not exist: ",
      .strip_root_prefix(version_dir, root),
      ". Run fetch_webawesome() first.",
      call. = FALSE
    )
  }

  if (!dir.exists(dist_dir)) {
    stop(
      "Fetched upstream version is missing dist-cdn/: ",
      .strip_root_prefix(dist_dir, root),
      call. = FALSE
    )
  }

  required_dirs <- file.path(dist_dir, .prune_expected_directories())
  missing_dirs <- required_dirs[!dir.exists(required_dirs)]

  required_files <- file.path(
    dist_dir,
    c("custom-elements.json", "webawesome.loader.js")
  )
  missing_files <- required_files[!file.exists(required_files)]

  missing <- c(missing_dirs, missing_files)
  if (length(missing) > 0L) {
    stop(
      paste(
        "Fetched upstream artifacts are missing required prune inputs:",
        paste(.strip_root_prefix(missing, root), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

# Normalize one dist-relative import target against a source file.
.normalize_import_target <- function(source_relative, target) {
  if (!startsWith(target, ".")) {
    return(NULL)
  }

  parts <- strsplit(source_relative, "/", fixed = TRUE)[[1]]
  source_dir <- if (length(parts) > 1L) {
    parts[-length(parts)]
  } else {
    character()
  }

  target_parts <- strsplit(target, "/", fixed = TRUE)[[1]]
  resolved <- source_dir

  for (part in target_parts) {
    if (identical(part, ".") || identical(part, "")) {
      next
    }

    if (identical(part, "..")) {
      if (length(resolved) == 0L) {
        stop(
          "Import escapes the dist root from ",
          source_relative,
          ": ",
          target,
          call. = FALSE
        )
      }

      resolved <- resolved[-length(resolved)]
      next
    }

    resolved <- c(resolved, part)
  }

  paste(resolved, collapse = "/")
}

# Extract relative JS and CSS import targets from one source file.
.extract_import_targets <- function(path, relative_path) {
  extension <- tools::file_ext(path)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  text <- paste(lines, collapse = "\n")

  if (identical(extension, "css")) {
    matches <- gregexpr(
      "@import\\s+(?:url\\()?['\"]([^'\"]+)['\"]",
      text,
      perl = TRUE
    )
    raw <- regmatches(text, matches)[[1]]
    if (length(raw) == 0L || identical(raw[[1]], "-1")) {
      return(character())
    }

    targets <- sub("^@import\\s+(?:url\\()?['\"]", "", raw, perl = TRUE)
    targets <- sub("['\"].*$", "", targets, perl = TRUE)
  } else {
    patterns <- c(
      "(?:import|export)\\s+[^'\"]*?from\\s+['\"]([^'\"]+)['\"]",
      "import\\s*\\(\\s*['\"]([^'\"]+)['\"]\\s*\\)",
      "import\\s+['\"]([^'\"]+)['\"]"
    )

    targets <- character()
    for (pattern in patterns) {
      matches <- gregexpr(pattern, text, perl = TRUE)
      raw <- regmatches(text, matches)[[1]]
      if (length(raw) == 0L || identical(raw[[1]], "-1")) {
        next
      }

      targets <- c(
        targets,
        sub(pattern, "\\1", raw, perl = TRUE)
      )
    }
  }

  targets <- trimws(targets)
  targets <- targets[nzchar(targets)]

  normalized <- lapply(
    targets,
    .normalize_import_target,
    source_relative = relative_path
  )
  normalized <- unlist(normalized, use.names = FALSE)

  normalized[!is.na(normalized) & nzchar(normalized)]
}

# Walk the runtime import graph from the configured entry files.
.analyze_reachability <- function(dist_dir, entry_files, candidate_files) {
  queue <- sort(unique(entry_files))
  reached <- character()
  missing_imports <- list()
  import_graph <- list()

  while (length(queue) > 0L) {
    current <- queue[[1]]
    queue <- queue[-1]

    if (current %in% reached) {
      next
    }

    reached <- c(reached, current)
    source_path <- file.path(dist_dir, current)
    imports <- .extract_import_targets(source_path, current)
    import_graph[[current]] <- sort(unique(imports))

    missing <- imports[!file.exists(file.path(dist_dir, imports))]
    if (length(missing) > 0L) {
      missing_imports[[current]] <- sort(unique(missing))
    }

    existing <- imports[file.exists(file.path(dist_dir, imports))]
    queue <- sort(unique(c(queue, existing)))
  }

  list(
    entries = sort(unique(entry_files)),
    candidates = sort(unique(candidate_files)),
    reached = sort(unique(reached)),
    unreached = sort(setdiff(candidate_files, reached)),
    missing_imports = missing_imports,
    import_graph = import_graph
  )
}

# Convert missing-import records into one detail line per broken reference.
.format_missing_import_lines <- function(missing_imports) {
  if (length(missing_imports) == 0L) {
    return(character())
  }

  unlist(
    lapply(
      sort(names(missing_imports)),
      function(source) {
        paste0(source, " -> ", missing_imports[[source]])
      }
    ),
    use.names = FALSE
  )
}

# Copy one dist-relative file into the runtime bundle output tree.
.copy_runtime_file <- function(dist_dir, target_dir, relative_path) {
  source <- file.path(dist_dir, relative_path)
  target <- file.path(target_dir, relative_path)

  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(source, target, overwrite = TRUE)

  if (!isTRUE(copied)) {
    stop("Failed to copy pruned runtime file: ", relative_path, call. = FALSE)
  }

  invisible(relative_path)
}

# Copy one metadata file into inst/extdata/webawesome.
.copy_metadata_file <- function(source, target) {
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(source, target, overwrite = TRUE)

  if (!isTRUE(copied)) {
    stop(
      "Failed to copy prune metadata file: ",
      basename(source),
      call. = FALSE
    )
  }

  invisible(target)
}

# Write a deterministic Markdown file.
.write_markdown <- function(path, lines) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(lines), path, useBytes = TRUE)
}

# Format one Markdown bullet list or a fallback line for empty inputs.
.markdown_list <- function(values, empty_text) {
  if (length(values) == 0L) {
    return(empty_text)
  }

  paste0("- `", values, "`")
}

# Write the prune summary report.
.write_prune_summary_report <- function(result, summary_path) {
  lines <- c(
    "# Prune Summary",
    "",
    paste0("- Run time: ", result$generated_at),
    paste0("- Web Awesome version: `", result$version, "`"),
    paste0("- Source dist: `", result$source_dist_dir, "`"),
    paste0("- Runtime output: `", result$runtime_dir, "`"),
    paste0("- Metadata output: `", result$extdata_dir, "`"),
    paste0("- Reachability report: `", result$reachability_report, "`"),
    "",
    "## Counts",
    "",
    paste0("- Runtime files copied: ", length(result$runtime_files)),
    paste0("- Metadata files copied: ", length(result$metadata_files)),
    paste0("- Reachability entry files: ", length(result$reachability$entries)),
    paste0(
      "- Reachable runtime candidates: ",
      length(result$reachability$reached)
    ),
    paste0(
      "- Unreached runtime candidates: ",
      length(result$reachability$unreached)
    ),
    "",
    "## Runtime Files",
    "",
    .markdown_list(result$runtime_files, "- None"),
    "",
    "## Metadata Files",
    "",
    .markdown_list(result$metadata_files, "- None")
  )

  .write_markdown(summary_path, lines)
}

# Write the reachability analysis report.
.write_reachability_report <- function(result, reachability_path) {
  lines <- c(
    "# Prune Reachability Report",
    "",
    paste0("- Run time: ", result$generated_at),
    paste0("- Web Awesome version: `", result$version, "`"),
    "",
    "## Entry Files",
    "",
    .markdown_list(result$reachability$entries, "- None"),
    "",
    "## Reached Files",
    "",
    .markdown_list(result$reachability$reached, "- None"),
    "",
    "## Unreached Files",
    "",
    .markdown_list(result$reachability$unreached, "- None"),
    "",
    "## Missing Imports",
    "",
    .markdown_list(
      .format_missing_import_lines(result$reachability$missing_imports),
      "- None"
    )
  )

  .write_markdown(reachability_path, lines)
}

# Emit a short summary for a programmatic prune result.
.emit_prune_summary <- function(result) {
  message(
    "Pruned version ",
    result$version,
    " into ",
    result$runtime_dir,
    "; report=",
    result$summary_report
  )
}

#' Prune a fetched Web Awesome dist-cdn bundle
#'
#' This tool supports both direct command-line execution and sourcing from R.
#'
#' Use `prune_webawesome()` when the file has been sourced and you want to call
#' the prune stage programmatically. Use `run_prune_webawesome()` as the
#' command-line entry point when invoking `./tools/prune_webawesome.R`.
#'
#' Reads one fetched Web Awesome `dist-cdn/` tree from
#' `vendor/webawesome/<version>/dist-cdn/`, validates that the expected runtime
#' inputs are present, copies the pruned browser runtime bundle into
#' `inst/www/webawesome/`, copies `custom-elements.json` and `VERSION` into
#' `inst/extdata/webawesome/`, and writes deterministic prune reports under
#' `report/prune/<version>/`.
#'
#' If `version` is `NULL`, the version pinned in `dev/webawesome-version.txt`
#' is used.
#'
#' @param version Optional Web Awesome version string. If `NULL`, reads the
#'   pinned version from `dev/webawesome-version.txt`.
#' @param root Repository root directory.
#' @param version_file Path to the pinned version file, relative to the
#'   repository root.
#' @param verbose Logical scalar. If `TRUE`, emits a short prune summary.
#'
#' @return A list describing the prune operation, including copied runtime and
#'   metadata files plus the generated report paths.
#'
#' @examples
#' \dontrun{
#' prune_webawesome()
#' prune_webawesome(version = "3.3.1")
#' }
prune_webawesome <- function(version = NULL,
                             root = ".",
                             version_file = .default_version_file(),
                             verbose = interactive()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  version <- version %||% .read_pinned_version(
    root = root,
    version_file = version_file
  )
  version <- .validate_prune_version(version)

  dist_dir <- .fetch_runtime_dir(root, version)
  runtime_dir <- .prune_runtime_dir(root)
  extdata_dir <- .prune_extdata_dir(root)
  report_dir <- .prune_report_dir(root, version)

  .validate_prune_inputs(root = root, version = version, dist_dir = dist_dir)
  .ensure_prune_outputs_empty(root = root, version = version)

  all_dist_files <- .list_relative_files(dist_dir)
  candidate_files <- all_dist_files[vapply(
    all_dist_files,
    .is_runtime_candidate,
    logical(1)
  )]

  entry_files <- candidate_files[
    candidate_files %in% "webawesome.loader.js" |
      vapply(candidate_files, .has_entry_directory_prefix, logical(1))
  ]
  entry_files <- sort(unique(entry_files))

  if (!"webawesome.loader.js" %in% entry_files) {
    stop(
      paste(
        "Prune could not find the required loader entry file",
        "in the fetched dist-cdn bundle."
      ),
      call. = FALSE
    )
  }

  reachability <- .analyze_reachability(
    dist_dir = dist_dir,
    entry_files = entry_files,
    candidate_files = candidate_files
  )

  missing_lines <- .format_missing_import_lines(reachability$missing_imports)
  if (length(missing_lines) > 0L) {
    stop(
      paste(
        c(
          "Prune reachability analysis found missing imported files.",
          missing_lines
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  runtime_files <- reachability$reached
  metadata_files <- .prune_metadata_files()

  dir.create(runtime_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(extdata_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

  invisible(vapply(
    runtime_files,
    .copy_runtime_file,
    character(1),
    dist_dir = dist_dir,
    target_dir = runtime_dir
  ))

  invisible(vapply(
    metadata_files,
    function(relative_path) {
      source <- if (identical(relative_path, "VERSION")) {
        file.path(.fetch_target_dir(root, version), relative_path)
      } else {
        file.path(dist_dir, relative_path)
      }
      target <- file.path(extdata_dir, relative_path)
      .copy_metadata_file(source, target)
      relative_path
    },
    character(1)
  ))

  generated_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  summary_path <- file.path(report_dir, "summary.md")
  reachability_path <- file.path(report_dir, "reachability.md")

  result <- list(
    version = version,
    generated_at = generated_at,
    root = root,
    source_dist_dir = .strip_root_prefix(dist_dir, root),
    runtime_dir = .strip_root_prefix(runtime_dir, root),
    extdata_dir = .strip_root_prefix(extdata_dir, root),
    report_dir = .strip_root_prefix(report_dir, root),
    runtime_files = sort(runtime_files),
    metadata_files = sort(metadata_files),
    reachability = reachability,
    summary_report = .strip_root_prefix(summary_path, root),
    reachability_report = .strip_root_prefix(reachability_path, root)
  )

  .write_prune_summary_report(result, summary_path)
  .write_reachability_report(result, reachability_path)

  if (isTRUE(verbose)) {
    .emit_prune_summary(result)
  }

  result
}

# Emit a short summary for the prune CLI runner.
.emit_prune_runner_summary <- function(result) {
  message(
    "Prune complete: version=",
    result$version,
    ", runtime=",
    result$runtime_dir,
    ", report=",
    result$summary_report
  )
}

#' Run the prune stage from the command line
#'
#' Parses CLI arguments, executes `prune_webawesome()`, and prints a short
#' status summary for the pruned runtime bundle.
#'
#' This is the command-line entry point for the prune stage.
#'
#' Supported options are:
#' - `--version` / `-v` to override the pinned upstream version
#' - `--root` to run against a different repository root
#' - `--quiet` to suppress stage-level progress messages
#' - `--help` / `-h` to print CLI help
#'
#' @rdname prune_webawesome
#' @describeIn prune_webawesome Run the prune stage from the command line.
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the result from `prune_webawesome()`. If `--help`
#'   or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_prune_webawesome()
#' run_prune_webawesome(c("--version", "3.3.1"))
#' run_prune_webawesome("--help")
#' }
run_prune_webawesome <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_prune_args(args)

  if (isTRUE(options$help)) {
    .print_prune_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(options$verbose)
  .cli_step_start(ui, "Pruning Web Awesome")

  result <- tryCatch(
    {
      prune_webawesome(
        version = options$version,
        root = options$root,
        verbose = FALSE
      )
    },
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  .cli_step_finish(
    ui,
    status = "Done",
    comment = paste0("[report: ", result$summary_report, "]")
  )
  .emit_prune_runner_summary(result)

  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_prune_webawesome)
}
# nolint end
