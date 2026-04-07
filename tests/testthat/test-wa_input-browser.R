test_that(
  "wa_input keeps browser and Shiny state aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-input")

    app$run_js(
      paste(
        "const el = document.getElementById('text_input');",
        "el.value = 'bravo';",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "text_input", expected = "bravo")

    testthat::expect_equal(app$get_value(input = "text_input"), "bravo")
    testthat::expect_equal(
      app$get_text("#text_input_state"),
      'input$text_input = "bravo"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('text_input').value"),
      "bravo"
    )

    app$click("update_text_input")

    wait_for_shiny_input(app, input = "text_input", expected = "beta")

    testthat::expect_equal(app$get_value(input = "text_input"), "beta")
    testthat::expect_equal(
      app$get_js("document.getElementById('text_input').label"),
      "Updated search term"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('text_input').hint"),
      "Updated input hint"
    )
  }
)

test_that(
  "wa_input autocorrect constructor mappings survive browser hydration",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-input")

    cases <- list(
      list(
        id = "text_input_auto_true",
        attr = "on",
        prop = TRUE,
        native = "on"
      ),
      list(
        id = "text_input_auto_false",
        attr = "off",
        prop = FALSE,
        native = "off"
      ),
      list(id = "text_input_auto_on", attr = "on", prop = TRUE, native = "on"),
      list(
        id = "text_input_auto_off",
        attr = "off",
        prop = FALSE,
        native = "off"
      ),
      list(
        id = "text_input_auto_null",
        attr = NULL,
        prop = FALSE,
        native = "off"
      )
    )

    for (case in cases) {
      attr_js <- sprintf(
        "document.getElementById('%s').getAttribute('autocorrect')",
        case$id
      )
      prop_js <- sprintf("document.getElementById('%s').autocorrect", case$id)
      native_js <- paste0(
        "(() => {",
        sprintf("const el = document.getElementById('%s');", case$id),
        "const native = el.shadowRoot && el.shadowRoot.querySelector('input');",
        "return native ? native.getAttribute('autocorrect') : null;",
        "})()"
      )

      testthat::expect_equal(app$get_js(attr_js), case$attr)
      testthat::expect_equal(app$get_js(prop_js), case$prop)
      testthat::expect_equal(app$get_js(native_js), case$native)
    }
  }
)
