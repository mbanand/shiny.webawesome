# nolint start: object_usage_linter,line_length_linter.
source(file.path("..", "..", "generate_components.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.write_json <- function(path, object) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    object,
    path = path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
}

.collapse_doc_text <- function(lines) {
  text <- paste(lines, collapse = " ")
  text <- gsub("#' ?", "", text)
  text <- gsub("[[:space:]]+", " ", text)
  trimws(text)
}

.create_fake_repo <- function(root, version = "3.3.1") {
  dir.create(file.path(root, "projectdocs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "inst", "extdata", "webawesome", "VERSION"), version)
  .write_file(
    file.path(root, "R", "wa_warning_registry.R"),
    c(
      ".wa_warning_defaults <- function() {",
      "  list(",
      "    missing_tree_item_id = TRUE",
      "  )",
      "}",
      "",
      ".wa_warning_keys <- function() {",
      "  names(.wa_warning_defaults())",
      "}"
    )
  )
}

.create_fake_binding_policy <- function(root) {
  .write_file(
    file.path(root, "dev", "generation", "binding-overrides.yaml"),
    c(
      "schema_version: 1",
      "",
      "components:",
      "  - tag: wa-button",
      "    binding:",
      "      mode: action",
      "      event: click",
      "      rationale: Native click semantics are expected for button-like controls.",
      "  - tag: wa-dropdown",
      "    binding:",
      "      mode: action_with_payload",
      "      event: wa-select",
      "      payload_kind: custom",
      "      payload_field: selectedItemValue",
      "      rationale: Dropdown selection is action-like and exposes the selected item's value as side-channel state.",
      "  - tag: wa-carousel",
      "    binding:",
      "      mode: semantic",
      "      event: wa-slide-change",
      "      value_kind: property",
      "      value_field: activeSlide",
      "      doc_note: zero_based_index",
      "      rationale: Carousel slide changes represent committed component state.",
      "  - tag: wa-details",
      "    binding:",
      "      mode: semantic",
      "      events:",
      "        - wa-show",
      "        - wa-hide",
      "      value_kind: property",
      "      value_field: open",
      "      rationale: Details visibility represents committed open state.",
      "  - tag: wa-dialog",
      "    binding:",
      "      mode: semantic",
      "      events:",
      "        - wa-show",
      "        - wa-after-hide",
      "      value_kind: property",
      "      value_field: open",
      "      rationale: Dialog visibility represents committed open state.",
      "  - tag: wa-drawer",
      "    binding:",
      "      mode: semantic",
      "      events:",
      "        - wa-show",
      "        - wa-after-hide",
      "      value_kind: property",
      "      value_field: open",
      "      rationale: Drawer visibility represents committed open state.",
      "  - tag: wa-tab-group",
      "    binding:",
      "      mode: semantic",
      "      event: wa-tab-show",
      "      value_kind: property",
      "      value_field: active",
      "      rationale: Tab groups expose committed active-tab state.",
      "  - tag: wa-tree",
      "    binding:",
      "      mode: semantic",
      "      event: wa-selection-change",
      "      value_kind: custom",
      "      value_field: selectedItemIds",
      "      js_warning: missing_tree_item_id",
      "      wrapper_warning: missing_tree_item_id",
      "      rationale: Tree selection changes represent committed component state."
    )
  )
}

.fake_custom_elements <- function() {
  list(
    schemaVersion = "1.0.0",
    package = list(name = "@awesome.me/webawesome"),
    modules = list(
      list(
        path = "components/card/card.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaCard",
            tagName = "wa-card",
            summary = "Card component.",
            attributes = list(
              list(
                name = "appearance",
                fieldName = "appearance",
                type = list(text = "'filled' | 'outlined'"),
                default = "filled"
              ),
              list(
                name = "with-header",
                fieldName = "withHeader",
                type = list(text = "boolean")
              )
            ),
            members = list(
              list(name = "appearance", kind = "field", type = list(text = "'filled' | 'outlined'")),
              list(name = "withHeader", kind = "field", type = list(text = "boolean")),
              list(name = "internalState", kind = "field", privacy = "private", type = list(text = "string")),
              list(name = "_secret", kind = "field", type = list(text = "string")),
              list(name = "css", kind = "field", static = TRUE, type = list(text = "string"))
            ),
            slots = list(
              list(name = "footer", description = "Footer slot."),
              list(name = "", description = "Default slot.")
            )
          )
        )
      ),
      list(
        path = "components/form/select.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaSelect",
            tagName = "wa-select",
            description = "Select component.",
            attributes = list(
              list(name = "multiple", fieldName = "multiple", type = list(text = "boolean")),
              list(name = "size", fieldName = "size", type = list(text = "'small' | 'large'")),
              list(name = "placeholder", fieldName = "placeholder", type = list(text = "string")),
              list(name = "value", fieldName = "value", type = list(text = "string")),
              list(name = "with-clear", fieldName = "withClear", type = list(text = "boolean"))
            ),
            members = list(
              list(name = "open", kind = "field", type = list(text = "boolean")),
              list(name = "value", kind = "field", type = list(text = "string")),
              list(name = "withClear", kind = "field", type = list(text = "boolean")),
              list(name = "displayInput", kind = "field", type = list(text = "HTMLInputElement")),
              list(name = "_value", kind = "field", type = list(text = "string")),
              list(name = "css", kind = "field", static = TRUE, type = list(text = "string"))
            ),
            events = list(
              list(name = "wa-change", type = list(text = "CustomEvent<string>")),
              list(name = "wa-input", type = list(text = "CustomEvent<string>"))
            ),
            slots = list(
              list(name = "label", description = "Label slot.")
            )
          )
        )
      ),
      list(
        path = "components/form/checkbox.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaCheckbox",
            tagName = "wa-checkbox",
            attributes = list(
              list(name = "checked", fieldName = "defaultChecked", type = list(text = "boolean")),
              list(name = "hint", fieldName = "hint", type = list(text = "string"))
            ),
            members = list(
              list(name = "checked", kind = "field", type = list(text = "boolean")),
              list(name = "hint", kind = "field", type = list(text = "string")),
              list(name = "input", kind = "field", type = list(text = "HTMLInputElement"))
            ),
            events = list(
              list(name = "wa-change", type = list(text = "CustomEvent<boolean>"))
            )
          )
        )
      ),
      list(
        path = "components/button/button.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaButton",
            tagName = "wa-button",
            attributes = list(
              list(name = "variant", fieldName = "variant", type = list(text = "'brand' | 'neutral'"))
            ),
            members = list(
              list(name = "variant", kind = "field", type = list(text = "'brand' | 'neutral'"))
            )
          )
        )
      ),
      list(
        path = "components/carousel/carousel.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaCarousel",
            tagName = "wa-carousel",
            summary = "Carousel component.",
            attributes = list(
              list(name = "current-slide", fieldName = "currentSlide", type = list(text = "number"))
            ),
            members = list(
              list(name = "currentSlide", kind = "field", type = list(text = "number")),
              list(name = "activeSlide", kind = "field", type = list(text = "number"))
            ),
            events = list(
              list(name = "wa-slide-change", type = list(text = "CustomEvent<{ index: number } >"))
            )
          )
        )
      ),
      list(
        path = "components/tree/tree.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaTree",
            tagName = "wa-tree",
            summary = "Tree component.",
            attributes = list(
              list(name = "selection", fieldName = "selection", type = list(text = "'single' | 'multiple' | 'leaf'"))
            ),
            members = list(
              list(name = "selection", kind = "field", type = list(text = "'single' | 'multiple' | 'leaf'"))
            ),
            events = list(
              list(name = "wa-selection-change", type = list(text = "CustomEvent<{ selection: WaTreeItem[] } >"))
            )
          )
        )
      ),
      list(
        path = "components/details/details.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaDetails",
            tagName = "wa-details",
            summary = "Details component.",
            attributes = list(
              list(name = "open", fieldName = "open", type = list(text = "boolean")),
              list(name = "summary", fieldName = "summary", type = list(text = "string"))
            ),
            members = list(
              list(name = "open", kind = "field", type = list(text = "boolean")),
              list(name = "summary", kind = "field", type = list(text = "string"))
            ),
            events = list(
              list(name = "wa-show", type = list(text = "CustomEvent<void>")),
              list(name = "wa-hide", type = list(text = "CustomEvent<void>"))
            )
          )
        )
      ),
      list(
        path = "components/dropdown/dropdown.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaDropdown",
            tagName = "wa-dropdown",
            summary = "Dropdown component.",
            attributes = list(
              list(name = "open", fieldName = "open", type = list(text = "boolean")),
              list(name = "placement", fieldName = "placement", type = list(text = "'top' | 'bottom'"))
            ),
            members = list(
              list(name = "open", kind = "field", type = list(text = "boolean")),
              list(name = "placement", kind = "field", type = list(text = "'top' | 'bottom'"))
            ),
            events = list(
              list(name = "wa-select", type = list(text = "CustomEvent<{ item: WaDropdownItem } >")),
              list(name = "wa-show", type = list(text = "CustomEvent<void>"))
            ),
            slots = list(
              list(name = "trigger", description = "Trigger slot.")
            )
          )
        )
      ),
      list(
        path = "components/dialog/dialog.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaDialog",
            tagName = "wa-dialog",
            summary = "Dialog component.",
            attributes = list(
              list(name = "open", fieldName = "open", type = list(text = "boolean")),
              list(name = "label", fieldName = "label", type = list(text = "string"))
            ),
            members = list(
              list(name = "open", kind = "field", type = list(text = "boolean")),
              list(name = "label", kind = "field", type = list(text = "string"))
            ),
            events = list(
              list(name = "wa-show", type = list(text = "CustomEvent<void>")),
              list(name = "wa-hide", type = list(text = "{ source: Element }")),
              list(name = "wa-after-hide", type = list(text = "CustomEvent<void>"))
            )
          )
        )
      ),
      list(
        path = "components/drawer/drawer.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaDrawer",
            tagName = "wa-drawer",
            summary = "Drawer component.",
            attributes = list(
              list(name = "open", fieldName = "open", type = list(text = "boolean")),
              list(name = "label", fieldName = "label", type = list(text = "string"))
            ),
            members = list(
              list(name = "open", kind = "field", type = list(text = "boolean")),
              list(name = "label", kind = "field", type = list(text = "string"))
            ),
            events = list(
              list(name = "wa-show", type = list(text = "CustomEvent<void>")),
              list(name = "wa-hide", type = list(text = "{ source: Element }")),
              list(name = "wa-after-hide", type = list(text = "CustomEvent<void>"))
            )
          )
        )
      ),
      list(
        path = "components/tab-group/tab-group.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaTabGroup",
            tagName = "wa-tab-group",
            summary = "Tab group component.",
            attributes = list(
              list(name = "active", fieldName = "active", type = list(text = "string")),
              list(name = "placement", fieldName = "placement", type = list(text = "'top' | 'bottom'"))
            ),
            members = list(
              list(name = "active", kind = "field", type = list(text = "string")),
              list(name = "placement", kind = "field", type = list(text = "'top' | 'bottom'"))
            ),
            events = list(
              list(name = "wa-tab-show", type = list(text = "CustomEvent<{ name: String } >")),
              list(name = "wa-tab-hide", type = list(text = "CustomEvent<{ name: String } >"))
            )
          )
        )
      ),
      list(
        path = "components/misc/helper.js",
        declarations = list(
          list(name = "NotACustomElement")
        )
      )
    )
  )
}

