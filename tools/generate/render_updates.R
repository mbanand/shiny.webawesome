# Update-function rendering helpers for the generate stage.
# nolint start: object_usage_linter.

# Return whether a component should emit an update helper in this milestone.
.component_has_update <- function(component) {
  component$tag_name %in% c("wa-select")
}

# Render one generated update helper parameter doc block.
.render_update_param_docs <- function(component) {
  switch(component$tag_name,
    "wa-select" = paste(
      c(
        "#' @param value Optional value to send to the component.",
        "#' @param label Optional label text to send to the component.",
        "#' @param hint Optional hint text to send to the component.",
        "#' @param disabled Optional logical disabled state to send to the component."
      ),
      collapse = "\n"
    ),
    stop("No update documentation renderer configured for ", component$tag_name, call. = FALSE)
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
    RDNAME = component$r_function_name
  )

  .render_template(template_path, values)
}
# nolint end
