#!/usr/bin/env Rscript

# Report stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It produces deterministic manifests and human-readable
# reports describing generated-file integrity, upstream component coverage,
# initial component conformance, and handwritten exported APIs.

# nolint start: object_usage_linter,line_length_linter.
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

.report_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .report_tool_base_dirs
  candidates <- c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "cli_ui.R"))),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "tools", "cli_ui.R"))),
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
  base_dirs <- .report_tool_base_dirs
  helper_files <- c(
    "utils.R",
    "policy.R",
    "metadata.R",
    "schema.R",
    "render_utils.R",
    "render_wrappers.R",
    "render_updates.R",
    "render_bindings.R"
  )

  helper_dir_candidates <- unique(c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "generate"))),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "tools", "generate"))),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "..", "generate"))),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "..", "tools", "generate"))),
    file.path("tools", "generate"),
    "generate"
  ))
  existing_helper_dirs <- helper_dir_candidates[dir.exists(helper_dir_candidates)]

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
      "Report helper files do not exist: ",
      paste(helper_files, collapse = ", "),
      call. = FALSE
    )
  }

  for (path in helper_paths) {
    source(path)
  }
}

.report_helpers_loaded <- FALSE

.bootstrap_cli_ui()
rm(.bootstrap_cli_ui)

# Ensure the shared generate helpers are loaded before report execution.
.ensure_report_helpers <- function() {
  if (isTRUE(.report_helpers_loaded)) {
    return(invisible(TRUE))
  }

  .bootstrap_generate_helpers()
  .report_helpers_loaded <<- TRUE

  invisible(TRUE)
}

# Return the CLI usage string for the report stage.
.report_usage <- function() {
  paste(
    "Usage: ./tools/report_components.R",
    "[--root <path>] [--quiet] [--help]"
  )
}

# Return the short CLI description for the report stage.
.report_description <- function() {
  "Generate manifests and reports for generated-file integrity and API coverage."
}

# List supported CLI options for the report stage.
.report_option_lines <- function() {
  c(
    paste(
      "--root <path>            Repository root.",
      "Defaults to the current directory."
    ),
    "--quiet                  Suppress stage-level progress messages.",
    "--help, -h               Print this help text."
  )
}

# Print the CLI help text for the report stage.
.print_report_help <- function() {
  writeLines(
    c(
      .report_description(),
      "",
      .report_usage(),
      "",
      "Options:",
      .report_option_lines()
    )
  )
}

# Define default CLI option values for the report stage.
.report_defaults <- function() {
  list(
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the report stage.
.parse_report_args <- function(args) {
  options <- .report_defaults()
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
      paste0("Unknown argument: ", arg, "\n", .report_usage()),
      call. = FALSE
    )
  }

  options
}

# Return the default component-coverage policy file relative to the repo root.
.default_cov_policy_file <- function() {
  file.path("dev", "manifests", "component-coverage.policy.yaml")
}

# Return the manifest directory relative to the repo root.
.manifest_dir <- function(root) {
  file.path(root, "manifests")
}

# Return the report directory relative to the repo root.
.report_dir <- function(root) {
  file.path(root, "report")
}

# Return the generated file marker used by the component generator.
.generated_file_marker <- function() {
  "# Generated by tools/generate_components.R. Do not edit by hand."
}

# Return sorted top-level generated R files owned by generate_components().
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
      length(lines) > 0L && identical(lines[[1]], .generated_file_marker())
    },
    logical(1)
  )

  sort(paths[owned])
}

# Return sorted generated binding files.
.generated_binding_files <- function(root) {
  binding_dir <- file.path(root, "inst", "bindings")
  if (!dir.exists(binding_dir)) {
    return(character())
  }

  sort(list.files(binding_dir, pattern = "\\.js$", full.names = TRUE))
}