.create_fake_metadata <- function(root) {
  .write_json(
    file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"),
    .fake_custom_elements()
  )
}

.copy_generate_templates <- function(root) {
  dir.create(
    file.path(root, "tools", "templates"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  template_files <- c(
    "wrapper.R.tmpl",
    "update.R.tmpl",
    "binding.js.tmpl"
  )

  for (template in template_files) {
    file.copy(
      normalizePath(
        file.path("..", "..", "templates", template),
        mustWork = TRUE
      ),
      file.path(root, "tools", "templates", template)
    )
  }
}

.create_fake_vendor_metadata <- function(root, version = "3.3.1") {
  .write_json(
    file.path(root, "vendor", "webawesome", version, "dist-cdn", "custom-elements.json"),
    .fake_custom_elements()
  )
}

testthat::test_that("generate builds deterministic intermediate schema", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)

  result <- generate_components(root = root, emit = FALSE, verbose = FALSE)

  testthat::expect_equal(result$component_count, 11L)
  testthat::expect_equal(
    vapply(result$schema$components, `[[`, character(1), "tag_name"),
    c(
      "wa-button", "wa-card", "wa-carousel", "wa-checkbox",
      "wa-details", "wa-dialog", "wa-drawer", "wa-dropdown", "wa-select",
      "wa-tab-group", "wa-tree"
    )
  )

  card <- result$schema$components[[2]]
  testthat::expect_equal(card$r_function_name, "wa_card")
  testthat::expect_equal(
    vapply(card$attributes, `[[`, character(1), "name"),
    c("appearance", "with-header")
  )
  testthat::expect_equal(
    vapply(card$properties, `[[`, character(1), "name"),
    c("appearance", "withHeader")
  )
  testthat::expect_true(isTRUE(card$attributes[[2]]$is_boolean))
  testthat::expect_equal(card$attributes[[1]]$enum_values, c("filled", "outlined"))
  testthat::expect_equal(card$attributes[[1]]$default, "filled")
  testthat::expect_equal(
    vapply(card$slots, `[[`, character(1), "argument_name"),
    c("default", "footer")
  )

  carousel <- result$schema$components[[3]]
  testthat::expect_equal(carousel$classification$mode, "wrapper-binding-semantic")
  testthat::expect_true(isTRUE(carousel$classification$binding))
  testthat::expect_equal(carousel$classification$binding_mode, "semantic")
  testthat::expect_equal(carousel$classification$binding_event, "wa-slide-change")
  testthat::expect_equal(carousel$classification$binding_value_kind, "property")
  testthat::expect_equal(carousel$classification$binding_value_field, "activeSlide")
  testthat::expect_equal(carousel$classification$binding_doc_note, "zero_based_index")
  testthat::expect_equal(carousel$classification$binding_source, "policy")
  testthat::expect_match(
    carousel$classification$reasons$binding_policy_reason,
    "Carousel slide changes"
  )

  checkbox <- result$schema$components[[4]]
  checkbox_properties <- vapply(checkbox$properties, `[[`, character(1), "name")
  testthat::expect_equal(checkbox_properties, c("checked", "hint", "input"))
  testthat::expect_true(is.na(checkbox$properties[[1]]$attribute_name))
  testthat::expect_equal(card$classification$mode, "wrapper")
  button <- result$schema$components[[1]]
  testthat::expect_equal(button$classification$mode, "wrapper-binding-action")
  testthat::expect_true(isTRUE(button$classification$binding))
  testthat::expect_equal(button$classification$binding_mode, "action")
  testthat::expect_equal(button$classification$binding_event, "click")
  testthat::expect_equal(button$classification$binding_source, "policy")
  testthat::expect_match(
    button$classification$reasons$binding_policy_reason,
    "Native click semantics"
  )
  testthat::expect_equal(checkbox$classification$mode, "wrapper-binding")
  testthat::expect_true(isTRUE(checkbox$classification$binding))
  details <- result$schema$components[[5]]
  testthat::expect_equal(details$classification$mode, "wrapper-binding-semantic")
  testthat::expect_equal(details$classification$binding_mode, "semantic")
  testthat::expect_equal(details$classification$binding_event, "wa-show")
  testthat::expect_equal(
    details$classification$binding_events,
    c("wa-show", "wa-hide")
  )
  testthat::expect_equal(details$classification$binding_value_field, "open")
  dialog <- result$schema$components[[6]]
  testthat::expect_equal(dialog$classification$mode, "wrapper-binding-semantic")
  testthat::expect_equal(
    dialog$classification$binding_events,
    c("wa-show", "wa-after-hide")
  )
  testthat::expect_equal(dialog$classification$binding_value_field, "open")
  drawer <- result$schema$components[[7]]
  testthat::expect_equal(drawer$classification$mode, "wrapper-binding-semantic")
  testthat::expect_equal(
    drawer$classification$binding_events,
    c("wa-show", "wa-after-hide")
  )
  testthat::expect_equal(drawer$classification$binding_value_field, "open")
  dropdown <- result$schema$components[[8]]
  testthat::expect_equal(dropdown$classification$mode, "wrapper-binding-action-payload")
  testthat::expect_true(isTRUE(dropdown$classification$binding))
  testthat::expect_equal(dropdown$classification$binding_mode, "action_with_payload")
  testthat::expect_equal(dropdown$classification$binding_event, "wa-select")
  testthat::expect_equal(dropdown$classification$binding_payload_kind, "custom")
  testthat::expect_equal(dropdown$classification$binding_payload_field, "selectedItemValue")
  select <- result$schema$components[[9]]
  testthat::expect_equal(select$classification$mode, "wrapper-binding-update")
  testthat::expect_true(isTRUE(select$classification$update))
  tab_group <- result$schema$components[[10]]
  testthat::expect_equal(tab_group$classification$mode, "wrapper-binding-semantic")
  testthat::expect_equal(tab_group$classification$binding_mode, "semantic")
  testthat::expect_equal(tab_group$classification$binding_event, "wa-tab-show")
  testthat::expect_equal(tab_group$classification$binding_value_field, "active")
  tree <- result$schema$components[[11]]
  testthat::expect_equal(tree$classification$mode, "wrapper-binding-semantic")
  testthat::expect_true(isTRUE(tree$classification$binding))
  testthat::expect_equal(tree$classification$binding_mode, "semantic")
  testthat::expect_equal(tree$classification$binding_event, "wa-selection-change")
  testthat::expect_equal(tree$classification$binding_value_kind, "custom")
  testthat::expect_equal(tree$classification$binding_value_field, "selectedItemIds")
  testthat::expect_equal(tree$classification$binding_js_warning, "missing_tree_item_id")
  testthat::expect_equal(tree$classification$binding_wrapper_warning, "missing_tree_item_id")
  testthat::expect_equal(result$schema$summary$classification$wrapper_only, 1L)
  testthat::expect_equal(result$schema$summary$classification$binding, 10L)
  testthat::expect_equal(result$schema$summary$classification$update, 1L)
})

