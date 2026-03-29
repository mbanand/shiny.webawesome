test_that(
  "wa_color_picker publishes durable value changes in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-color-picker")

    testthat::expect_match(
      app$get_text("#wa_color_picker-section h2"),
      "wa_color_picker"
    )

    app$run_js(
      paste(
        "const el = document.getElementById('color_picker');",
        "el.value = '#445566';",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "color_picker", expected = "#445566")

    testthat::expect_equal(app$get_value(input = "color_picker"), "#445566")
    testthat::expect_equal(
      app$get_text("#color_picker_state"),
      'input$color_picker = "#445566"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('color_picker').value"),
      "#445566"
    )
  }
)
