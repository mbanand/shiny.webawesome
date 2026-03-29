test_that(
  "wa_dropdown keeps action and payload state aligned in the action harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-action")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(
      app,
      c("wa-button", "wa-dropdown", "wa-dropdown-item")
    )

    app$run_js(
      paste(
        "const el = document.getElementById('dropdown');",
        "const item = document.getElementById('dropdown_item_alpha');",
        "el.dispatchEvent(new CustomEvent('wa-select', {",
        "  bubbles: true,",
        "  detail: { item }",
        "}));"
      )
    )

    wait_for_shiny_input(app, input = "dropdown", expected = 1)
    wait_for_shiny_input(app, input = "dropdown_value", expected = "alpha")

    testthat::expect_equal(app$get_value(input = "dropdown"), 1)
    testthat::expect_equal(app$get_value(input = "dropdown_value"), "alpha")
    testthat::expect_equal(
      app$get_text("#dropdown_state"),
      paste(
        "input$dropdown = 1",
        'input$dropdown_value = "alpha"',
        sep = "\n"
      )
    )

    app$run_js(
      paste(
        "const el = document.getElementById('dropdown');",
        "const item = document.getElementById('dropdown_item_alpha');",
        "el.dispatchEvent(new CustomEvent('wa-select', {",
        "  bubbles: true,",
        "  detail: { item }",
        "}));"
      )
    )

    wait_for_shiny_input(app, input = "dropdown", expected = 2)

    testthat::expect_equal(app$get_value(input = "dropdown"), 2)
    testthat::expect_equal(app$get_value(input = "dropdown_value"), "alpha")

    app$run_js(
      paste(
        "const el = document.getElementById('dropdown');",
        "const item = document.getElementById('dropdown_item_missing');",
        "el.dispatchEvent(new CustomEvent('wa-select', {",
        "  bubbles: true,",
        "  detail: { item }",
        "}));"
      )
    )

    wait_for_shiny_input(app, input = "dropdown", expected = 3)
    wait_for_shiny_input(app, input = "dropdown_value", expected = NULL)

    testthat::expect_equal(app$get_value(input = "dropdown"), 3)
    testthat::expect_null(app$get_value(input = "dropdown_value"))

    app$run_js(
      paste(
        "const el = document.getElementById('dropdown');",
        "const item = document.getElementById('dropdown_item_empty');",
        "el.dispatchEvent(new CustomEvent('wa-select', {",
        "  bubbles: true,",
        "  detail: { item }",
        "}));"
      )
    )

    wait_for_shiny_input(app, input = "dropdown", expected = 4)
    wait_for_shiny_input(app, input = "dropdown_value", expected = "")

    testthat::expect_equal(app$get_value(input = "dropdown"), 4)
    testthat::expect_equal(app$get_value(input = "dropdown_value"), "")
  }
)