testthat::test_that("generate supports component filters and exclusions", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)

  result <- generate_components(
    root = root,
    filter = c("wa-card", "wa_checkbox", "select"),
    exclude = "wa-card",
    emit = FALSE,
    verbose = FALSE
  )

  testthat::expect_equal(result$component_count, 2L)
  testthat::expect_equal(
    vapply(result$schema$components, `[[`, character(1), "tag_name"),
    c("wa-checkbox", "wa-select")
  )
})

testthat::test_that("generate fails fast on unknown policy warning keys", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)

  .write_file(
    file.path(root, "dev", "generation", "binding-overrides.yaml"),
    c(
      "schema_version: 1",
      "",
      "components:",
      "  - tag: wa-tree",
      "    binding:",
      "      mode: semantic",
      "      event: wa-selection-change",
      "      value_kind: custom",
      "      value_field: selectedItemIds",
      "      js_warning: unknown_warning_key",
      "      rationale: Tree selection changes represent committed component state."
    )
  )

  testthat::expect_error(
    generate_components(
      root = root,
      filter = "wa-tree",
      emit = FALSE,
      verbose = FALSE
    ),
    regexp = "Unknown `binding\\.js_warning` key `unknown_warning_key`"
  )
})

testthat::test_that("generate fails fast on unknown binding doc note keys", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)

  .write_file(
    file.path(root, "dev", "generation", "binding-overrides.yaml"),
    c(
      "schema_version: 1",
      "",
      "components:",
      "  - tag: wa-carousel",
      "    binding:",
      "      mode: semantic",
      "      event: wa-slide-change",
      "      value_kind: property",
      "      value_field: activeSlide",
      "      doc_note: unsupported_note_key",
      "      rationale: Carousel slide changes represent committed component state."
    )
  )

  testthat::expect_error(
    generate_components(
      root = root,
      filter = "wa-carousel",
      emit = FALSE,
      verbose = FALSE
    ),
    regexp = "Unsupported binding documentation note key: unsupported_note_key"
  )
})

