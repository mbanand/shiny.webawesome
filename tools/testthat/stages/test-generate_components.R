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

.create_fake_repo <- function(root, version = "3.3.1") {
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "inst", "extdata", "webawesome", "VERSION"), version)
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
                type = list(text = "'filled' | 'outlined'")
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
              list(name = "size", fieldName = "size", type = list(text = "'small' | 'large'")),
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
            ),
            events = list(
              list(name = "click", type = list(text = "MouseEvent"))
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
    file.path(root, "vendor", "webawesome", version, "dist", "custom-elements.json"),
    .fake_custom_elements()
  )
}

testthat::test_that("generate builds deterministic intermediate schema", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)

  result <- generate_components(root = root, emit = FALSE, verbose = FALSE)

  testthat::expect_equal(result$component_count, 4L)
  testthat::expect_equal(
    vapply(result$schema$components, `[[`, character(1), "tag_name"),
    c("wa-button", "wa-card", "wa-checkbox", "wa-select")
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
  testthat::expect_equal(
    vapply(card$slots, `[[`, character(1), "argument_name"),
    c("default", "footer")
  )

  checkbox <- result$schema$components[[3]]
  checkbox_properties <- vapply(checkbox$properties, `[[`, character(1), "name")
  testthat::expect_equal(checkbox_properties, c("checked", "hint", "input"))
  testthat::expect_true(is.na(checkbox$properties[[1]]$attribute_name))
})

testthat::test_that("generate supports component filters and exclusions", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)

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

testthat::test_that("generate writes debug artifacts when requested", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)

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
  testthat::expect_equal(schema_debug$summary$component_count, 4L)
})

testthat::test_that("generate writes wrapper, binding, and update outputs", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_metadata(root)
  .copy_generate_templates(root)

  result <- generate_components(
    root = root,
    filter = c("wa-card", "wa-checkbox", "wa-select"),
    verbose = FALSE
  )

  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_card.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_checkbox.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_select.R"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_checkbox.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "inst", "bindings", "wa_select.js"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "R", "wa_select.R"))
  )
  testthat::expect_equal(length(result$written$wrappers), 3L)
  testthat::expect_equal(length(result$written$bindings), 2L)
  testthat::expect_equal(length(result$written$updates), 1L)
  testthat::expect_true("R/wa_select.R" %in% result$written$updates)
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
      "No fetched Web Awesome dist was found under vendor/webawesome/.",
      "Run fetch_webawesome\\(\\) and then prune_webawesome\\(\\) first."
    )
  )
})
# nolint end
