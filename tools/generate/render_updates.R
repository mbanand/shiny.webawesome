# Update-function rendering helpers for the generate stage.
# nolint start: object_usage_linter.

# Return whether a component should emit an update helper.
.component_has_update <- function(component) {
  isTRUE(component$classification$update)
}

# Return supported update message field names for one component.
.update_message_fields <- function(component) {
  supported <- c("value", "label", "hint", "disabled")
  available <- unique(c(
    vapply(component$attributes %||% list(), `[[`, character(1), "name"),
    vapply(component$properties %||% list(), `[[`, character(1), "name")
  ))

  supported[supported %in% available]
}

# Return one generated update helper parameter documentation block.
.render_update_param_docs <- function(component) {
  docs <- vapply(
    .update_message_fields(component),
    function(field) {
      description <- switch(field,
        "value" = "Optional value to send to the component.",
        "label" = "Optional label text to send to the component.",
        "hint" = "Optional hint text to send to the component.",
        "disabled" = paste(
          "Optional logical disabled state to send to the component."
        ),
        stop(
          "No update documentation renderer configured for field ",
          field,
          call. = FALSE
        )
      )

      paste0("#' @param ", field, " ", description)
    },
    character(1)
  )

  paste(docs, collapse = "\n")
}

# Render one update helper parameter signature fragment.
.render_update_signature <- function(component) {
  fields <- .update_message_fields(component)

  if (length(fields) == 0L) {
    return("")
  }

  paste0(
    ",\n",
    paste0("  ", fields, " = NULL", collapse = ",\n")
  )
}

# Render one update helper message field block.
.render_update_message_fields <- function(component) {
  fields <- .update_message_fields(component)

  paste(
    paste0("      ", fields, " = ", fields),
    collapse = ",\n"
  )
}

# Render one update function file from template.
.render_update_file <- function(component, template_path) {
  if (!.component_has_update(component)) {
    return(NULL)
  }

  values <- c(
    HEADER = .generated_header(),
    FUNCTION_NAME = paste0("update_", component$r_function_name),
    TAG_NAME = component$tag_name,
    PARAM_DOCS = .render_update_param_docs(component),
    PARAM_SIGNATURE = .render_update_signature(component),
    MESSAGE_FIELDS = .render_update_message_fields(component),
    RDNAME = component$r_function_name
  )

  .render_template(template_path, values)
}
# nolint end