testthat::test_that("generate fails fast on incomplete action-with-payload policy", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)

  .write_file(
    file.path(root, "dev", "generation", "binding-overrides.yaml"),
    c(
      "schema_version: 1",
      "",
      "components:",
      "  - tag: wa-dropdown",
      "    binding:",
      "      mode: action_with_payload",
      "      event: wa-select",
      "      rationale: Dropdown selection should carry payload."
    )
  )

  testthat::expect_error(
    generate_components(
      root = root,
      filter = "wa-dropdown",
      emit = FALSE,
      verbose = FALSE
    ),
    regexp = "Action-with-payload binding override entries must include"
  )
})

testthat::test_that("generate writes debug artifacts when requested", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)

  result <- generate_components(
    root = root,
    emit = FALSE,
    debug = TRUE,
    verbose = FALSE
  )

  testthat::expect_true(dir.exists(result$debug$directory))
  testthat::expect_equal(
    dirname(result$debug$directory),
    file.path(root, "scratch", "debug")
  )
  testthat::expect_match(
    basename(result$debug$directory),
    "^generate-components-[0-9]{8}-[0-9]{6}-[0-9]+$"
  )
  testthat::expect_true(file.exists(result$debug$metadata_summary))
  testthat::expect_true(file.exists(result$debug$schema))
  testthat::expect_true(file.exists(result$debug$filters))
  testthat::expect_equal(
    result$debug$relative_directory,
    sub(
      paste0("^", normalizePath(root, winslash = "/", mustWork = TRUE), "/"),
      "",
      result$debug$directory
    )
  )

  schema_debug <- jsonlite::fromJSON(result$debug$schema, simplifyVector = FALSE)
  testthat::expect_equal(schema_debug$summary$component_count, 11L)
  testthat::expect_equal(
    names(schema_debug$components),
    c(
      "wa-button", "wa-card", "wa-carousel", "wa-checkbox",
      "wa-details", "wa-dialog", "wa-drawer", "wa-dropdown", "wa-select",
      "wa-tab-group", "wa-tree"
    )
  )
  testthat::expect_equal(
    schema_debug$components[["wa-card"]]$r_function_name,
    "wa_card"
  )
  testthat::expect_equal(
    names(schema_debug$components[["wa-card"]]$attributes),
    c("appearance", "with-header")
  )
  testthat::expect_equal(
    names(schema_debug$components[["wa-card"]]$properties),
    c("appearance", "withHeader")
  )
  testthat::expect_equal(
    names(schema_debug$components[["wa-card"]]$slots),
    c("default", "footer")
  )
  testthat::expect_equal(
    names(schema_debug$components[["wa-select"]]$events),
    c("wa-change", "wa-input")
  )
  testthat::expect_equal(
    schema_debug$components[["wa-button"]]$classification$binding_mode,
    "action"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-button"]]$classification$binding_source,
    "policy"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-carousel"]]$classification$binding_mode,
    "semantic"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-carousel"]]$classification$binding_value_kind,
    "property"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-carousel"]]$classification$binding_value_field,
    "activeSlide"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-carousel"]]$classification$binding_doc_note,
    "zero_based_index"
  )
  testthat::expect_equal(
    unlist(schema_debug$components[["wa-details"]]$classification$binding_events),
    c("wa-show", "wa-hide")
  )
  testthat::expect_equal(
    unlist(schema_debug$components[["wa-dialog"]]$classification$binding_events),
    c("wa-show", "wa-after-hide")
  )
  testthat::expect_equal(
    unlist(schema_debug$components[["wa-drawer"]]$classification$binding_events),
    c("wa-show", "wa-after-hide")
  )
  testthat::expect_equal(
    schema_debug$components[["wa-dropdown"]]$classification$binding_mode,
    "action_with_payload"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-dropdown"]]$classification$binding_payload_kind,
    "custom"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-dropdown"]]$classification$binding_payload_field,
    "selectedItemValue"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tab-group"]]$classification$binding_mode,
    "semantic"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tab-group"]]$classification$binding_value_field,
    "active"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tree"]]$classification$binding_mode,
    "semantic"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tree"]]$classification$binding_value_kind,
    "custom"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tree"]]$classification$binding_value_field,
    "selectedItemIds"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tree"]]$classification$binding_js_warning,
    "missing_tree_item_id"
  )
  testthat::expect_equal(
    schema_debug$components[["wa-tree"]]$classification$binding_wrapper_warning,
    "missing_tree_item_id"
  )
})

