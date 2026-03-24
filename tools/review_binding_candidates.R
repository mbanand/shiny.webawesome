#!/usr/bin/env Rscript

# Binding-candidate review reporting for the shiny.webawesome generate workflow.
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

.review_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .review_tool_base_dirs
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
  base_dirs <- .review_tool_base_dirs
  helper_files <- c(
    "utils.R",
    "policy.R",
    "metadata.R",
    "schema.R"
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
      "Review helper files do not exist: ",
      paste(helper_files, collapse = ", "),
      call. = FALSE
    )
  }

  for (path in helper_paths) {
    source(path)
  }
}

.bootstrap_cli_ui()
rm(.bootstrap_cli_ui)

# Return the CLI usage string for the binding-candidate review tool.
.review_bind_usage <- function() {
  paste(
    "Usage: ./tools/review_binding_candidates.R",
    "[--root <path>] [--quiet] [--help]"
  )
}

# Return the short CLI description for the binding-candidate review tool.
.review_bind_desc <- function() {
  paste(
    "Review wrapper-only components for possible Shiny binding metadata gaps."
  )
}

# List supported CLI options for the binding-candidate review tool.
.review_bind_option_lines <- function() {
  c(
    paste(
      "--root <path>  Repository root.",
      "Defaults to the current directory."
    ),
    "--quiet        Suppress stage-level progress messages.",
    "--help, -h     Print this help text."
  )
}

# Print the CLI help text for the binding-candidate review tool.
.print_review_bind_help <- function() {
  writeLines(
    c(
      .review_bind_desc(),
      "",
      .review_bind_usage(),
      "",
      "Options:",
      .review_bind_option_lines()
    )
  )
}

# Define default CLI option values for the binding-candidate review tool.
.review_bind_defaults <- function() {
  list(
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the binding-candidate review tool.
.parse_review_bind_args <- function(args) {
  options <- .review_bind_defaults()
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
      paste0(
        "Unknown argument: ",
        arg,
        "\n",
        .review_bind_usage()
      ),
      call. = FALSE
    )
  }

  options
}

# Return the default report path relative to the repository root.
.default_binding_review_report <- function() {
  file.path("report", "review", "binding-candidates.md")
}

# Return the markdown report output path.
.binding_review_report_path <- function(
  root,
  path = .default_binding_review_report()
) {
  file.path(root, path)
}

# Return whether one declaration member looks like a public method.
.is_public_method_member <- function(member) {
  if (!identical(.scalar_string(member$kind, fallback = ""), "method")) {
    return(FALSE)
  }

  if (isTRUE(.or_default(member$static, FALSE))) {
    return(FALSE)
  }

  name <- .scalar_string(member$name, fallback = "")
  if (!nzchar(name) || startsWith(name, "_")) {
    return(FALSE)
  }

  privacy <- .scalar_string(member$privacy, fallback = "")
  !identical(privacy, "private")
}

# Return one declaration member's public method names in deterministic order.
.public_method_names <- function(declaration) {
  members <- .or_default(declaration$members, list())
  methods <- members[vapply(members, .is_public_method_member, logical(1))]

  if (length(methods) == 0L) {
    return(character())
  }

  .sorted_unique(vapply(methods, `[[`, character(1), "name"))
}

# Return one lowercased documentation text blob for heuristic matching.
.declaration_doc_blob <- function(declaration) {
  parts <- c(
    .scalar_string(declaration$summary, fallback = ""),
    .scalar_string(declaration$description, fallback = ""),
    .scalar_string(declaration$jsDoc, fallback = "")
  )

  tolower(paste(parts[nzchar(parts)], collapse = "\n"))
}

# Return one lowercased summary string for compact report output.
.declaration_summary <- function(declaration) {
  .scalar_string(
    .or_default(declaration$summary, declaration$description),
    fallback = ""
  )
}

# Return whether a documentation blob contains interaction-review keywords.
.doc_has_interaction_keywords <- function(doc_blob) {
  grepl(
    "\\b(button|click|trigger|press|submit|activate|toggle)\\b",
    doc_blob,
    perl = TRUE
  )
}

# Return whether a public method list contains one review-interest method.
.has_review_method <- function(method_names) {
  length(intersect(
    method_names,
    c("click", "show", "hide", "toggle", "focus", "blur", "submit", "reset")
  )) > 0L
}

# Return one candidate score from heuristic signals.
.binding_candidate_score <- function(
  wrapper_only,
  method_names,
  event_names,
  doc_blob
) {
  if (!isTRUE(wrapper_only)) {
    return(0L)
  }

  score <- 0L

  if ("click" %in% method_names && !("click" %in% event_names)) {
    score <- score + 3L
  }

  if (.has_review_method(method_names)) {
    score <- score + 1L
  }

  if (.doc_has_interaction_keywords(doc_blob)) {
    score <- score + 1L
  }

  score
}

