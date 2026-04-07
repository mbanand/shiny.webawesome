# Policy loading helpers for the generate stage.
# nolint start: object_usage_linter

# Return the default binding-override policy file relative to the repo root.
.default_binding_policy_file <- function() {
  file.path("dev", "generation", "binding-overrides.yaml")
}

# Return the default attribute-override policy file relative to the repo root.
.default_attribute_policy_file <- function() {
  file.path("dev", "generation", "attribute-overrides.yaml")
}

# Return the runtime warning-registry file relative to the repo root.
.warning_registry_file <- function() {
  file.path("R", "wa_warning_registry.R")
}

# Return one normalized binding mode or `"none"` when missing.
.normalize_binding_mode <- function(value) {
  mode <- tolower(.scalar_string(value, fallback = "none"))

  if (!mode %in% c("none", "value", "action", "semantic", "action_with_payload")) {
    stop(
      "Unsupported binding override mode: ",
      mode,
      call. = FALSE
    )
  }

  mode
}

# Return one normalized binding event string.
.normalize_binding_event <- function(value) {
  .scalar_string(tolower(value), fallback = NA_character_)
}

# Return one normalized ordered list of binding event strings.
.normalize_binding_events <- function(value) {
  value <- .or_default(value, list())

  if (length(value) == 0L) {
    return(character())
  }

  normalized <- vapply(value, .normalize_binding_event, character(1))
  normalized <- normalized[!is.na(normalized) & nzchar(normalized)]

  unique(normalized)
}

# Return one normalized binding extractor kind.
.normalize_binding_value_kind <- function(value) {
  kind <- tolower(.scalar_string(value, fallback = NA_character_))

  if (is.na(kind)) {
    return(NA_character_)
  }

  if (!kind %in% c("property", "attribute", "custom")) {
    stop(
      "Unsupported binding override value kind: ",
      kind,
      call. = FALSE
    )
  }

  kind
}

# Return one normalized binding extractor field name.
.normalize_binding_value_field <- function(value) {
  .scalar_string(value, fallback = NA_character_)
}

# Return one normalized binding payload extractor kind.
.normalize_binding_payload_kind <- function(value) {
  kind <- tolower(.scalar_string(value, fallback = NA_character_))

  if (is.na(kind)) {
    return(NA_character_)
  }

  if (!kind %in% c("property", "attribute", "custom")) {
    stop(
      "Unsupported binding override payload kind: ",
      kind,
      call. = FALSE
    )
  }

  kind
}

# Return one normalized binding payload extractor field name.
.normalize_binding_payload_field <- function(value) {
  .scalar_string(value, fallback = NA_character_)
}

# Return one normalized binding warning key.
.normalize_binding_warning_key <- function(value) {
  .scalar_string(value, fallback = NA_character_)
}

# Return one normalized binding documentation note key.
.normalize_binding_doc_note_key <- function(value) {
  key <- .scalar_string(value, fallback = NA_character_)

  if (is.na(key) || !nzchar(key)) {
    return(NA_character_)
  }

  if (!key %in% c("zero_based_index")) {
    stop(
      "Unsupported binding documentation note key: ",
      key,
      call. = FALSE
    )
  }

  key
}

# Return the known runtime warning-registry keys from package source.
.known_warning_registry_keys <- function(root) {
  registry_path <- file.path(root, .warning_registry_file())

  if (!file.exists(registry_path)) {
    stop(
      "Runtime warning registry file does not exist: ",
      .warning_registry_file(),
      call. = FALSE
    )
  }

  env <- new.env(parent = baseenv())
  sys.source(registry_path, envir = env)

  if (!exists(".wa_warning_keys", envir = env, inherits = FALSE)) {
    stop(
      "Runtime warning registry file does not define `.wa_warning_keys()`: ",
      .warning_registry_file(),
      call. = FALSE
    )
  }

  keys <- get(".wa_warning_keys", envir = env, inherits = FALSE)()
  .sorted_unique(as.character(keys))
}