# Read one handwritten component-coverage policy file when present.
.read_cov_policy <- function(
  root,
  policy_file = .default_cov_policy_file()
) {
  policy_path <- file.path(root, policy_file)

  if (!file.exists(policy_path)) {
    return(list(
      path = policy_file,
      exists = FALSE,
      components = list()
    ))
  }

  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to read component coverage policy files.",
      call. = FALSE
    )
  }

  policy <- yaml::read_yaml(policy_path)
  policy_components <- .or_default(policy$components, list())
  allowed_status <- c("covered", "partial", "planned", "excluded", "unsupported")

  if (length(policy_components) == 0L) {
    return(list(
      path = policy_file,
      exists = TRUE,
      components = list()
    ))
  }

  normalized <- lapply(
    policy_components,
    function(component) {
      tag <- .scalar_string(component$tag, fallback = NA_character_)
      status <- tolower(.scalar_string(component$status, fallback = NA_character_))
      notes <- .scalar_string(component$notes, fallback = NA_character_)

      if (is.na(tag)) {
        stop("Coverage policy entries must include `tag`.", call. = FALSE)
      }

      if (!startsWith(tag, "wa-")) {
        stop(
          "Coverage policy tags must start with `wa-`: ",
          tag,
          call. = FALSE
        )
      }

      if (is.na(status) || !status %in% allowed_status) {
        stop(
          "Unsupported coverage status for ",
          tag,
          ": ",
          status,
          call. = FALSE
        )
      }

      list(
        tag = tag,
        status = status,
        notes = if (is.na(notes)) NULL else notes
      )
    }
  )

  tags <- vapply(normalized, `[[`, character(1), "tag")
  names(normalized) <- tags

  list(
    path = policy_file,
    exists = TRUE,
    components = normalized[order(tags)]
  )
}

# Return all exported symbols from NAMESPACE.
.namespace_exports <- function(root) {
  namespace_path <- file.path(root, "NAMESPACE")
  if (!file.exists(namespace_path)) {
    return(character())
  }

  lines <- readLines(namespace_path, warn = FALSE, encoding = "UTF-8")
  export_lines <- grep("^export\\(", lines, value = TRUE)

  if (length(export_lines) == 0L) {
    return(character())
  }

  exports <- sub("^export\\(([^)]+)\\)$", "\\1", export_lines)
  .sorted_unique(exports)
}

# Return whether one file contains a function definition for one name.
.file_defines_function <- function(path, name) {
  pattern <- paste0("^", gsub("([.])", "\\\\\\1", name), "\\s*<-\\s*function\\s*\\(")
  any(grepl(pattern, readLines(path, warn = FALSE, encoding = "UTF-8"), perl = TRUE))
}

# Find package R files that define one function name.
.find_function_source_files <- function(root, name) {
  r_dir <- file.path(root, "R")
  if (!dir.exists(r_dir)) {
    return(character())
  }

  paths <- sort(list.files(r_dir, pattern = "\\.[Rr]$", full.names = TRUE))
  matches <- paths[vapply(paths, .file_defines_function, logical(1), name = name)]
  .strip_root_prefix(matches, root)
}

# Return one relative path for one expected wrapper file.
.expected_wrapper_path <- function(component) {
  file.path("R", paste0(component$r_function_name, ".R"))
}

# Return one relative path for one expected binding file.
.expected_binding_path <- function(component) {
  file.path("inst", "bindings", paste0(component$r_function_name, ".js"))
}

# Return whether one relative path exists under the repository root.
.path_exists <- function(root, relative_path) {
  file.exists(file.path(root, relative_path))
}

# Return whether one wrapper function exists in its expected file.
.wrapper_function_exists <- function(root, component) {
  path <- file.path(root, .expected_wrapper_path(component))
  file.exists(path) && .file_defines_function(path, component$r_function_name)
}

# Return whether one update function exists in the wrapper file.
.update_function_exists <- function(root, component) {
  if (!isTRUE(component$classification$update)) {
    return(FALSE)
  }

  update_name <- paste0("update_", component$r_function_name)
  path <- file.path(root, .expected_wrapper_path(component))
  file.exists(path) && .file_defines_function(path, update_name)
}

# Return one default inferred coverage status from discovered artifacts.
.infer_component_status <- function(component, wrapper_exists, binding_exists, update_exists) {
  if (!wrapper_exists) {
    return("unsupported")
  }

  if (isTRUE(component$classification$binding) && !binding_exists) {
    return("partial")
  }

  if (isTRUE(component$classification$update) && !update_exists) {
    return("partial")
  }

  "covered"
}

# Return one component coverage entry from schema and observed artifacts.
.component_coverage_entry <- function(root, component, coverage_policy = list()) {
  wrapper_path <- .expected_wrapper_path(component)
  binding_path <- .expected_binding_path(component)
  wrapper_exists <- .wrapper_function_exists(root, component)
  update_exists <- .update_function_exists(root, component)
  binding_exists <- isTRUE(component$classification$binding) &&
    .path_exists(root, binding_path)

  inferred_status <- .infer_component_status(
    component = component,
    wrapper_exists = wrapper_exists,
    binding_exists = binding_exists,
    update_exists = update_exists
  )

  policy_entry <- coverage_policy[[component$tag_name]]
  status <- if (is.null(policy_entry)) inferred_status else policy_entry$status
  notes <- if (is.null(policy_entry)) NULL else policy_entry$notes

  list(
    tag = component$tag_name,
    component_name = component$component_name,
    status = status,
    inferred_status = inferred_status,
    notes = notes,
    r_function = list(
      name = component$r_function_name,
      path = wrapper_path,
      exists = wrapper_exists
    ),
    update_function = list(
      name = paste0("update_", component$r_function_name),
      expected = isTRUE(component$classification$update),
      exists = update_exists
    ),
    binding = list(
      name = component$tag_name,
      mode = component$classification$binding_mode,
      expected = isTRUE(component$classification$binding),
      path = binding_path,
      exists = binding_exists
    )
  )
}

