#!/usr/bin/env Rscript

# Generate stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It currently implements metadata extraction and the
# intermediate component schema and now emits selected generated files.

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

.generate_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .generate_tool_base_dirs
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

# Source the shared generate helpers relative to this script when possible.
.bootstrap_generate_helpers <- function() {
  base_dirs <- .generate_tool_base_dirs
  helper_files <- c(
    "utils.R",
    "policy.R",
    "metadata.R",
    "schema.R",
    "render_utils.R",
    "render_wrappers.R",
    "render_updates.R",
    "render_bindings.R",
    "write_outputs.R"
  )

  helper_dir_candidates <- unique(c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "generate"))),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "tools", "generate"))
    ),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "..", "generate"))),
    unlist(
      lapply(
        base_dirs,
        function(dir) file.path(dir, "..", "tools", "generate")
      )
    ),
    file.path("tools", "generate"),
    "generate"
  ))
  existing_helper_dirs <- helper_dir_candidates[
    dir.exists(helper_dir_candidates)
  ]

  helper_paths <- NULL
  for (helper_dir in existing_helper_dirs) {
    candidate_paths <- file.path(helper_dir, helper_files)
    if (all(file.exists(candidate_paths))) {
      helper_paths <- candidate_paths
      break
    }
  }

  if (is.null(helper_paths)) {
    stop(
      "Generate helper files do not exist: ",
      paste(helper_files, collapse = ", "),
      call. = FALSE
    )
  }

  for (path in helper_paths) {
    source(path)
  }
}

.bootstrap_cli_ui()
.bootstrap_generate_helpers()

