test_that(
  "wa_select keeps the selected durable value aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, c("wa-option", "wa-select"))

    app$run_js(
      paste(
        "const el = document.getElementById('select');",
        "el.value = 'b';",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "select", expected = "b")

    testthat::expect_equal(app$get_value(input = "select"), "b")
    testthat::expect_equal(
      app$get_text("#select_state"),
      'input$select = "b"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('select').value"),
      "b"
    )

    app$click("update_select")

    wait_for_shiny_input(app, input = "select", expected = "b")

    testthat::expect_equal(app$get_value(input = "select"), "b")
    testthat::expect_equal(
      app$get_js("document.getElementById('select').label"),
      "Updated picker"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('select').hint"),
      "Updated select hint"
    )
  }
)