# Validate one policy warning key against the runtime warning registry.
.validate_binding_warning_key <- function(
  key,
  field_name,
  tag,
  known_keys
) {
  if (is.na(key) || !nzchar(key)) {
    return(key)
  }

  if (key %in% known_keys) {
    return(key)
  }

  stop(
    "Unknown `binding.", field_name, "` key `", key, "` for ",
    tag,
    ". Known warning keys: ",
    paste(known_keys, collapse = ", "),
    call. = FALSE
  )
}

# Read one handwritten binding-override policy file when present.
.read_binding_override_policy <- function(
  root,
  policy_file = .default_binding_policy_file()
) {
  policy_path <- file.path(root, policy_file)

  if (!file.exists(policy_path)) {
    return(list(
      path = policy_file,
      exists = FALSE,
      components = list()
    ))
  }

  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to read binding override policy files.",
      call. = FALSE
    )
  }

  policy <- yaml::read_yaml(policy_path)
  policy_components <- .or_default(policy$components, list())

  if (length(policy_components) == 0L) {
    return(list(
      path = policy_file,
      exists = TRUE,
      components = list()
    ))
  }

  known_warning_keys <- .known_warning_registry_keys(root)

  normalized <- lapply(
    policy_components,
    function(component) {
      tag <- .scalar_string(component$tag, fallback = NA_character_)
      binding <- .or_default(component$binding, list())
      mode <- .normalize_binding_mode(binding$mode)
      event <- .normalize_binding_event(binding$event)
      events <- .normalize_binding_events(binding$events)
      value_kind <- .normalize_binding_value_kind(binding$value_kind)
      value_field <- .normalize_binding_value_field(binding$value_field)
      payload_kind <- .normalize_binding_payload_kind(binding$payload_kind)
      payload_field <- .normalize_binding_payload_field(binding$payload_field)
      js_warning <- .normalize_binding_warning_key(binding$js_warning)
      wrapper_warning <- .normalize_binding_warning_key(binding$wrapper_warning)
      doc_note <- .normalize_binding_doc_note_key(binding$doc_note)
      rationale <- .scalar_string(binding$rationale, fallback = NA_character_)

      if (is.na(tag)) {
        stop("Binding override entries must include `tag`.", call. = FALSE)
      }

      if (!startsWith(tag, "wa-")) {
        stop(
          "Binding override tags must start with `wa-`: ",
          tag,
          call. = FALSE
        )
      }

      if (
        !identical(mode, "none") &&
          is.na(event) &&
          length(events) == 0L
      ) {
        stop(
          "Binding override entries must include `binding.event` or ",
          "`binding.events` for mode `", mode, "`: ",
          tag,
          call. = FALSE
        )
      }

      if (
        !identical(mode, "semantic") &&
          !identical(mode, "action_with_payload") &&
          length(events) > 0L
      ) {
        stop(
          "Binding override entries may use `binding.events` only for ",
          "`binding.mode: semantic` or `binding.mode: action_with_payload`: ",
          tag,
          call. = FALSE
        )
      }

      if (identical(mode, "semantic") &&
        (is.na(value_kind) || is.na(value_field))) {
        stop(
          "Semantic binding override entries must include `binding.value_kind` ",
          "and `binding.value_field`: ",
          tag,
          call. = FALSE
        )
      }

      if (
        identical(mode, "action_with_payload") &&
          (is.na(payload_kind) || is.na(payload_field))
      ) {
        stop(
          "Action-with-payload binding override entries must include ",
          "`binding.payload_kind` and `binding.payload_field`: ",
          tag,
          call. = FALSE
        )
      }

      js_warning <- .validate_binding_warning_key(
        js_warning,
        "js_warning",
        tag,
        known_warning_keys
      )
      wrapper_warning <- .validate_binding_warning_key(
        wrapper_warning,
        "wrapper_warning",
        tag,
        known_warning_keys
      )

      list(
        tag = tag,
        binding = list(
          mode = mode,
          event = event,
          events = if (length(events) == 0L) {
            if (is.na(event)) character() else event
          } else {
            events
          },
          value_kind = value_kind,
          value_field = value_field,
          payload_kind = payload_kind,
          payload_field = payload_field,
          js_warning = js_warning,
          wrapper_warning = wrapper_warning,
          doc_note = doc_note,
          rationale = rationale
        )
      )
    }
  )

  tags <- vapply(normalized, `[[`, character(1), "tag")
  names(normalized) <- tags

  list(
    path = policy_file,
    exists = TRUE,
    components = normalized[order(tags)]
  )
}

