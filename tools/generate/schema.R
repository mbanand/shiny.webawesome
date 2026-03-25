# Schema construction helpers for the generate stage.
# nolint start: object_usage_linter,line_length_linter.

# Return whether one declaration member looks like a public property.
.is_public_property_member <- function(member) {
  if (!identical(.scalar_string(member$kind, fallback = ""), "field")) {
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
  if (identical(privacy, "private")) {
    return(FALSE)
  }

  TRUE
}

# Normalize one attribute declaration into schema form.
.normalize_attribute <- function(attribute) {
  name <- .scalar_string(attribute$name, fallback = NA_character_)
  type_text <- .type_text(attribute$type)
  field_name <- .scalar_string(attribute$fieldName, fallback = NA_character_)
  enum_values <- .enum_values(type_text)

  list(
    name = name,
    argument_name = .as_snake_case(name),
    field_name = field_name,
    type = type_text,
    default = .scalar_string(attribute$default, fallback = NA_character_),
    description = .scalar_string(
      .or_default(attribute$description, attribute$summary),
      fallback = NA_character_
    ),
    is_boolean = .is_boolean_type(type_text),
    enum_values = if (length(enum_values) == 0L) NULL else enum_values
  )
}

# Normalize one public property into schema form.
.normalize_property <- function(
  member,
  attribute_names_by_field = character()
) {
  name <- .scalar_string(member$name, fallback = NA_character_)
  type_text <- .type_text(member$type)
  enum_values <- .enum_values(type_text)
  attribute_name <- if (name %in% names(attribute_names_by_field)) {
    unname(attribute_names_by_field[[name]])
  } else {
    NA_character_
  }

  list(
    name = name,
    argument_name = .as_snake_case(name),
    attribute_name = attribute_name,
    type = type_text,
    description = .scalar_string(
      .or_default(member$description, member$summary),
      fallback = NA_character_
    ),
    is_boolean = .is_boolean_type(type_text),
    enum_values = if (length(enum_values) == 0L) NULL else enum_values
  )
}

# Normalize one event declaration into schema form.
.normalize_event <- function(event) {
  list(
    name = .scalar_string(event$name, fallback = NA_character_),
    argument_name = .as_snake_case(.scalar_string(event$name, fallback = "")),
    type = .type_text(event$type),
    description = .scalar_string(
      .or_default(event$description, event$summary),
      fallback = NA_character_
    )
  )
}

# Normalize one slot declaration into schema form.
.normalize_slot <- function(slot) {
  list(
    name = .scalar_string(slot$name, fallback = ""),
    argument_name = .as_snake_case(
      .scalar_string(slot$name, fallback = "default")
    ),
    description = .scalar_string(
      .or_default(slot$description, slot$summary),
      fallback = NA_character_
    )
  )
}

# Return one sorted normalized list for one declaration field.
.normalize_sorted <- function(values, mapper, sort_key = "name") {
  values <- .or_default(values, list())

  if (length(values) == 0L) {
    return(list())
  }

  normalized <- lapply(values, mapper)
  keys <- vapply(
    normalized,
    function(value) .scalar_string(value[[sort_key]], fallback = ""),
    character(1)
  )

  normalized[order(keys)]
}

# Return relevant event names for Shiny input binding heuristics.
.binding_event_names <- function() {
  c("change", "input", "click", "toggle", "wa-change", "wa-input", "wa-toggle")
}

# Return event names that should not drive binding classification.
.ignored_binding_event_names <- function() {
  c(
    "blur", "focus", "slotchange", "wa-invalid",
    "wa-show", "wa-hide", "wa-after-show", "wa-after-hide", "wa-hover"
  )
}

# Return state field names that may indicate update-capable controls.
.update_state_field_names <- function() {
  c("value", "checked", "selected", "open", "active")
}

# Return supporting attribute names that suggest richer writable value controls.
.update_support_field_names <- function() {
  c(
    "placeholder", "multiple", "rows", "min", "max", "step",
    "maxlength", "minlength", "range"
  )
}

# Return one normalized binding override entry for a component tag.
.binding_override_for <- function(binding_policy, tag_name) {
  components <- .or_default(binding_policy$components, list())

  if (length(components) == 0L || !tag_name %in% names(components)) {
    return(NULL)
  }

  components[[tag_name]]$binding
}

# Classify one component for wrapper, binding, and update support.
.classify_component_support <- function(
  tag_name,
  attributes,
  properties,
  events,
  binding_policy = list()
) {
  attribute_names <- vapply(attributes, `[[`, character(1), "name")
  property_names <- vapply(properties, `[[`, character(1), "name")
  event_names <- vapply(events, `[[`, character(1), "name")

  matched_binding_events <- intersect(event_names, .binding_event_names())
  matched_update_state_fields <- intersect(
    unique(c(attribute_names, property_names)),
    .update_state_field_names()
  )
  matched_update_support_fields <- intersect(
    attribute_names,
    .update_support_field_names()
  )
  binding_override <- .binding_override_for(binding_policy, tag_name)
  binding_mode <- if (is.null(binding_override)) "none" else binding_override$mode
  binding_event <- if (is.null(binding_override)) NA_character_ else binding_override$event
  binding_events <- if (is.null(binding_override)) {
    character()
  } else {
    .or_default(binding_override$events, character())
  }
  binding_value_kind <- if (is.null(binding_override)) {
    NA_character_
  } else {
    binding_override$value_kind
  }
  binding_value_field <- if (is.null(binding_override)) {
    NA_character_
  } else {
    binding_override$value_field
  }
  binding_js_warning <- if (is.null(binding_override)) {
    NA_character_
  } else {
    binding_override$js_warning
  }
  binding_wrapper_warning <- if (is.null(binding_override)) {
    NA_character_
  } else {
    binding_override$wrapper_warning
  }
  binding_policy_reason <- if (is.null(binding_override)) {
    NA_character_
  } else {
    binding_override$rationale
  }

  if (identical(binding_mode, "action")) {
    has_binding <- TRUE
    has_update <- FALSE
  } else if (identical(binding_mode, "semantic")) {
    has_binding <- TRUE
    has_update <- FALSE
  } else if (identical(binding_mode, "value")) {
    has_binding <- TRUE
    has_update <- length(matched_update_state_fields) > 0L &&
      length(matched_update_support_fields) >= 2L
  } else {
    has_binding <- length(matched_binding_events) > 0L
    has_update <- has_binding &&
      length(matched_update_state_fields) > 0L &&
      length(matched_update_support_fields) >= 2L
    binding_mode <- if (has_binding) "value" else "none"
    binding_event <- if (length(matched_binding_events) == 0L) {
      NA_character_
    } else {
      matched_binding_events[[1]]
    }
    binding_events <- if (is.na(binding_event)) character() else binding_event
  }

  mode <- if (identical(binding_mode, "action")) {
    "wrapper-binding-action"
  } else if (identical(binding_mode, "semantic")) {
    "wrapper-binding-semantic"
  } else if (has_update) {
    "wrapper-binding-update"
  } else if (has_binding) {
    "wrapper-binding"
  } else {
    "wrapper"
  }

  list(
    mode = mode,
    wrapper = TRUE,
    binding = has_binding,
    binding_mode = binding_mode,
    binding_event = binding_event,
    binding_events = binding_events,
    binding_value_kind = binding_value_kind,
    binding_value_field = binding_value_field,
    binding_js_warning = binding_js_warning,
    binding_wrapper_warning = binding_wrapper_warning,
    binding_source = if (is.null(binding_override)) "metadata" else "policy",
    update = has_update,
    reasons = list(
      binding_events = matched_binding_events,
      ignored_events = intersect(event_names, .ignored_binding_event_names()),
      update_state_fields = matched_update_state_fields,
      update_support_fields = matched_update_support_fields,
      binding_policy_reason = binding_policy_reason,
      binding_events = binding_events,
      binding_value_kind = binding_value_kind,
      binding_value_field = binding_value_field,
      binding_js_warning = binding_js_warning,
      binding_wrapper_warning = binding_wrapper_warning
    )
  )
}

# Build the intermediate component schema from declaration records.
.build_component_schema <- function(records,
                                    binding_policy = list(),
                                    filter = character(),
                                    exclude = character()) {
  filter <- .normalize_filter_tokens(filter)
  exclude <- .normalize_filter_tokens(exclude)
  components <- list()

  for (record in records) {
    declaration <- record$declaration
    tag_name <- .scalar_string(declaration$tagName, fallback = NA_character_)
    component_name <- sub("^wa-", "", tag_name)
    r_function_name <- paste0("wa_", .as_snake_case(component_name))

    selectors <- .normalize_filter_tokens(c(tag_name, component_name, r_function_name))
    if (length(filter) > 0L && !any(selectors %in% filter)) {
      next
    }

    if (length(exclude) > 0L && any(selectors %in% exclude)) {
      next
    }

    attributes <- .normalize_sorted(
      declaration$attributes,
      .normalize_attribute
    )
    attribute_names_by_field <- stats::setNames(
      vapply(attributes, `[[`, character(1), "name"),
      vapply(attributes, `[[`, character(1), "field_name")
    )

    public_members <- .or_default(declaration$members, list())
    public_members <- public_members[
      vapply(public_members, .is_public_property_member, logical(1))
    ]

    properties <- .normalize_sorted(
      public_members,
      function(member) .normalize_property(member, attribute_names_by_field)
    )
    events <- .normalize_sorted(declaration$events, .normalize_event)
    slots <- .normalize_sorted(declaration$slots, .normalize_slot)
    classification <- .classify_component_support(
      tag_name = tag_name,
      attributes = attributes,
      properties = properties,
      events = events,
      binding_policy = binding_policy
    )

    components[[length(components) + 1L]] <- list(
      tag_name = tag_name,
      component_name = component_name,
      r_function_name = r_function_name,
      class_name = .scalar_string(declaration$name, fallback = NA_character_),
      source_module = .scalar_string(record$module_path, fallback = NA_character_),
      description = .scalar_string(
        .or_default(declaration$description, declaration$summary),
        fallback = NA_character_
      ),
      classification = classification,
      attributes = attributes,
      properties = properties,
      events = events,
      slots = slots
    )
  }

  if (length(components) == 0L) {
    return(list())
  }

  keys <- vapply(components, `[[`, character(1), "tag_name")
  components[order(keys)]
}

# Summarize component classification counts for debug and reporting.
.classification_summary <- function(components) {
  list(
    wrapper_only = sum(!vapply(components, function(comp) comp$classification$binding, logical(1))),
    binding = sum(vapply(components, function(comp) comp$classification$binding, logical(1))),
    update = sum(vapply(components, function(comp) comp$classification$update, logical(1)))
  )
}

# Build one machine-readable schema payload including summary metadata.
.build_schema_payload <- function(metadata,
                                  records,
                                  root,
                                  metadata_file,
                                  metadata_version = NA_character_,
                                  binding_policy = list(),
                                  filter = character(),
                                  exclude = character()) {
  components <- .build_component_schema(
    records = records,
    binding_policy = binding_policy,
    filter = filter,
    exclude = exclude
  )
  classification_counts <- .classification_summary(components)

  list(
    schema_version = 1L,
    generated_at = format(
      Sys.time(),
      "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),
    metadata = list(
      path = .strip_root_prefix(
        .resolve_metadata_path(root, metadata_file),
        root
      ),
      source_package = .scalar_string(
        metadata$package$name,
        fallback = NA_character_
      ),
      source_version = metadata_version,
      module_count = length(.metadata_modules(metadata)),
      declaration_count = length(records)
    ),
    binding_policy = list(
      path = .scalar_string(binding_policy$path, fallback = NA_character_),
      exists = isTRUE(binding_policy$exists),
      component_count = length(.or_default(binding_policy$components, list()))
    ),
    filters = list(
      include = if (length(filter) == 0L) NULL else .normalize_filter_tokens(filter),
      exclude = if (length(exclude) == 0L) NULL else .normalize_filter_tokens(exclude)
    ),
    summary = list(
      component_count = length(components),
      classification = classification_counts,
      tags = vapply(components, `[[`, character(1), "tag_name")
    ),
    components = components
  )
}
# nolint end
