test_that(
  "wa_number_input keeps durable values aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-number-input")

    app$run_js(
      paste(
        "const el = document.getElementById('number_input');",
        "el.value = 4;",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "number_input", expected = 4)

    testthat::expect_equal(app$get_value(input = "number_input"), 4)
    testthat::expect_equal(
      app$get_text("#number_input_state"),
      "input$number_input = 4"
    )
    testthat::expect_equal(
      app$get_js("String(document.getElementById('number_input').value)"),
      "4"
    )

    app$click("update_number_input")

    wait_for_shiny_input(app, input = "number_input", expected = 6)

    testthat::expect_equal(app$get_value(input = "number_input"), 6)
    testthat::expect_equal(
      app$get_js("document.getElementById('number_input').label"),
      "Updated quantity"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('number_input').hint"),
      "Updated number hint"
    )
  }
)
