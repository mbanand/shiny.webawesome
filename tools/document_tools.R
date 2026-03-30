#!/usr/bin/env Rscript

# Tool documentation generation for the shiny.webawesome build pipeline.
#
# This file is sourced by tests and other tool scripts. It is not package
# runtime code.

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

# Return the default set of handwritten tool files to document.
.default_tool_doc_files <- function() {
  c(
    "tools/build_package.R",
    "tools/build_tools.R",
    "tools/check_integrity.R",
    "tools/clean_webawesome.R",
    "tools/document_tools.R",
    "tools/fetch_webawesome.R",
    "tools/prune_webawesome.R",
    "tools/report_components.R",
    "tools/review_binding_candidates.R",
    "tools/test_tools.R"
  )
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

# Validate and normalize the requested tool documentation source files.
.validate_tool_doc_files <- function(files, root) {
  normalized <- file.path(root, files)

  missing <- normalized[!file.exists(normalized)]
  if (length(missing) > 0L) {
    stop(
      "Tool documentation source files do not exist: ",
      paste(.strip_root_prefix(missing, root), collapse = ", "),
      call. = FALSE
    )
  }

  sort(unique(.strip_root_prefix(
    normalizePath(normalized, winslash = "/", mustWork = TRUE),
    root
  )))
}

# List generated documentation artifacts currently present in the output
# directory.
.list_generated_doc_files <- function(output_dir) {
  if (!dir.exists(output_dir)) {
    return(character())
  }

  doc_files <- list.files(
    output_dir,
    pattern = "\\.(Rd|html|txt)$",
    full.names = TRUE
  )

  if (length(doc_files) == 0L) {
    return(character())
  }

  normalizePath(doc_files, winslash = "/", mustWork = TRUE)
}

# Generate and copy documentation artifacts for one handwritten tool file.
.copy_document_artifacts <- function(file, output_dir, root, clean) {
  temp_output_dir <- tempfile("tool-doc-")
  temp_working_dir <- tempfile("tool-doc-work-")
  dir.create(temp_output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(temp_working_dir, recursive = TRUE, showWarnings = FALSE)

  on.exit(unlink(temp_output_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(unlink(temp_working_dir, recursive = TRUE, force = TRUE), add = TRUE)

  logs <- character()
  result <- tryCatch(
    withCallingHandlers(
      {
        output_lines <- utils::capture.output(
          result <- document::document(
            file_name = file.path(root, file),
            output_directory = temp_output_dir,
            working_directory = temp_working_dir,
            check_package = FALSE,
            clean = FALSE,
            debug = FALSE
          ),
          type = "output"
        )
        logs <<- c(logs, output_lines)
        result
      },
      message = function(condition) {
        logs <<- c(logs, conditionMessage(condition))
        invokeRestart("muffleMessage")
      },
      warning = function(condition) {
        logs <<- c(logs, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) {
      detail_lines <- unique(c(conditionMessage(condition), logs))
      stop(paste(detail_lines, collapse = "\n"), call. = FALSE)
    }
  )

  generated <- unique(c(result$html_path, result$txt_path))
  generated <- generated[!is.na(generated) & nzchar(generated)]

  fake_package_dir <- document::get_dpd()
  rd_files <- list.files(
    file.path(fake_package_dir, "man"),
    pattern = "\\.Rd$",
    full.names = TRUE
  )

  generated <- c(generated, rd_files)
  generated <- normalizePath(generated, winslash = "/", mustWork = TRUE)

  if (length(generated) == 0L) {
    stop(
      "No documentation artifacts were generated for ",
      file,
      ".",
      call. = FALSE
    )
  }

  copied_paths <- file.path(output_dir, basename(generated))
  file.copy(generated, copied_paths, overwrite = TRUE)

  if (isTRUE(clean)) {
    unlink(fake_package_dir, recursive = TRUE, force = TRUE)
  }

  basename(copied_paths)
}

# Emit a short summary for a documentation generation run.
.emit_tool_doc_summary <- function(result) {
  if (length(result$generated) > 0L) {
    message("Generated: ", paste(result$generated, collapse = ", "))
  }

  if (length(result$removed) > 0L) {
    message("Removed stale docs: ", paste(result$removed, collapse = ", "))
  }
}

#' Generate documentation for build tools
#'
#' Extracts roxygen documentation from selected handwritten build-tool files and
#' writes the generated artifacts to `tools/man/`. Documentation is generated
#' file-by-file using the `document` package so tool scripts can be documented
#' without moving them into the package `R/` tree.
#'
#' @param files Optional character vector of tool script paths, relative to the
#'   repository root. If `NULL`, documents the standard handwritten tool entry
#'   points.
#' @param output_dir Output directory for generated documentation, relative to
#'   the repository root.
#' @param root Repository root directory.
#' @param clean Logical scalar. Passed through to [document::document()] to
#'   clean its temporary working directory.
#' @param verbose Logical scalar. If `TRUE`, emits a short summary of generated
#'   and removed stale files.
#'
#' @return A list describing the documentation run, including input files,
#'   generated files, and removed files.
#'
#' @examples
#' \dontrun{
#' document_tools()
#' document_tools(files = "tools/clean_webawesome.R")
#' }
document_tools <- function(files = NULL,
                           output_dir = file.path("tools", "man"),
                           root = ".",
                           clean = TRUE,
                           verbose = interactive()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  if (!requireNamespace("document", quietly = TRUE)) {
    stop(
      "The `document` package is required to generate tool docs.",
      call. = FALSE
    )
  }

  if (is.null(files)) {
    files <- .default_tool_doc_files()
  }

  files <- .validate_tool_doc_files(files, root)

  output_dir <- file.path(root, output_dir)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

  existing_docs <- .list_generated_doc_files(output_dir)
  generated_docs <- character()
  ui <- .cli_ui_new()

  .cli_step_start(ui, "Documenting tools")

  tryCatch(
    {
      for (i in seq_along(files)) {
        file <- files[[i]]
        label <- basename(file)
        .cli_step_update(
          ui = ui,
          label = label,
          index = i,
          total = length(files)
        )
        generated_docs <- c(
          generated_docs,
          .copy_document_artifacts(
            file = file,
            output_dir = output_dir,
            root = root,
            clean = clean
          )
        )
        .cli_substep_pass(
          ui = ui,
          label = label,
          index = i,
          total = length(files),
          status = "done"
        )
      }

      generated_paths <- file.path(output_dir, generated_docs)
      stale_docs <- setdiff(existing_docs, generated_paths)

      if (length(stale_docs) > 0L) {
        unlink(stale_docs, force = TRUE)
      }

      result <- list(
        files = files,
        output_dir = output_dir,
        generated = sort(generated_docs),
        removed = sort(basename(stale_docs))
      )
      if (isTRUE(verbose) && !isTRUE(ui$fancy) && FALSE) {
        .emit_tool_doc_summary(result)
      }

      .cli_step_finish(ui, status = "Done")

      result
    },
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )
}

if (sys.nframe() == 0L) {
  .cli_run_main(function() invisible(document_tools()))
}
# nolint end
