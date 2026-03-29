test_that(
  "wa_tab_group keeps semantic active-tab state aligned in the event harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic-events")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, c("wa-tab", "wa-tab-group", "wa-tab-panel"))

    app$run_js(
      paste(
        "const el = document.getElementById('tab_group');",
        "el.active = 'second';",
        "el.dispatchEvent(new CustomEvent('wa-tab-show', {",
        "  bubbles: true,",
        "  detail: { name: 'second' }",
        "}));"
      )
    )

    wait_for_shiny_input(app, input = "tab_group", expected = "second")

    testthat::expect_equal(app$get_value(input = "tab_group"), "second")
    testthat::expect_equal(
      app$get_text("#tab_group_state"),
      'input$tab_group = "second"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('tab_group').active"),
      "second"
    )
  }
)