testthat::test_that("generate writes wrapper, binding, and update outputs", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .create_fake_binding_policy(root)
  .copy_generate_templates(root)

  result <- generate_components(
    root = root,
    filter = c(
      "wa-button", "wa-card", "wa-carousel", "wa-checkbox",
      "wa-details", "wa-dialog", "wa-drawer", "wa-dropdown", "wa-select",
      "wa-tab-group", "wa-tree"
    ),
    verbose = FALSE
  )

  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_button.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_card.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_carousel.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_checkbox.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_details.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_dialog.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_drawer.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_dropdown.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_select.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_tab_group.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_tree.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_button.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_carousel.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_checkbox.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_details.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_dialog.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_drawer.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_dropdown.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_select.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_tab_group.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_tree.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_select.R"))
  )
  testthat::expect_equal(length(result$written$wrappers), 11L)
  testthat::expect_equal(length(result$written$bindings), 10L)
  testthat::expect_equal(length(result$written$updates), 1L)
  testthat::expect_true("R/wa_select.R" %in% result$written$updates)
  testthat::expect_equal(result$integrity$prune_check$status, "warn")
  testthat::expect_match(
    result$integrity$prune_check$summary,
    "no recorded prune output found"
  )
  testthat::expect_equal(
    result$integrity$generated_record$path,
    file.path("manifests", "integrity", "generate-output.yaml")
  )
  testthat::expect_true(
    file.exists(file.path(root, result$integrity$generated_record$path))
  )

  button_wrapper <- readLines(file.path(root, "R", "wa_button.R"), warn = FALSE)
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    button_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^wa_button <- function\\($",
    button_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  input_id,$",
    button_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@param class Optional CSS class string\\.",
    button_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@param style Optional inline CSS style string\\.",
    button_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  class = NULL,$",
    button_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  style = NULL,$",
    button_wrapper
  )))

  card_wrapper <- readLines(file.path(root, "R", "wa_card.R"), warn = FALSE)
  testthat::expect_true(any(grepl(
    "@param id Optional DOM id attribute for HTML, CSS, and JS targeting\\.",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@param class Optional CSS class string\\.",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@param style Optional inline CSS style string\\.",
    card_wrapper
  )))

  carousel_wrapper <- readLines(
    file.path(root, "R", "wa_carousel.R"),
    warn = FALSE
  )
  carousel_text <- .collapse_doc_text(carousel_wrapper)
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    carousel_wrapper
  )))
  testthat::expect_match(
    carousel_text,
    "The Shiny value is returned as a numeric value\\."
  )
  testthat::expect_match(
    carousel_text,
    "This index is 0-based\\."
  )
  testthat::expect_true(any(grepl(
    "^wa_carousel <- function\\($",
    carousel_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  input_id,$",
    carousel_wrapper
  )))

  tree_wrapper <- readLines(
    file.path(root, "R", "wa_tree.R"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    tree_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^wa_tree <- function\\($",
    tree_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  input_id,$",
    tree_wrapper
  )))

  tab_group_wrapper <- readLines(
    file.path(root, "R", "wa_tab_group.R"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    tab_group_wrapper
  )))

  details_wrapper <- readLines(
    file.path(root, "R", "wa_details.R"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    details_wrapper
  )))

  dialog_wrapper <- readLines(
    file.path(root, "R", "wa_dialog.R"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    dialog_wrapper
  )))

  drawer_wrapper <- readLines(
    file.path(root, "R", "wa_drawer.R"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    drawer_wrapper
  )))

  dropdown_wrapper <- readLines(
    file.path(root, "R", "wa_dropdown.R"),
    warn = FALSE
  )
  dropdown_text <- .collapse_doc_text(dropdown_wrapper)
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    dropdown_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@section Shiny Bindings:",
    dropdown_wrapper
  )))
  testthat::expect_true(any(grepl(
    "input\\$<input_id>_value",
    dropdown_wrapper
  )))
  testthat::expect_true(any(grepl(
    "action semantics",
    dropdown_wrapper
  )))
  testthat::expect_match(
    dropdown_text,
    "The Shiny action value is returned as a numeric action value\\."
  )
  testthat::expect_match(
    dropdown_text,
    "The payload value is returned as a character string or `NULL`.",
    fixed = TRUE
  )
  testthat::expect_true(any(grepl(
    "returns `NULL` when the selected item has no `value`",
    dropdown_wrapper,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "empty string `\"\"`",
    dropdown_wrapper,
    fixed = TRUE
  )))

  select_wrapper <- readLines(file.path(root, "R", "wa_select.R"), warn = FALSE)
  select_text <- .collapse_doc_text(select_wrapper)
  testthat::expect_true(any(grepl(
    "@param input_id Shiny input id for the component\\.",
    select_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@section Shiny Bindings:",
    select_wrapper
  )))
  testthat::expect_match(
    select_text,
    paste(
      "The Shiny value is returned as a character string for single-select",
      "usage, or a character vector when `multiple` is `TRUE`."
    ),
    fixed = TRUE
  )
  testthat::expect_true(any(grepl(
    "^wa_select <- function\\($",
    select_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  input_id,$",
    select_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  if \\(length\\(message\\) == 0L\\) \\{$",
    select_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^    return\\(invisible\\(NULL\\)\\)$",
    select_wrapper
  )))
  testthat::expect_true(any(grepl(
    "Enumerated string\\.",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "@section Shiny Bindings:",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "#' None\\.",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "Allowed values:",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "`filled`",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "`outlined`",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "Default: `filled`\\.",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^  if \\(!is.null\\(appearance\\)\\) \\{$",
    card_wrapper
  )))
  testthat::expect_true(any(grepl(
    "^    appearance <- \\.wa_match_arg\\($",
    card_wrapper
  )))

  checkbox_wrapper <- readLines(
    file.path(root, "R", "wa_checkbox.R"),
    warn = FALSE
  )
  checkbox_component <- result$schema$components[[
    which(vapply(result$schema$components, `[[`, character(1), "tag_name") == "wa-checkbox")
  ]]
  checkbox_attr <- checkbox_component$attributes[[
    which(vapply(checkbox_component$attributes, `[[`, character(1), "name") == "checked")
  ]]
  checkbox_doc <- .wrapper_attr_param_doc(checkbox_component, checkbox_attr)
  testthat::expect_match(checkbox_doc, "Boolean\\.")
  testthat::expect_match(checkbox_doc, "Default: `FALSE`.", fixed = TRUE)
  testthat::expect_match(checkbox_doc, "HTML `checked` attribute", fixed = TRUE)
  testthat::expect_match(checkbox_doc, "`defaultChecked`", fixed = TRUE)
  testthat::expect_match(
    checkbox_doc,
    "live `checked` property\\."
  )

  icon_attrs <- list(list(
    name = "animation",
    argument_name = "animation",
    field_name = "animation",
    type = "IconAnimation | undefined",
    default = NA_character_,
    description = "Sets the animation for the icon",
    is_boolean = FALSE,
    enum_values = NULL
  ))
  icon_members <- list(list(
    name = "animation",
    type = list(text = "IconAnimation | undefined"),
    parsedType = list(
      text = "'beat' | 'fade' | 'spin' | undefined"
    )
  ))
  enriched_icon_attrs <- .enrich_attribute_types(icon_attrs, icon_members)
  icon_doc <- .wrapper_attr_param_doc(
    list(properties = list()),
    enriched_icon_attrs[[1]]
  )
  testthat::expect_match(icon_doc, "Enumerated string\\.")
  testthat::expect_match(icon_doc, "Allowed values:")
  testthat::expect_match(icon_doc, "`beat`", fixed = TRUE)

  flip_doc <- .wrapper_attr_param_doc(
    list(properties = list()),
    list(
      name = "flip",
      argument_name = "flip",
      field_name = "flip",
      type = "'x' | 'y' | 'both' | undefined",
      default = NA_character_,
      description = "Sets the flip direction of the icon.",
      is_boolean = FALSE,
      enum_values = .enum_values("'x' | 'y' | 'both' | undefined")
    )
  )
  testthat::expect_match(flip_doc, "Enumerated string\\.")
  testthat::expect_match(flip_doc, "`x`", fixed = TRUE)

  button_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_button.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return \\$\\(el\\)\\.data\\(\"val\"\\) \\|\\| 0;",
    button_binding
  )))
  testthat::expect_true(any(grepl(
    "return \"shiny.action\";",
    button_binding
  )))
  testthat::expect_true(any(grepl(
    "\\$\\(el\\)\\.data\\(\"val\", val \\+ 1\\);",
    button_binding
  )))
  testthat::expect_true(any(grepl(
    "callback\\(false\\);",
    button_binding
  )))

  checkbox_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_checkbox.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "__shinyWebawesomeCallback = \\(\\) => callback\\(\\);",
    checkbox_binding
  )))
  testthat::expect_true(any(grepl(
    "removeEventListener\\(eventName, el.__shinyWebawesomeCallback\\);",
    checkbox_binding
  )))
  testthat::expect_true(any(grepl(
    "dispatchEvent\\(new Event\\('change', \\{ bubbles: true \\}\\)\\);",
    checkbox_binding
  )))

  carousel_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_carousel.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return el\\.activeSlide;",
    carousel_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-slide-change\"\\];",
    carousel_binding
  )))
  testthat::expect_true(any(grepl(
    "addEventListener\\(eventName, el.__shinyWebawesomeCallback\\);",
    carousel_binding
  )))
  testthat::expect_true(any(grepl(
    "receiveMessage\\(el, data\\) \\{",
    carousel_binding
  )))
  testthat::expect_true(any(grepl(
    "^    return;$",
    carousel_binding
  )))

  tree_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_tree.js"),
    warn = FALSE
  )
  tree_wrapper <- readLines(
    file.path(root, "R", "wa_tree.R"),
    warn = FALSE
  )
  tree_text <- .collapse_doc_text(tree_wrapper)
  testthat::expect_true(any(grepl(
    "return el.__shinyWebawesomeValue \\|\\| \\[\\];",
    tree_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-selection-change\"\\];",
    tree_binding
  )))
  testthat::expect_true(any(grepl(
    "event\\?\\.detail\\?\\.selection",
    tree_binding
  )))
  testthat::expect_true(any(grepl(
    "window\\.ShinyWebawesomeWarn\\.warnOnce\\(",
    tree_binding
  )))
  testthat::expect_true(any(grepl(
    "missing_tree_item_id",
    tree_binding
  )))
  testthat::expect_true(any(grepl(
    "\\.wa_warn_missing_tree_item_ids\\(children, input_id = input_id\\)",
    tree_wrapper
  )))
  testthat::expect_true(any(grepl(
    "selectable descendant",
    tree_wrapper
  )))
  testthat::expect_match(
    tree_text,
    "The Shiny value is returned as a character vector\\."
  )

  details_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_details.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return el\\.open;",
    details_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-show\", \"wa-hide\"\\];",
    details_binding
  )))

  dialog_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_dialog.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return el\\.open;",
    dialog_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-show\", \"wa-after-hide\"\\];",
    dialog_binding
  )))

  drawer_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_drawer.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return el\\.open;",
    drawer_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-show\", \"wa-after-hide\"\\];",
    drawer_binding
  )))

  dropdown_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_dropdown.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return \"shiny.action\";",
    dropdown_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-select\"\\];",
    dropdown_binding
  )))
  testthat::expect_true(any(grepl(
    "event\\?\\.detail\\?\\.item",
    dropdown_binding
  )))
  testthat::expect_true(any(grepl(
    "typeof item.value === \"string\"",
    dropdown_binding,
    fixed = TRUE
  )))
  testthat::expect_true(any(grepl(
    "Shiny.setInputValue\\(el.id \\+ \"_value\", payload, \\{ priority: \"event\" \\}\\);",
    dropdown_binding
  )))

  tab_group_binding <- readLines(
    file.path(root, "inst", "bindings", "wa_tab_group.js"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl(
    "return el\\.active;",
    tab_group_binding
  )))
  testthat::expect_true(any(grepl(
    "el.__shinyWebawesomeEvents = \\[\"wa-tab-show\"\\];",
    tab_group_binding
  )))
})

