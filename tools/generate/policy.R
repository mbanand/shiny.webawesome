# Policy loading helpers for the generate stage.
# nolint start: object_usage_linter

# Return the default binding-override policy file relative to the repo root.
.default_binding_policy_file <- function() {
  file.path("dev", "generation", "binding-overrides.yaml")
}

# Return one normalized binding mode or `"none"` when missing.
.normalize_binding_mode <- function(value) {
  mode <- tolower(.scalar_string(value, fallback = "none"))

  if (!mode %in% c("none", "value", "action")) {
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

  normalized <- lapply(
    policy_components,
    function(component) {
      tag <- .scalar_string(component$tag, fallback = NA_character_)
      binding <- .or_default(component$binding, list())
      mode <- .normalize_binding_mode(binding$mode)
      event <- .normalize_binding_event(binding$event)
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

      if (!identical(mode, "none") && is.na(event)) {
        stop(
          "Binding override entries must include `binding.event` for mode `",
          mode,
          "`: ",
          tag,
          call. = FALSE
        )
      }

      list(
        tag = tag,
        binding = list(
          mode = mode,
          event = event,
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
# nolint end