# Return one generated-file manifest entry for one expected path.
.generated_file_entry <- function(root, path, file_type, tag = NA_character_) {
  list(
    path = path,
    type = file_type,
    component_tag = tag,
    exists = .path_exists(root, path)
  )
}

# Build the generated-file manifest payload.
.build_generated_file_manifest <- function(root, schema) {
  expected_wrapper_entries <- lapply(
    schema$components,
    function(component) {
      .generated_file_entry(
        root = root,
        path = .expected_wrapper_path(component),
        file_type = "wrapper",
        tag = component$tag_name
      )
    }
  )
  expected_binding_entries <- lapply(
    schema$components[vapply(schema$components, function(comp) comp$classification$binding, logical(1))],
    function(component) {
      .generated_file_entry(
        root = root,
        path = .expected_binding_path(component),
        file_type = "binding",
        tag = component$tag_name
      )
    }
  )

  expected_files <- c(expected_wrapper_entries, expected_binding_entries)
  expected_paths <- vapply(expected_files, `[[`, character(1), "path")
  actual_paths <- c(
    .strip_root_prefix(.generated_r_files(root), root),
    .strip_root_prefix(.generated_binding_files(root), root)
  )
  unexpected_paths <- sort(setdiff(actual_paths, expected_paths))

  list(
    schema_version = 1L,
    manifest_type = "generated_file_manifest",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    upstream = list(
      source_file = schema$metadata$path,
      source_version = schema$metadata$source_version
    ),
    summary = list(
      expected = length(expected_files),
      present = sum(vapply(expected_files, `[[`, logical(1), "exists")),
      missing = sum(!vapply(expected_files, `[[`, logical(1), "exists")),
      unexpected = length(unexpected_paths)
    ),
    files = expected_files,
    unexpected_files = lapply(
      unexpected_paths,
      function(path) list(path = path)
    )
  )
}

# Build the component-coverage manifest payload.
.build_cov_manifest <- function(root, schema, coverage_policy) {
  components <- lapply(
    schema$components,
    .component_coverage_entry,
    root = root,
    coverage_policy = coverage_policy$components
  )
  status_values <- vapply(components, `[[`, character(1), "status")

  list(
    schema_version = 1L,
    manifest_type = "component_coverage",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    upstream = list(
      source_file = schema$metadata$path,
      source_version = schema$metadata$source_version
    ),
    policy = list(
      path = coverage_policy$path,
      exists = isTRUE(coverage_policy$exists),
      component_count = length(.or_default(coverage_policy$components, list()))
    ),
    summary = list(
      total_components = length(components),
      covered = sum(status_values == "covered"),
      partial = sum(status_values == "partial"),
      planned = sum(status_values == "planned"),
      excluded = sum(status_values == "excluded"),
      unsupported = sum(status_values == "unsupported")
    ),
    components = components
  )
}

# Build the manual exported API inventory payload.
.build_manual_api_inventory <- function(root, schema) {
  exports <- .namespace_exports(root)
  generated_exports <- c(
    vapply(schema$components, `[[`, character(1), "r_function_name"),
    paste0(
      "update_",
      vapply(
        schema$components[vapply(schema$components, function(comp) comp$classification$update, logical(1))],
        `[[`,
        character(1),
        "r_function_name"
      )
    )
  )
  manual_exports <- sort(setdiff(exports, generated_exports))

  list(
    schema_version = 1L,
    manifest_type = "manual_api_inventory",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    summary = list(
      total_exports = length(exports),
      generated_exports = length(intersect(exports, generated_exports)),
      manual_exports = length(manual_exports)
    ),
    exports = lapply(
      manual_exports,
      function(name) {
        source_files <- .find_function_source_files(root, name)
        list(
          name = name,
          kind = "manual_export",
          source_files = if (length(source_files) == 0L) NULL else source_files
        )
      }
    )
  )
}

