source(file.path("..", "..", "report_components.R"))

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

.create_fake_repo <- function(root, version = "3.3.1") {
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(
    file.path(root, "inst", "extdata", "webawesome", "VERSION"),
    version
  )
  .write_file(
    file.path(root, "NAMESPACE"),
    c(
      "export(update_wa_select)",
      "export(wa_button)",
      "export(wa_page)",
      "export(wa_select)"
    )
  )
  .write_file(
    file.path(root, "R", "wa_warning_registry.R"),
    c(
      ".wa_warning_defaults <- function() {",
      "  list()",
      "}",
      "",
      ".wa_warning_keys <- function() {",
      "  names(.wa_warning_defaults())",
      "}"
    )
  )
  .write_file(
    file.path(root, "R", "wa_page.R"),
    c(
      "#' Manual helper.",
      "#' @export",
      "wa_page <- function(...) NULL"
    )
  )
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
      "      rationale: Button should act like a Shiny action input."
    )
  )
  .write_file(
    file.path(root, "dev", "manifests", "component-coverage.policy.yaml"),
    c(
      "schema_version: 1",
      "",
      "components: []"
    )
  )
}

.fake_custom_elements <- function() {
  list(
    schemaVersion = "1.0.0",
    package = list(name = "@awesome.me/webawesome"),
    modules = list(
      list(
        path = "components/button/button.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaButton",
            tagName = "wa-button",
            attributes = list(
              list(
                name = "appearance",
                fieldName = "appearance",
                type = list(text = "'filled' | 'outlined'")
              )
            ),
            members = list(
              list(
                name = "appearance",
                kind = "field",
                type = list(text = "'filled' | 'outlined'")
              )
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
            attributes = list(
              list(
                name = "placeholder",
                fieldName = "placeholder",
                type = list(text = "string")
              ),
              list(
                name = "multiple",
                fieldName = "multiple",
                type = list(text = "boolean")
              ),
              list(
                name = "value",
                fieldName = "value",
                type = list(text = "string")
              ),
              list(
                name = "with-clear",
                fieldName = "withClear",
                type = list(text = "boolean")
              )
            ),
            members = list(
              list(
                name = "value",
                kind = "field",
                type = list(text = "string")
              ),
              list(
                name = "withClear",
                kind = "field",
                type = list(text = "boolean")
              )
            ),
            events = list(
              list(
                name = "wa-change",
                type = list(text = "CustomEvent<string>")
              ),
              list(name = "wa-input", type = list(text = "CustomEvent<string>"))
            )
          )
        )
      )
    )
  )
}

.template_path <- function(name) {
  normalizePath(file.path("..", "..", "templates", name), mustWork = TRUE)
}

# nolint start: object_usage_linter.
.build_fake_schema <- function(root) {
  .ensure_report_helpers()

  metadata_path <- file.path(
    root,
    "inst",
    "extdata",
    "webawesome",
    "custom-elements.json"
  )
  metadata <- .read_component_metadata(metadata_path)
  records <- .component_declaration_records(metadata)
  binding_policy <- .read_binding_override_policy(root)

  .build_schema_payload(
    metadata = metadata,
    records = records,
    root = root,
    metadata_file = .default_metadata_file(),
    metadata_version = .read_metadata_version(root),
    binding_policy = binding_policy
  )
}

.create_generated_surface <- function(root) {
  .write_json(
    file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"),
    .fake_custom_elements()
  )
  schema <- .build_fake_schema(root)
  wrapper_template <- .template_path("wrapper.R.tmpl")
  update_template <- .template_path("update.R.tmpl")
  binding_template <- .template_path("binding.js.tmpl")

  for (component in schema$components) {
    wrapper_text <- .render_wrapper_file(component, wrapper_template)
    update_text <- .render_update_file(component, update_template)

    if (!is.null(update_text)) {
      wrapper_text <- paste(wrapper_text, update_text, sep = "\n\n")
    }

    .write_file(
      file.path(root, "R", paste0(component$r_function_name, ".R")),
      wrapper_text
    )

    binding_text <- .render_binding_file(component, binding_template)
    if (!is.null(binding_text)) {
      .write_file(
        file.path(
          root,
          "inst",
          "bindings",
          paste0(component$r_function_name, ".js")
        ),
        binding_text
      )
    }
  }

  .write_file(
    file.path(root, "R", "wa_stale.R"),
    c(
      "# Generated by tools/generate_components.R. Do not edit by hand.",
      "",
      "wa_stale <- function(...) NULL"
    )
  )
}

