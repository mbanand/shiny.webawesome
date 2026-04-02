# Output writing helpers for the generate stage.
# nolint start: object_usage_linter.

# Return the top-level R source directory.
.r_output_dir <- function(root) {
  file.path(root, "R")
}

# Return the binding output directory.
.binding_output_dir <- function(root) {
  file.path(root, "inst", "bindings")
}

# Normalize generated R text before writing.
.normalize_generated_r_text <- function(text) {
  gsub("\n{3,}", "\n\n", text, perl = TRUE)
}

# Write one deterministic text file.
.write_text_file <- function(path, text) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(text), path, useBytes = TRUE)
  invisible(path)
}

# Emit generated wrapper, update, and binding files.
.write_generated_outputs <- function(root, components, template_root) {
  wrapper_template <- file.path(template_root, "wrapper.R.tmpl")
  update_template <- file.path(template_root, "update.R.tmpl")
  binding_template <- file.path(template_root, "binding.js.tmpl")

  written <- list(
    wrappers = character(),
    updates = character(),
    bindings = character()
  )

  for (component in components) {
    wrapper_path <- file.path(
      .r_output_dir(root),
      paste0(component$r_function_name, ".R")
    )
    wrapper_text <- .render_wrapper_file(component, wrapper_template)
    update_text <- .render_update_file(component, update_template)

    if (!is.null(update_text)) {
      wrapper_text <- paste(wrapper_text, update_text, sep = "\n\n")
    }
    wrapper_text <- .normalize_generated_r_text(wrapper_text)

    written$wrappers <- c(
      written$wrappers,
      .strip_root_prefix(
        .write_text_file(
          wrapper_path,
          wrapper_text
        ),
        root
      )
    )

    if (!is.null(update_text)) {
      written$updates <- c(
        written$updates,
        .strip_root_prefix(wrapper_path, root)
      )
    }

    binding_text <- .render_binding_file(component, binding_template)
    if (!is.null(binding_text)) {
      binding_path <- file.path(
        .binding_output_dir(root),
        paste0(component$r_function_name, ".js")
      )
      written$bindings <- c(
        written$bindings,
        .strip_root_prefix(.write_text_file(binding_path, binding_text), root)
      )
    }
  }

  written
}
# nolint end