# Return expected wrapper argument names for one component.
.expected_wrapper_args <- function(component) {
  args <- if (.wrapper_uses_input_id(component)) {
    c("input_id", "...")
  } else if (.wrapper_uses_id(component)) {
    c("...", "id")
  } else {
    "..."
  }

  attr_args <- vapply(.wrapper_attributes(component), `[[`, character(1), "argument_name")
  slot_args <- vapply(
    .wrapper_slots(component),
    `[[`,
    character(1),
    "wrapper_argument_name"
  )

  c(args, attr_args, slot_args)
}

# Return expected update helper argument names for one component.
.expected_update_args <- function(component) {
  if (!isTRUE(component$classification$update)) {
    return(character())
  }

  c("session", "input_id", .update_message_fields(component))
}

# Return one vector of R function argument names parsed from source.
.function_args_from_file <- function(path, name) {
  if (!file.exists(path)) {
    return(character())
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start_idx <- grep(
    paste0("^", gsub("([.])", "\\\\\\1", name), "\\s*<-\\s*function\\s*\\("),
    lines,
    perl = TRUE
  )

  if (length(start_idx) == 0L) {
    return(character())
  }

  collected <- character()
  depth <- 0L
  opened <- FALSE

  for (line in lines[start_idx[[1]]:length(lines)]) {
    collected <- c(collected, line)
    chars <- strsplit(line, "", fixed = TRUE)[[1]]

    for (char in chars) {
      if (identical(char, "(")) {
        depth <- depth + 1L
        opened <- TRUE
      } else if (identical(char, ")")) {
        depth <- depth - 1L
        if (opened && depth == 0L) {
          break
        }
      }
    }

    if (opened && depth == 0L) {
      break
    }
  }

  signature_text <- paste(collected, collapse = "\n")
  args_text <- sub(".*?function\\s*\\(", "", signature_text, perl = TRUE)
  args_text <- sub("\\).*?$", "", args_text, perl = TRUE)
  pieces <- trimws(unlist(strsplit(args_text, ",", fixed = TRUE)))
  pieces <- pieces[nzchar(pieces)]
  names <- sub("\\s*=.*$", "", pieces, perl = TRUE)
  names <- trimws(gsub("`", "", names, fixed = TRUE))
  names
}

# Return one parsed vector of binding subscription events from JS source.
.binding_events_from_file <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  event_line <- grep(
    "el\\.__shinyWebawesomeEvents\\s*=\\s*\\[[^]]*\\];",
    lines,
    value = TRUE
  )

  if (length(event_line) == 0L) {
    return(character())
  }

  event_text <- sub("^.*\\[", "", event_line[[1]])
  event_text <- sub("\\].*$", "", event_text)
  events <- trimws(unlist(strsplit(event_text, ",", fixed = TRUE)))
  events <- gsub("^\"|\"$", "", events)
  events[nzchar(events)]
}

# Return one parsed binding registration name from JS source.
.binding_name_from_file <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  line <- grep("Shiny\\.inputBindings\\.register\\(binding,", lines, value = TRUE)

  if (length(line) == 0L) {
    return(NA_character_)
  }

  sub("^.*register\\(binding,\\s*'([^']+)'\\);.*$", "\\1", line[[1]], perl = TRUE)
}

# Return one parsed binding selector from JS source.
.binding_selector_from_file <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  line <- grep("\\$\\(scope\\)\\.find\\('", lines, value = TRUE)

  if (length(line) == 0L) {
    return(NA_character_)
  }

  sub("^.*find\\('([^']+)'\\);.*$", "\\1", line[[1]], perl = TRUE)
}

