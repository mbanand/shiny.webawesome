# Update-function rendering helpers for the generate stage.
# nolint start: object_usage_linter.

# Return whether a component should emit an update helper in this milestone.
.component_has_update <- function(component) {
  component$tag_name %in% c("wa-select")
}

# Render one update function file from template.
.render_update_file <- function(component, template_path) {
  if (!.component_has_update(component)) {
    return(NULL)
  }

  values <- c(
    HEADER = .generated_header(),
    FUNCTION_NAME = paste0("update_", component$r_function_name),
    TAG_NAME = component$tag_name
  )

  .render_template(template_path, values)
}
# nolint end
