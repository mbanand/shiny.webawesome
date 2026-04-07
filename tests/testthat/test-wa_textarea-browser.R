test_that(
  "wa_textarea keeps browser and Shiny text aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-textarea")

    app$run_js(
      paste(
        "const el = document.getElementById('text_area');",
        "el.value = 'delta';",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "text_area", expected = "delta")

    testthat::expect_equal(app$get_value(input = "text_area"), "delta")
    testthat::expect_equal(
      app$get_text("#text_area_state"),
      'input$text_area = "delta"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('text_area').value"),
      "delta"
    )

    app$click("update_textarea")

    wait_for_shiny_input(app, input = "text_area", expected = "gamma")

    testthat::expect_equal(app$get_value(input = "text_area"), "gamma")
    testthat::expect_equal(
      app$get_js("document.getElementById('text_area').label"),
      "Updated textarea label"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('text_area').hint"),
      "Updated textarea hint"
    )
  }
)

test_that(
  "wa_textarea autocorrect constructor mappings survive browser hydration",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-textarea")

    cases <- list(
      list(id = "text_area_auto_true", attr = "on", prop = TRUE, native = "on"),
      list(
        id = "text_area_auto_false",
        attr = "off",
        prop = FALSE,
        native = "off"
      ),
      list(id = "text_area_auto_on", attr = "on", prop = TRUE, native = "on"),
      list(
        id = "text_area_auto_off",
        attr = "off",
        prop = FALSE,
        native = "off"
      ),
      list(
        id = "text_area_auto_null",
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
        paste(
          "const native = el.shadowRoot &&",
          "el.shadowRoot.querySelector('textarea');"
        ),
        "return native ? native.getAttribute('autocorrect') : null;",
        "})()"
      )

      testthat::expect_equal(app$get_js(attr_js), case$attr)
      testthat::expect_equal(app$get_js(prop_js), case$prop)
      testthat::expect_equal(app$get_js(native_js), case$native)
    }
  }
)