# Return whether one file contains one literal snippet.
.file_contains <- function(path, snippet) {
  file.exists(path) &&
    grepl(snippet, paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"), fixed = TRUE)
}

# Return one conformance vector of missing expected items.
.missing_expected_items <- function(expected, actual) {
  sort(setdiff(expected, actual))
}

# Return one conformance vector of unexpected extra items.
.unexpected_items <- function(expected, actual) {
  sort(setdiff(actual, expected))
}

# Return one detailed wrapper conformance payload.
.wrapper_conformance <- function(root, component, exported_names) {
  path <- file.path(root, .expected_wrapper_path(component))
  expected_args <- .expected_wrapper_args(component)
  actual_args <- .function_args_from_file(path, component$r_function_name)

  list(
    name = component$r_function_name,
    exists = file.exists(path),
    exported = component$r_function_name %in% exported_names,
    expected_args = expected_args,
    actual_args = if (length(actual_args) == 0L) NULL else actual_args,
    missing_args = .missing_expected_items(expected_args, actual_args),
    unexpected_args = .unexpected_items(expected_args, actual_args),
    args_match = identical(expected_args, actual_args)
  )
}

# Return one detailed update-function conformance payload.
.update_conformance <- function(root, component, exported_names) {
  update_name <- paste0("update_", component$r_function_name)
  path <- file.path(root, .expected_wrapper_path(component))
  expected_args <- .expected_update_args(component)
  actual_args <- .function_args_from_file(path, update_name)
  expected <- isTRUE(component$classification$update)

  list(
    name = update_name,
    expected = expected,
    exists = length(actual_args) > 0L,
    exported = update_name %in% exported_names,
    expected_args = if (length(expected_args) == 0L) NULL else expected_args,
    actual_args = if (length(actual_args) == 0L) NULL else actual_args,
    missing_args = if (!expected) character() else .missing_expected_items(expected_args, actual_args),
    unexpected_args = if (!expected) actual_args else .unexpected_items(expected_args, actual_args),
    args_match = if (!expected) length(actual_args) == 0L else identical(expected_args, actual_args)
  )
}

# Return one detailed binding conformance payload.
.binding_conformance <- function(root, component) {
  expected <- isTRUE(component$classification$binding)
  path <- file.path(root, .expected_binding_path(component))
  actual_events <- .binding_events_from_file(path)
  expected_events <- if (expected) .binding_subscribe_events(component) else character()

  mode <- .scalar_string(component$classification$binding_mode, fallback = "none")
  selector_expected <- .binding_selector(component)
  name_expected <- .binding_name(component)

  mode_checks <- list(
    action_type = if (mode %in% c("action", "action_with_payload")) {
      .file_contains(path, "return \"shiny.action\";")
    } else {
      TRUE
    },
    semantic_receive_message = if (identical(mode, "semantic")) {
      .file_contains(path, "return;")
    } else {
      TRUE
    },
    action_payload_side_channel = if (identical(mode, "action_with_payload")) {
      .file_contains(path, "Shiny.setInputValue(el.id + \"_value\"")
    } else {
      TRUE
    }
  )

  list(
    expected = expected,
    mode = mode,
    exists = file.exists(path),
    selector_expected = if (!expected) NULL else selector_expected,
    selector_actual = if (!expected) NULL else .binding_selector_from_file(path),
    selector_match = if (!expected) !file.exists(path) else identical(.binding_selector_from_file(path), selector_expected),
    name_expected = if (!expected) NULL else name_expected,
    name_actual = if (!expected) NULL else .binding_name_from_file(path),
    name_match = if (!expected) !file.exists(path) else identical(.binding_name_from_file(path), name_expected),
    expected_events = if (length(expected_events) == 0L) NULL else expected_events,
    actual_events = if (length(actual_events) == 0L) NULL else actual_events,
    missing_events = if (!expected) character() else .missing_expected_items(expected_events, actual_events),
    unexpected_events = if (!expected) actual_events else .unexpected_items(expected_events, actual_events),
    events_match = if (!expected) !file.exists(path) else identical(expected_events, actual_events),
    mode_checks = mode_checks
  )
}

# Build the deeper component API conformance payload.
.build_conformance_manifest <- function(root, schema) {
  exported_names <- .namespace_exports(root)
  components <- lapply(
    schema$components,
    function(component) {
      wrapper <- .wrapper_conformance(root, component, exported_names)
      binding <- .binding_conformance(root, component)
      update_function <- .update_conformance(root, component, exported_names)

      status <- if (
        isTRUE(wrapper$exists) &&
          isTRUE(wrapper$exported) &&
          isTRUE(wrapper$args_match) &&
          isTRUE(binding$selector_match) &&
          isTRUE(binding$name_match) &&
          isTRUE(binding$events_match) &&
          all(vapply(binding$mode_checks, isTRUE, logical(1))) &&
          (
            !isTRUE(update_function$expected) ||
              (
                isTRUE(update_function$exists) &&
                  isTRUE(update_function$exported) &&
                  isTRUE(update_function$args_match)
              )
          )
      ) {
        "conformant"
      } else {
        "nonconformant"
      }

      list(
        tag = component$tag_name,
        component_name = component$component_name,
        status = status,
        wrapper = wrapper,
        binding = binding,
        update_function = update_function
      )
    }
  )

  statuses <- vapply(components, `[[`, character(1), "status")

  list(
    schema_version = 1L,
    manifest_type = "component_api_conformance",
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    upstream = list(
      source_file = schema$metadata$path,
      source_version = schema$metadata$source_version
    ),
    summary = list(
      total_components = length(components),
      conformant = sum(statuses == "conformant"),
      nonconformant = sum(statuses == "nonconformant")
    ),
    components = components
  )
}

# Write one deterministic text file.
.write_text_file <- function(path, text) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(text), path, useBytes = TRUE)
  invisible(path)
}

