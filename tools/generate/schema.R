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

# Build the intermediate component schema from declaration records.
.build_component_schema <- function(records,
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

# Build one machine-readable schema payload including summary metadata.
.build_schema_payload <- function(metadata,
                                  records,
                                  root,
                                  metadata_file,
                                  metadata_version = NA_character_,
                                  filter = character(),
                                  exclude = character()) {
  components <- .build_component_schema(
    records = records,
    filter = filter,
    exclude = exclude
  )

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
    filters = list(
      include = if (length(filter) == 0L) NULL else .normalize_filter_tokens(filter),
      exclude = if (length(exclude) == 0L) NULL else .normalize_filter_tokens(exclude)
    ),
    summary = list(
      component_count = length(components),
      tags = vapply(components, `[[`, character(1), "tag_name")
    ),
    components = components
  )
}
# nolint end