testthat::test_that("generate backticks reserved R argument names in wrappers", {
  root <- withr::local_tempdir()
  metadata <- .fake_custom_elements()
  metadata$modules[[length(metadata$modules) + 1L]] <- list(
    path = "components/overlay/tooltip.js",
    declarations = list(
      list(
        kind = "class",
        name = "WaTooltip",
        tagName = "wa-tooltip",
        attributes = list(
          list(name = "for", fieldName = "for", type = list(text = "string")),
          list(name = "trigger", fieldName = "trigger", type = list(text = "string"))
        ),
        members = list(
          list(name = "for", kind = "field", type = list(text = "string")),
          list(name = "trigger", kind = "field", type = list(text = "string"))
        )
      )
    )
  )

  .create_fake_repo(root)
  .write_json(
    file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"),
    metadata
  )
  .copy_generate_templates(root)

  result <- generate_components(
    root = root,
    filter = "wa-tooltip",
    verbose = FALSE
  )

  testthat::expect_equal(length(result$written$wrappers), 1L)

  tooltip_wrapper <- readLines(
    file.path(root, "R", "wa_tooltip.R"),
    warn = FALSE
  )
  testthat::expect_true(any(grepl("^  `for` = NULL,$", tooltip_wrapper)))
  testthat::expect_true(any(grepl('"for" = `for`', tooltip_wrapper, fixed = TRUE)))
})