# Write one deterministic YAML file.
.write_yaml_file <- function(path, object) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to write report manifests.",
      call. = FALSE
    )
  }

  .write_text_file(
    path,
    yaml::as.yaml(object, indent.mapping.sequence = TRUE, line.sep = "\n")
  )
}

# Return summary lines for the generated-file report.
.generated_file_report_lines <- function(manifest) {
  missing <- manifest$files[!vapply(manifest$files, `[[`, logical(1), "exists")]
  unexpected <- .or_default(manifest$unexpected_files, list())

  c(
    "# Generated File Integrity",
    "",
    paste0("- Expected files: ", manifest$summary$expected),
    paste0("- Present expected files: ", manifest$summary$present),
    paste0("- Missing expected files: ", manifest$summary$missing),
    paste0("- Unexpected generated files: ", manifest$summary$unexpected),
    "",
    "## Missing Expected Files",
    "",
    if (length(missing) == 0L) {
      "- None."
    } else {
      vapply(missing, function(entry) paste0("- `", entry$path, "`"), character(1))
    },
    "",
    "## Unexpected Generated Files",
    "",
    if (length(unexpected) == 0L) {
      "- None."
    } else {
      vapply(unexpected, function(entry) paste0("- `", entry$path, "`"), character(1))
    }
  )
}

# Return summary lines for the component-coverage report.
.coverage_report_lines <- function(manifest) {
  problematic <- manifest$components[
    vapply(manifest$components, function(entry) entry$status != "covered", logical(1))
  ]

  c(
    "# Component Coverage",
    "",
    paste0("- Total components: ", manifest$summary$total_components),
    paste0("- Covered: ", manifest$summary$covered),
    paste0("- Partial: ", manifest$summary$partial),
    paste0("- Planned: ", manifest$summary$planned),
    paste0("- Excluded: ", manifest$summary$excluded),
    paste0("- Unsupported: ", manifest$summary$unsupported),
    "",
    "## Non-covered Components",
    "",
    if (length(problematic) == 0L) {
      "- None."
    } else {
      vapply(
        problematic,
        function(entry) {
          note <- if (is.na(entry$notes)) "" else paste0(" - ", entry$notes)
          paste0("- `", entry$tag, "`: ", entry$status, note)
        },
        character(1)
      )
    }
  )
}

# Return summary lines for the manual API inventory report.
.manual_api_report_lines <- function(manifest) {
  exports <- .or_default(manifest$exports, list())

  c(
    "# Manual API Inventory",
    "",
    paste0("- Total exports: ", manifest$summary$total_exports),
    paste0("- Generated exports: ", manifest$summary$generated_exports),
    paste0("- Manual exports: ", manifest$summary$manual_exports),
    "",
    "## Manual Exports",
    "",
    if (length(exports) == 0L) {
      "- None."
    } else {
      vapply(
        exports,
        function(entry) {
          sources <- .or_default(entry$source_files, character())
          source_text <- if (length(sources) == 0L) {
            ""
          } else {
            paste0(" (", paste(sources, collapse = ", "), ")")
          }
          paste0("- `", entry$name, "`", source_text)
        },
        character(1)
      )
    }
  )
}