# Return one candidate reason vector from heuristic signals.
.binding_candidate_reasons <- function(method_names, event_names, doc_blob) {
  reasons <- character()

  if ("click" %in% method_names && !("click" %in% event_names)) {
    reasons <- c(reasons, "public click() method without declared click event")
  }

  review_methods <- intersect(
    method_names,
    c("show", "hide", "toggle", "focus", "blur", "submit", "reset")
  )
  if (length(review_methods) > 0L) {
    reasons <- c(
      reasons,
      paste(
        "interactive public methods:",
        paste(review_methods, collapse = ", ")
      )
    )
  }

  if (.doc_has_interaction_keywords(doc_blob)) {
    reasons <- c(reasons, "docs contain interaction keywords")
  }

  reasons
}

# Build one component review row from schema and raw declaration data.
.binding_review_row <- function(component, declaration) {
  method_names <- .public_method_names(declaration)
  event_names <- vapply(
    component$events %||% list(),
    `[[`,
    character(1),
    "name"
  )
  doc_blob <- .declaration_doc_blob(declaration)
  score <- .binding_candidate_score(
    wrapper_only = !isTRUE(component$classification$binding),
    method_names = method_names,
    event_names = event_names,
    doc_blob = doc_blob
  )

  list(
    tag = component$tag_name,
    classification_mode = component$classification$mode,
    binding_mode = .scalar_string(
      component$classification$binding_mode,
      fallback = "none"
    ),
    binding_source = .scalar_string(
      component$classification$binding_source,
      fallback = "metadata"
    ),
    events = event_names,
    methods = method_names,
    summary = .declaration_summary(declaration),
    score = score,
    reasons = .binding_candidate_reasons(method_names, event_names, doc_blob)
  )
}

# Build review rows keyed by component tag.
.binding_review_rows <- function(schema_components, records) {
  if (length(schema_components) == 0L) {
    return(list())
  }

  declarations_by_tag <- stats::setNames(
    lapply(records, `[[`, "declaration"),
    vapply(
      records,
      function(record) {
        .scalar_string(record$declaration$tagName, fallback = "")
      },
      character(1)
    )
  )

  rows <- lapply(
    schema_components,
    function(component) {
      .binding_review_row(
        component = component,
        declaration = declarations_by_tag[[component$tag_name]]
      )
    }
  )

  names(rows) <- vapply(rows, `[[`, character(1), "tag")
  rows[order(names(rows))]
}

# Return the handled policy override rows.
.handled_binding_overrides <- function(rows) {
  rows[vapply(
    rows,
    function(row) identical(row$binding_source, "policy"),
    logical(1)
  )]
}

# Return unresolved wrapper-only candidates ordered by review score.
.unresolved_binding_candidates <- function(rows) {
  candidates <- rows[vapply(rows, function(row) row$score >= 2L, logical(1))]
  candidates <- candidates[vapply(
    candidates,
    function(row) identical(row$binding_source, "metadata"),
    logical(1)
  )]

  if (length(candidates) == 0L) {
    return(list())
  }

  order_idx <- order(
    -vapply(candidates, `[[`, integer(1), "score"),
    vapply(candidates, `[[`, character(1), "tag")
  )
  candidates[order_idx]
}

# Return one markdown bullet list from character values.
.markdown_list <- function(values, empty = "- None") {
  values <- values[nzchar(values)]

  if (length(values) == 0L) {
    return(empty)
  }

  paste0("- ", values)
}

# Return markdown lines for one handled override row.
.handled_override_section <- function(row) {
  c(
    paste0("### `", row$tag, "`"),
    "",
    paste0("- Current classification: `", row$classification_mode, "`"),
    paste0("- Binding mode: `", row$binding_mode, "`"),
    paste(
      "- Events declared in metadata:",
      paste(row$events, collapse = ", ")
    ),
    paste0("- Public methods: ", paste(row$methods, collapse = ", ")),
    paste0("- Summary: ", if (nzchar(row$summary)) row$summary else "None"),
    paste0("- Why it needed policy: ", paste(row$reasons, collapse = "; ")),
    ""
  )
}

# Return markdown lines for one unresolved candidate row.
.candidate_section <- function(row) {
  c(
    paste0("### `", row$tag, "`"),
    "",
    paste0("- Review score: `", row$score, "`"),
    paste0("- Current classification: `", row$classification_mode, "`"),
    paste0(
      "- Declared events: ",
      if (length(row$events) > 0L) {
        paste(row$events, collapse = ", ")
      } else {
        "None"
      }
    ),
    paste0(
      "- Public methods: ",
      if (length(row$methods) > 0L) {
        paste(row$methods, collapse = ", ")
      } else {
        "None"
      }
    ),
    paste0("- Summary: ", if (nzchar(row$summary)) row$summary else "None"),
    "- Review signals:",
    .markdown_list(row$reasons),
    ""
  )
}

