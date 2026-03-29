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
