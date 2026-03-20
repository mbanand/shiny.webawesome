# Output writing helpers for the generate stage.
# nolint start: object_usage_linter.

# Return the wrapper output directory.
.wrapper_output_dir <- function(root) {
  file.path(root, "R", "generated")
}

# Return the update-function output directory.
.update_output_dir <- function(root) {
  file.path(root, "R", "generated_updates")
}

# Return the binding output directory.
.binding_output_dir <- function(root) {
  file.path(root, "inst", "bindings")
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
      .wrapper_output_dir(root),
      paste0(component$r_function_name, ".R")
    )
    written$wrappers <- c(
      written$wrappers,
      .strip_root_prefix(
        .write_text_file(
          wrapper_path,
          .render_wrapper_file(component, wrapper_template)
        ),
        root
      )
    )

    update_text <- .render_update_file(component, update_template)
    if (!is.null(update_text)) {
      update_path <- file.path(
        .update_output_dir(root),
        paste0("update_", component$r_function_name, ".R")
      )
      written$updates <- c(
        written$updates,
        .strip_root_prefix(.write_text_file(update_path, update_text), root)
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