# Write the markdown review report.
.write_binding_review_report <- function(path, result) {
  lines <- c(
    "# Binding Candidate Review",
    "",
    paste0("- Metadata: `", result$metadata_path, "`"),
    paste0("- Source version: `", result$metadata_version, "`"),
    paste0("- Components reviewed: `", result$component_count, "`"),
    paste0(
      "- Explicit binding overrides: `",
      length(result$handled_overrides),
      "`"
    ),
    paste0("- Additional review candidates: `", length(result$candidates), "`"),
    "",
    "This report is advisory. It highlights wrapper-only components whose",
    "metadata and docs suggest that their Shiny interaction contract may merit",
    "manual review for a binding-support override.",
    "",
    "## Explicit Overrides Already Applied",
    ""
  )

  if (length(result$handled_overrides) == 0L) {
    lines <- c(lines, "None.", "")
  } else {
    for (row in result$handled_overrides) {
      lines <- c(lines, .handled_override_section(row))
    }
  }

  lines <- c(lines, "## Additional Candidates To Review", "")

  if (length(result$candidates) == 0L) {
    lines <- c(lines, "None.", "")
  } else {
    for (row in result$candidates) {
      lines <- c(lines, .candidate_section(row))
    }
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(lines), path, useBytes = TRUE)
  invisible(path)
}

# Emit a short summary for one review run.
.emit_binding_review_summary <- function(result) {
  message(
    "Binding review complete: overrides=",
    length(result$handled_overrides),
    ", candidates=",
    length(result$candidates),
    ", report=",
    result$report_path
  )
}

#' Review wrapper-only components for possible binding metadata gaps
#'
#' Reads the copied Web Awesome metadata and the generated component schema,
#' then flags wrapper-only components whose public methods and documentation
#' suggest that their interaction semantics may be underrepresented by metadata.
#' The tool writes a deterministic markdown report under `report/review/`.
#'
#' @param root Repository root directory.
#' @param metadata_file Path to the copied `custom-elements.json` file,
#'   relative to the repository root.
#' @param version_file Path to the copied Web Awesome version file, relative to
#'   the repository root.
#' @param binding_policy_file Path to the handwritten binding-override policy
#'   file, relative to the repository root.
#' @param report_file Output report path, relative to the repository root.
#' @param verbose Logical scalar. If `TRUE`, emits a short summary.
#'
#' @return A list describing the review pass, including handled policy
#'   overrides, unresolved candidates, and the report path.
#'
#' @examples
#' \dontrun{
#' review_binding_candidates()
#' }
review_binding_candidates <- function(
  root = ".",
  metadata_file = .default_metadata_file(),
  version_file = .default_metadata_version_file(),
  binding_policy_file = .default_binding_policy_file(),
  report_file = .default_binding_review_report(),
  verbose = interactive()
) {
  .bootstrap_generate_helpers()
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  metadata_path <- .resolve_metadata_path(root, metadata_file)
  .validate_generate_inputs(
    root = root,
    metadata_path = metadata_path,
    metadata_file = metadata_file
  )

  metadata <- .read_component_metadata(metadata_path)
  metadata_version <- .read_metadata_version(root, version_file = version_file)
  records <- .component_declaration_records(metadata)
  binding_policy <- .read_binding_override_policy(
    root = root,
    policy_file = binding_policy_file
  )
  schema <- .build_schema_payload(
    metadata = metadata,
    records = records,
    root = root,
    metadata_file = metadata_file,
    metadata_version = metadata_version,
    binding_policy = binding_policy
  )

  rows <- .binding_review_rows(schema$components, records)
  handled_overrides <- .handled_binding_overrides(rows)
  candidates <- .unresolved_binding_candidates(rows)
  report_path <- .binding_review_report_path(root, report_file)

  result <- list(
    metadata_path = .strip_root_prefix(metadata_path, root),
    metadata_version = metadata_version,
    component_count = length(rows),
    handled_overrides = handled_overrides,
    candidates = candidates,
    report_path = .strip_root_prefix(
      .write_binding_review_report(report_path, list(
        metadata_path = .strip_root_prefix(metadata_path, root),
        metadata_version = metadata_version,
        component_count = length(rows),
        handled_overrides = handled_overrides,
        candidates = candidates
      )),
      root
    )
  )

  if (isTRUE(verbose)) {
    .emit_binding_review_summary(result)
  }

  result
}

#' Run the binding-candidate review tool from the command line
#'
#' Parses CLI arguments, executes `review_binding_candidates()`, and prints a
#' short summary describing the resulting report and candidate counts.
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the result from `review_binding_candidates()`. If
#'   `--help` or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @rdname review_binding_candidates
#' @describeIn review_binding_candidates Run the binding-candidate review tool
#'   from the command line.
run_review_binding_candidates <- function(
  args = commandArgs(trailingOnly = TRUE)
) {
  options <- .parse_review_bind_args(args)

  if (isTRUE(options$help)) {
    .print_review_bind_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(options$verbose)
  .cli_step_start(ui, "Reviewing binding candidates")

  result <- tryCatch(
    review_binding_candidates(
      root = options$root,
      verbose = FALSE
    ),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  .cli_step_finish(
    ui,
    status = paste0(
      "Done    [report: ",
      result$report_path,
      "]"
    )
  )
  .emit_binding_review_summary(result)
  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_review_binding_candidates)
}
# nolint end