# Return summary lines for the component API conformance report.
.conformance_report_lines <- function(manifest) {
  problematic <- manifest$components[
    vapply(manifest$components, function(entry) entry$status != "conformant", logical(1))
  ]

  c(
    "# Component API Conformance",
    "",
    paste0("- Total components: ", manifest$summary$total_components),
    paste0("- Conformant: ", manifest$summary$conformant),
    paste0("- Nonconformant: ", manifest$summary$nonconformant),
    "",
    "## Nonconformant Components",
    "",
    if (length(problematic) == 0L) {
      "- None."
    } else {
      vapply(
        problematic,
        function(entry) {
          wrapper_missing <- .or_default(entry$wrapper$missing_args, character())
          wrapper_extra <- .or_default(entry$wrapper$unexpected_args, character())
          binding_missing <- .or_default(entry$binding$missing_events, character())
          binding_extra <- .or_default(entry$binding$unexpected_events, character())
          update_missing <- .or_default(entry$update_function$missing_args, character())
          update_extra <- .or_default(entry$update_function$unexpected_args, character())
          mode_failures <- names(entry$binding$mode_checks)[
            !vapply(entry$binding$mode_checks, isTRUE, logical(1))
          ]

          paste0(
            "- `", entry$tag, "`",
            ": wrapper_exists=", tolower(as.character(entry$wrapper$exists)),
            ", wrapper_exported=", tolower(as.character(entry$wrapper$exported)),
            ", wrapper_args_match=", tolower(as.character(entry$wrapper$args_match)),
            ", wrapper_missing_args=",
            if (length(wrapper_missing) == 0L) "none" else paste(wrapper_missing, collapse = "|"),
            ", wrapper_unexpected_args=",
            if (length(wrapper_extra) == 0L) "none" else paste(wrapper_extra, collapse = "|"),
            ", binding_expected=", tolower(as.character(entry$binding$expected)),
            ", binding_exists=", tolower(as.character(entry$binding$exists)),
            ", binding_selector_match=", tolower(as.character(entry$binding$selector_match)),
            ", binding_name_match=", tolower(as.character(entry$binding$name_match)),
            ", binding_events_match=", tolower(as.character(entry$binding$events_match)),
            ", binding_missing_events=",
            if (length(binding_missing) == 0L) "none" else paste(binding_missing, collapse = "|"),
            ", binding_unexpected_events=",
            if (length(binding_extra) == 0L) "none" else paste(binding_extra, collapse = "|"),
            ", binding_mode_failures=",
            if (length(mode_failures) == 0L) "none" else paste(mode_failures, collapse = "|"),
            ", update_expected=", tolower(as.character(entry$update_function$expected)),
            ", update_exists=", tolower(as.character(entry$update_function$exists)),
            ", update_exported=", tolower(as.character(entry$update_function$exported)),
            ", update_args_match=", tolower(as.character(entry$update_function$args_match)),
            ", update_missing_args=",
            if (length(update_missing) == 0L) "none" else paste(update_missing, collapse = "|"),
            ", update_unexpected_args=",
            if (length(update_extra) == 0L) "none" else paste(update_extra, collapse = "|")
          )
        },
        character(1)
      )
    }
  )
}

# Return summary lines for the top-level report summary.
.report_summary_lines <- function(result) {
  c(
    "# Report Summary",
    "",
    paste0("- Upstream metadata: `", result$schema$metadata$path, "`"),
    paste0("- Upstream version: `", result$schema$metadata$source_version, "`"),
    paste0("- Components analyzed: ", result$schema$summary$component_count),
    paste0("- Generated files missing: ", result$generated_file_manifest$summary$missing),
    paste0("- Generated files unexpected: ", result$generated_file_manifest$summary$unexpected),
    paste0("- Components covered: ", result$component_coverage_manifest$summary$covered),
    paste0("- Components partial: ", result$component_coverage_manifest$summary$partial),
    paste0("- Components unsupported: ", result$component_coverage_manifest$summary$unsupported),
    paste0("- Manual exports: ", result$manual_api_inventory$summary$manual_exports),
    paste0("- Component conformance failures: ", result$component_api_conformance$summary$nonconformant)
  )
}

# Emit a short summary for a programmatic report result.
.emit_report_summary <- function(result) {
  message(
    "Report complete: components=",
    result$schema$summary$component_count,
    ", manifests=",
    length(result$written$manifests),
    ", reports=",
    length(result$written$reports)
  )
}