# Source the shared integrity helpers relative to this script when possible.
.bootstrap_integrity_helpers <- function() {
  base_dirs <- .generate_tool_base_dirs
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

.bootstrap_integrity_helpers()
rm(.bootstrap_cli_ui, .bootstrap_generate_helpers, .bootstrap_integrity_helpers)

# Return the CLI usage string for the generate stage.
.generate_usage <- function() {
  paste(
    "Usage: ./tools/generate_components.R",
    "[--root <path>] [--filter <components>] [--exclude <components>]",
    "[--schema-only] [--debug] [--quiet] [--help]"
  )
}

# Return the short CLI description for the generate stage.
.generate_description <- function() {
  paste(
    "Build the intermediate component schema from copied",
    "Web Awesome metadata."
  )
}

# List supported CLI options for the generate stage.
.generate_option_lines <- function() {
  c(
    paste(
      "--root <path>            Repository root.",
      "Defaults to the current directory."
    ),
    paste(
      "--filter <components>    Comma-separated tags, component names, or",
      "wa_* function names to include."
    ),
    paste(
      "--exclude <components>   Comma-separated tags, component names, or",
      "wa_* function names to exclude."
    ),
    "--schema-only            Build schema only and skip writing outputs.",
    paste(
      "--debug                  Write metadata/schema snapshots under",
      "scratch/debug/."
    ),
    "--quiet                  Suppress stage-level progress messages.",
    "--help, -h               Print this help text."
  )
}

# Print the CLI help text for the generate stage.
.print_generate_help <- function() {
  writeLines(
    c(
      .generate_description(),
      "",
      .generate_usage(),
      "",
      "Options:",
      .generate_option_lines()
    )
  )
}

# Define default CLI option values for the generate stage.
.generate_defaults <- function() {
  list(
    root = ".",
    filter = character(),
    exclude = character(),
    emit = TRUE,
    debug = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the generate stage.
.parse_generate_args <- function(args) {
  options <- .generate_defaults()
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

    if (arg == "--debug") {
      options$debug <- TRUE
      next
    }

    if (arg == "--schema-only") {
      options$emit <- FALSE
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

    if (arg == "--filter") {
      if (i == length(args)) {
        stop("Missing value for --filter.", call. = FALSE)
      }

      options$filter <- c(options$filter, args[[i + 1L]])
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--filter=")) {
      options$filter <- c(options$filter, sub("^--filter=", "", arg))
      next
    }

    if (arg == "--exclude") {
      if (i == length(args)) {
        stop("Missing value for --exclude.", call. = FALSE)
      }

      options$exclude <- c(options$exclude, args[[i + 1L]])
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--exclude=")) {
      options$exclude <- c(options$exclude, sub("^--exclude=", "", arg))
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .generate_usage()),
      call. = FALSE
    )
  }

  options
}

# Return the repository-local directory used for generate debug artifacts.
.generate_debug_root <- function(root) {
  file.path(root, "scratch", "debug")
}

# Return one persistent generate debug directory path.
.generate_debug_dir <- function(root) {
  stamp <- format(Sys.time(), "%Y%m%d-%H%M%S", tz = "UTC")
  file.path(
    .generate_debug_root(root),
    paste0("generate-components-", stamp, "-", Sys.getpid())
  )
}

# Write schema debug artifacts and return their relative paths.
.write_debug_artifacts <- function(result, root) {
  debug_dir <- .generate_debug_dir(root)
  dir.create(debug_dir, recursive = TRUE, showWarnings = FALSE)

  metadata_summary_path <- file.path(debug_dir, "metadata-summary.json")
  schema_path <- file.path(debug_dir, "component-schema.json")
  filters_path <- file.path(debug_dir, "filters.json")

  .write_debug_json(metadata_summary_path, result$metadata)
  debug_schema <- result$schema
  debug_schema$components <- .debug_components_by_tag(debug_schema$components)

  .write_debug_json(schema_path, debug_schema)
  .write_debug_json(
    filters_path,
    list(
      include = result$filter,
      exclude = result$exclude
    )
  )

  list(
    directory = debug_dir,
    metadata_summary = metadata_summary_path,
    schema = schema_path,
    filters = filters_path,
    relative_directory = .strip_root_prefix(debug_dir, root)
  )
}

# Emit a short summary for a programmatic generate result.
.emit_generate_summary <- function(result) {
  message(
    "Built schema for ",
    result$component_count,
    " component(s) from ",
    result$metadata_path
  )
}

#' Build the intermediate Web Awesome component schema
#'
#' The current implementation reads the copied metadata produced by the prune
#' stage from `inst/extdata/webawesome/custom-elements.json`, extracts custom
#' element declarations, and constructs a deterministic intermediate schema.
#' The current implementation reads the copied metadata produced by the prune
#' stage from `inst/extdata/webawesome/custom-elements.json`, extracts custom
#' element declarations, constructs a deterministic intermediate schema, and
#' emits generated wrapper, binding, and update files for the selected
#' component set.
#'
#' CLI entry point:
#' `./tools/generate_components.R --help`
#'
#' @param root Repository root directory.
#' @param metadata_file Path to the copied `custom-elements.json` file,
#'   relative to the repository root.
#' @param version_file Path to the copied Web Awesome version file, relative to
#'   the repository root.
#' @param binding_policy_file Path to the handwritten binding-override policy
#'   file, relative to the repository root.
#' @param attribute_policy_file Path to the handwritten attribute-override
#'   policy file, relative to the repository root.
#' @param filter Optional character vector of tags, component names, or
#'   `wa_*` function names to include.
#' @param exclude Optional character vector of tags, component names, or
#'   `wa_*` function names to exclude.
#' @param emit Logical scalar. If `TRUE`, writes generated output files.
#' @param debug Logical scalar. If `TRUE`, writes JSON debug snapshots under
#'   `scratch/debug/`.
#' @param verbose Logical scalar. If `TRUE`, emits a short summary.
#'
#' @return A list describing the parsed metadata and intermediate schema.
#'
#' @examples
#' \dontrun{
#' generate_components()
#' generate_components(filter = c("wa-card", "wa_checkbox"))
#' generate_components(emit = FALSE)
#' generate_components(debug = TRUE)
#' }
generate_components <- function(
  root = ".",
  metadata_file = .default_metadata_file(),
  version_file = .default_metadata_version_file(),
  binding_policy_file = .default_binding_policy_file(),
  attribute_policy_file = .default_attribute_policy_file(),
  filter = character(),
  exclude = character(),
  emit = TRUE,
  debug = FALSE,
  verbose = interactive()
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  metadata_path <- .resolve_metadata_path(root, metadata_file)
  .validate_generate_inputs(
    root = root,
    metadata_path = metadata_path,
    metadata_file = metadata_file
  )

  metadata <- .read_component_metadata(metadata_path)
  records <- .component_declaration_records(metadata)
  filter <- .normalize_filter_tokens(filter)
  exclude <- .normalize_filter_tokens(exclude)
  metadata_version <- .read_metadata_version(root, version_file = version_file)
  binding_policy <- .read_binding_override_policy(
    root = root,
    policy_file = binding_policy_file
  )
  attribute_policy <- .read_attribute_override_policy(
    root = root,
    policy_file = attribute_policy_file
  )
  schema <- .build_schema_payload(
    metadata = metadata,
    records = records,
    root = root,
    metadata_file = metadata_file,
    metadata_version = metadata_version,
    binding_policy = binding_policy,
    attribute_policy = attribute_policy,
    filter = filter,
    exclude = exclude
  )

  result <- list(
    root = root,
    metadata_path = .strip_root_prefix(metadata_path, root),
    metadata = schema$metadata,
    binding_policy = schema$binding_policy,
    attribute_policy = schema$attribute_policy,
    schema = schema,
    filter = filter,
    exclude = exclude,
    component_count = schema$summary$component_count
  )

  result$integrity <- list(
    prune_check = .check_prune_integrity(root)
  )

  if (isTRUE(emit)) {
    result$written <- .write_generated_outputs(
      root = root,
      components = schema$components,
      template_root = file.path(root, "tools", "templates")
    )
    result$integrity$generated_record <- .write_generate_integrity(root)
  }

  if (isTRUE(debug)) {
    result$debug <- .write_debug_artifacts(result, root)
  }

  if (isTRUE(verbose)) {
    .emit_generate_summary(result)
  }

  result
}

# Emit a short summary for the generate CLI runner.
.emit_generate_runner_summary <- function(result) {
  summary <- paste0(
    "Generate schema complete: components=",
    result$component_count,
    ", metadata=",
    result$metadata_path
  )

  if (!is.null(result$debug)) {
    summary <- paste0(summary, ", debug=", result$debug$directory)
  }

  if (!is.null(result$written)) {
    summary <- paste0(
      summary,
      ", wrappers=",
      length(result$written$wrappers),
      ", bindings=",
      length(result$written$bindings),
      ", updates=",
      length(result$written$updates)
    )
  }

  message(summary)
}

# Run the generate stage from the command line.
run_generate_components <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_generate_args(args)

  if (isTRUE(options$help)) {
    .print_generate_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(options$verbose)
  .cli_step_start(ui, "Building component schema")

  result <- tryCatch(
    generate_components(
      root = options$root,
      filter = options$filter,
      exclude = options$exclude,
      emit = options$emit,
      debug = options$debug,
      verbose = FALSE
    ),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  .cli_substep_pass(
    ui,
    "Integrity check",
    status = .integrity_cli_status(result$integrity$prune_check$status),
    comment = paste0("[", result$integrity$prune_check$summary, "]")
  )

  .cli_step_finish(ui, status = "Done")
  .emit_generate_runner_summary(result)
  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_generate_components)
}
# nolint end
