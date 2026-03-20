# Binding rendering helpers for the generate stage.
# nolint start: object_usage_linter,line_length_linter.

# Return whether a component should emit a Shiny binding in this milestone.
.component_has_binding <- function(component) {
  component$tag_name %in% c("wa-checkbox", "wa-select")
}

# Render JS binding behavior values for one component.
.binding_values <- function(component) {
  switch(component$tag_name,
    "wa-checkbox" = c(
      FIND_SELECTOR = "wa-checkbox[id]",
      BINDING_NAME = "shiny.webawesome.waCheckbox",
      GET_VALUE = "return !!el.checked;",
      SET_VALUE = paste(
        "if (Object.prototype.hasOwnProperty.call(data, \"value\")) {",
        "  el.checked = !!data.value;",
        "}",
        sep = "\n    "
      ),
      SUBSCRIBE_EVENT = "change"
    ),
    "wa-select" = c(
      FIND_SELECTOR = "wa-select[id]",
      BINDING_NAME = "shiny.webawesome.waSelect",
      GET_VALUE = paste(
        "if (el.multiple && Array.isArray(el.value)) {",
        "  return el.value;",
        "}",
        "return el.value;",
        sep = "\n    "
      ),
      SET_VALUE = paste(
        "if (Object.prototype.hasOwnProperty.call(data, \"value\")) { el.value = data.value; }",
        "if (Object.prototype.hasOwnProperty.call(data, \"label\")) { el.label = data.label; }",
        "if (Object.prototype.hasOwnProperty.call(data, \"hint\")) { el.hint = data.hint; }",
        "if (Object.prototype.hasOwnProperty.call(data, \"disabled\")) { el.disabled = !!data.disabled; }",
        sep = "\n    "
      ),
      SUBSCRIBE_EVENT = "change"
    ),
    stop("No binding renderer configured for ", component$tag_name, call. = FALSE)
  )
}

# Render one JS binding file from template.
.render_binding_file <- function(component, template_path) {
  if (!.component_has_binding(component)) {
    return(NULL)
  }

  values <- c(
    HEADER = paste("//", .generated_header()),
    FILE_STEM = component$component_name,
    .binding_values(component)
  )

  .render_template(template_path, values)
}
# nolint end