#' Generate manifests and reports for the current generated component surface
#'
#' Builds deterministic manifest and markdown report artifacts describing the
#' current generated-file integrity, upstream component coverage, initial
#' component API conformance, and handwritten exported package APIs.
#'
#' @param root Repository root directory.
#' @param metadata_file Path to the copied `custom-elements.json` file,
#'   relative to the repository root.
#' @param version_file Path to the copied Web Awesome version file, relative to
#'   the repository root.
#' @param binding_policy_file Path to the handwritten binding-override policy
#'   file, relative to the repository root.
#' @param coverage_policy_file Path to the handwritten component-coverage policy
#'   file, relative to the repository root.
#' @param verbose Logical scalar. If `TRUE`, emits a short summary.
#'
#' @return A list describing the generated manifests, reports, and the schema
#'   surface used to compute them.
#'
#' @examples
#' \dontrun{
#' report_components()
#' }
report_components <- function(
  root = ".",
  metadata_file = .default_metadata_file(),
  version_file = .default_metadata_version_file(),
  binding_policy_file = .default_binding_policy_file(),
  coverage_policy_file = .default_cov_policy_file(),
  verbose = interactive()
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  .ensure_report_helpers()
  metadata_path <- .resolve_metadata_path(root, metadata_file)
  .validate_generate_inputs(
    root = root,
    metadata_path = metadata_path,
    metadata_file = metadata_file
  )

  metadata <- .read_component_metadata(metadata_path)
  records <- .component_declaration_records(metadata)
  metadata_version <- .read_metadata_version(root, version_file = version_file)
  binding_policy <- .read_binding_override_policy(
    root = root,
    policy_file = binding_policy_file
  )
  coverage_policy <- .read_cov_policy(
    root = root,
    policy_file = coverage_policy_file
  )
  schema <- .build_schema_payload(
    metadata = metadata,
    records = records,
    root = root,
    metadata_file = metadata_file,
    metadata_version = metadata_version,
    binding_policy = binding_policy,
    filter = character(),
    exclude = character()
  )

  generated_file_manifest <- .build_generated_file_manifest(root, schema)
  component_coverage_manifest <- .build_cov_manifest(
    root = root,
    schema = schema,
    coverage_policy = coverage_policy
  )
  manual_api_inventory <- .build_manual_api_inventory(root, schema)
  component_api_conformance <- .build_conformance_manifest(root, schema)

  manifest_paths <- list(
    generated_file_manifest = file.path(.manifest_dir(root), "generated-file-manifest.yaml"),
    component_coverage = file.path(.manifest_dir(root), "component-coverage.yaml"),
    component_api_conformance = file.path(.manifest_dir(root), "component-api-conformance.yaml"),
    manual_api_inventory = file.path(.manifest_dir(root), "manual-api-inventory.yaml")
  )
  report_paths <- list(
    summary = file.path(.report_dir(root), "summary.md"),
    generated_files = file.path(.report_dir(root), "generated-files.md"),
    component_coverage = file.path(.report_dir(root), "component-coverage.md"),
    component_api_conformance = file.path(.report_dir(root), "component-api-conformance.md"),
    manual_api_inventory = file.path(.report_dir(root), "manual-api-inventory.md")
  )

  .write_yaml_file(
    manifest_paths$generated_file_manifest,
    generated_file_manifest
  )
  .write_yaml_file(
    manifest_paths$component_coverage,
    component_coverage_manifest
  )
  .write_yaml_file(
    manifest_paths$component_api_conformance,
    component_api_conformance
  )
  .write_yaml_file(
    manifest_paths$manual_api_inventory,
    manual_api_inventory
  )

  result <- list(
    root = root,
    schema = schema,
    binding_policy = binding_policy,
    coverage_policy = coverage_policy,
    generated_file_manifest = generated_file_manifest,
    component_coverage_manifest = component_coverage_manifest,
    component_api_conformance = component_api_conformance,
    manual_api_inventory = manual_api_inventory
  )

  .write_text_file(report_paths$summary, .report_summary_lines(result))
  .write_text_file(
    report_paths$generated_files,
    .generated_file_report_lines(generated_file_manifest)
  )
  .write_text_file(
    report_paths$component_coverage,
    .coverage_report_lines(component_coverage_manifest)
  )
  .write_text_file(
    report_paths$component_api_conformance,
    .conformance_report_lines(component_api_conformance)
  )
  .write_text_file(
    report_paths$manual_api_inventory,
    .manual_api_report_lines(manual_api_inventory)
  )

  result$written <- list(
    manifests = .strip_root_prefix(unlist(manifest_paths, use.names = FALSE), root),
    reports = .strip_root_prefix(unlist(report_paths, use.names = FALSE), root)
  )

  if (isTRUE(verbose)) {
    .emit_report_summary(result)
  }

  result
}

# Emit a short summary for the report CLI runner.
.emit_report_runner_summary <- function(result) {
  message(
    "Report stage complete: components=",
    result$schema$summary$component_count,
    ", covered=",
    result$component_coverage_manifest$summary$covered,
    ", partial=",
    result$component_coverage_manifest$summary$partial,
    ", planned=",
    result$component_coverage_manifest$summary$planned,
    ", excluded=",
    result$component_coverage_manifest$summary$excluded,
    ", unsupported=",
    result$component_coverage_manifest$summary$unsupported,
    ", conformance_failures=",
    result$component_api_conformance$summary$nonconformant
  )
}

#' Run the report stage from the command line
#'
#' Parses CLI arguments, executes `report_components()`, and prints a short
#' status summary for the emitted manifests and reports.
#'
#' @rdname report_components
#' @describeIn report_components Run the report stage from the command line.
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the result from `report_components()`. If `--help`
#'   or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_report_components()
#' run_report_components("--help")
#' }
run_report_components <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_report_args(args)

  if (isTRUE(options$help)) {
    .print_report_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(options$verbose)
  .cli_step_start(ui, "Generating reports")

  result <- tryCatch(
    report_components(
      root = options$root,
      verbose = FALSE
    ),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      stop(condition)
    }
  )

  .cli_step_finish(ui, status = "Done")

  if (isTRUE(options$verbose)) {
    .emit_report_runner_summary(result)
  }

  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_report_components)
}
# nolint end