# Return one normalized scalar attribute-constructor serialization value.
.normalize_attribute_constructor_value <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }

  value <- .scalar_string(value, fallback = NA_character_)
  if (is.na(value) || !nzchar(value)) {
    stop(
      "Attribute constructor override values must be non-empty strings or NULL.",
      call. = FALSE
    )
  }

  value
}

# Return one normalized named mapping for accepted string constructor values.
.normalize_attribute_constructor_string_map <- function(value) {
  value <- .or_default(value, list())

  if (length(value) == 0L) {
    return(character())
  }

  if (is.null(names(value)) || any(!nzchar(names(value)))) {
    stop(
      "Attribute constructor string maps must be named.",
      call. = FALSE
    )
  }

  normalized <- vapply(
    value,
    .normalize_attribute_constructor_value,
    character(1)
  )

  stats::setNames(normalized, names(value))
}

# Read one handwritten attribute-override policy file when present.
.read_attribute_override_policy <- function(
  root,
  policy_file = .default_attribute_policy_file()
) {
  policy_path <- file.path(root, policy_file)

  if (!file.exists(policy_path)) {
    return(list(
      path = policy_file,
      exists = FALSE,
      components = list()
    ))
  }

  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to read attribute override policy files.",
      call. = FALSE
    )
  }

  policy <- yaml::read_yaml(policy_path)
  policy_components <- .or_default(policy$components, list())

  if (length(policy_components) == 0L) {
    return(list(
      path = policy_file,
      exists = TRUE,
      components = list()
    ))
  }

  normalized <- lapply(
    policy_components,
    function(component) {
      tag <- .scalar_string(component$tag, fallback = NA_character_)
      attributes <- .or_default(component$attributes, list())

      if (is.na(tag) || !startsWith(tag, "wa-")) {
        stop(
          "Attribute override entries must include a `wa-` component tag.",
          call. = FALSE
        )
      }

      normalized_attrs <- lapply(
        attributes,
        function(attr) {
          name <- .scalar_string(attr$name, fallback = NA_character_)
          constructor <- .or_default(attr$constructor, list())
          true_value <- .normalize_attribute_constructor_value(constructor$true)
          false_value <- .normalize_attribute_constructor_value(constructor$false)
          string_map <- .normalize_attribute_constructor_string_map(
            constructor$strings
          )

          if (is.na(name) || !nzchar(name)) {
            stop(
              "Attribute override entries must include `name`.",
              call. = FALSE
            )
          }

          if (is.null(true_value) && is.null(false_value) && length(string_map) == 0L) {
            stop(
              "Attribute override entries must define at least one constructor mapping: ",
              tag,
              " / ",
              name,
              call. = FALSE
            )
          }

          list(
            name = name,
            constructor = list(
              true = true_value,
              false = false_value,
              strings = string_map
            )
          )
        }
      )

      normalized_attrs <- stats::setNames(
        normalized_attrs,
        vapply(normalized_attrs, `[[`, character(1), "name")
      )

      list(
        tag = tag,
        attributes = normalized_attrs
      )
    }
  )

  components <- stats::setNames(
    normalized,
    vapply(normalized, `[[`, character(1), "tag")
  )

  list(
    path = policy_file,
    exists = TRUE,
    components = components
  )
}
# nolint end