.create_nonconformant_surface <- function(root) {
  .create_generated_surface(root)
  .write_file(
    file.path(root, "R", "wa_select.R"),
    sub(
      "boolean_names = c\\([^)]+\\),",
      "boolean_names = character(),",
      paste(
        readLines(file.path(root, "R", "wa_select.R"), warn = FALSE),
        collapse = "\n"
      )
    )
  )
  .write_file(
    file.path(root, "inst", "bindings", "wa_button.js"),
    sub(
      "return \\$\\(el\\)\\.data\\(\"val\"\\) \\|\\| 0;",
      "return 0;",
      paste(
        readLines(
          file.path(root, "inst", "bindings", "wa_button.js"),
          warn = FALSE
        ),
        collapse = "\n"
      )
    )
  )
}
# nolint end

testthat::test_that(
  "report_components writes deterministic manifests and reports",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    .create_generated_surface(root)

    result <- report_components(root = root, verbose = FALSE)

    testthat::expect_equal(result$integrity$generate_check$status, "warn")
    testthat::expect_match(
      result$integrity$generate_check$summary,
      "no recorded generate output found"
    )

    testthat::expect_true(file.exists(file.path(
      root, "manifests", "report", "generated-file-manifest.yaml"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "manifests", "report", "component-coverage.yaml"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "manifests", "report", "component-api-conformance.yaml"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "manifests", "report", "manual-api-inventory.yaml"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "reports", "report", "summary.md"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "reports", "report", "generated-files.md"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "reports", "report", "component-coverage.md"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "reports", "report", "component-api-conformance.md"
    )))
    testthat::expect_true(file.exists(file.path(
      root, "reports", "report", "manual-api-inventory.md"
    )))

    testthat::expect_equal(result$generated_file_manifest$summary$expected, 4)
    testthat::expect_equal(
      result$generated_file_manifest$summary$unexpected,
      1
    )
    testthat::expect_equal(
      result$component_coverage_manifest$summary$covered,
      2
    )
    testthat::expect_equal(
      result$manual_api_inventory$summary$manual_exports,
      1
    )
    testthat::expect_equal(
      result$component_api_conformance$summary$nonconformant,
      0
    )
    testthat::expect_true(
      result$component_api_conformance$components[[1]]$wrapper$args_match
    )
    testthat::expect_true(
      result$component_api_conformance$components[[1]]$wrapper$attrs_match
    )

    select_entry <- result$component_api_conformance$components[[2]]
    testthat::expect_true(select_entry$wrapper$args_match)
    testthat::expect_true(select_entry$wrapper$attrs_match)
    testthat::expect_true(select_entry$wrapper$boolean_names_match)
    testthat::expect_true(select_entry$wrapper$boolean_arg_names_match)
    testthat::expect_true(select_entry$binding$events_match)
    testthat::expect_true(select_entry$binding$get_value_match)
    testthat::expect_true(select_entry$binding$receive_message_match)
    testthat::expect_true(select_entry$update_function$args_match)

    manual_inventory <- yaml::read_yaml(
      file.path(root, "manifests", "report", "manual-api-inventory.yaml")
    )
    testthat::expect_equal(manual_inventory$summary$manual_exports, 1)
    testthat::expect_equal(manual_inventory$exports[[1]]$name, "wa_page")

    generated_files_report <- readLines(
      file.path(root, "reports", "report", "generated-files.md"),
      warn = FALSE
    )
    testthat::expect_true(any(grepl(
      "wa_stale.R",
      generated_files_report,
      fixed = TRUE
    )))
  }
)

testthat::test_that("report_components detects deeper conformance drift", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_nonconformant_surface(root)

  result <- report_components(root = root, verbose = FALSE)

  testthat::expect_gte(
    result$component_api_conformance$summary$nonconformant,
    1
  )

  select_entry <- result$component_api_conformance$components[[2]]
  testthat::expect_false(select_entry$wrapper$boolean_names_match)

  button_entry <- result$component_api_conformance$components[[1]]
  testthat::expect_false(button_entry$binding$get_value_match)
})