testthat::test_that("wrapper global attrs avoid metadata duplicates", {
  component <- list(
    attributes = list(
      list(
        name = "style",
        argument_name = "style",
        type = "string",
        default = NULL,
        description = "Style attribute."
      )
    ),
    slots = list(),
    classification = list(binding = FALSE)
  )

  globals <- .wrapper_global_attrs(component)

  testthat::expect_equal(length(globals), 1L)
  testthat::expect_equal(globals[[1]]$name, "class")
  testthat::expect_equal(globals[[1]]$argument_name, "class")
})

testthat::test_that("wrapper docs always include a Shiny Bindings section", {
  unbound_component <- list(
    tag_name = "wa-card",
    component_name = "card",
    r_function_name = "wa_card",
    description = "Card component.",
    classification = list(
      binding = FALSE,
      binding_mode = "none",
      binding_value_field = NA_character_,
      binding_doc_note = NA_character_,
      binding_wrapper_warning = NA_character_
    ),
    attributes = list(),
    properties = list(),
    events = list(),
    slots = list()
  )

  bound_component <- list(
    tag_name = "wa-input",
    component_name = "input",
    r_function_name = "wa_input",
    description = "Input component.",
    classification = list(
      binding = TRUE,
      binding_mode = "value",
      binding_value_field = "value",
      binding_doc_note = NA_character_,
      binding_wrapper_warning = NA_character_
    ),
    attributes = list(),
    properties = list(
      list(
        name = "value",
        argument_name = "value",
        attribute_name = "value",
        type = "string",
        description = "Current value.",
        is_boolean = FALSE,
        enum_values = NULL
      )
    ),
    events = list(),
    slots = list()
  )

  unbound_lines <- .render_bind_section(unbound_component)
  testthat::expect_match(
    unbound_lines,
    "@section Shiny Bindings:",
    fixed = TRUE
  )
  testthat::expect_match(unbound_lines, "#' None.", fixed = TRUE)

  bound_lines <- .render_bind_section(bound_component)
  testthat::expect_match(
    bound_lines,
    "@section Shiny Bindings:",
    fixed = TRUE
  )
  testthat::expect_false(grepl("#' None\\.", bound_lines))
})

testthat::test_that("generate asks for prune when vendor metadata exists", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_vendor_metadata(root)

  testthat::expect_error(
    generate_components(root = root, emit = FALSE, verbose = FALSE),
    "Run prune_webawesome\\(\\) first"
  )
})

testthat::test_that("generate asks for fetch and prune when vendor metadata is missing", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    generate_components(root = root, emit = FALSE, verbose = FALSE),
    paste(
      "No fetched Web Awesome dist-cdn runtime was found under vendor/webawesome/.",
      "Run fetch_webawesome\\(\\) and then prune_webawesome\\(\\) first."
    )
  )
})
# nolint end
