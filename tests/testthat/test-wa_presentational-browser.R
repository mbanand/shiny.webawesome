test_that(
  "presentational components render correctly in the presentational harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-presentational")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(
      app,
      c(
        "wa-avatar",
        "wa-badge",
        "wa-button",
        "wa-callout",
        "wa-card",
        "wa-copy-button",
        "wa-divider",
        "wa-popover",
        "wa-popup",
        "wa-tag",
        "wa-tooltip",
        "wa-tree-item"
      )
    )

    testthat::expect_match(app$get_html("#avatar"), "initials=\"AV\"")
    testthat::expect_match(app$get_html("#badge"), "Beta")
    testthat::expect_match(app$get_html("#button"), "Run")
    testthat::expect_match(app$get_html("#callout"), "Heads up")
    testthat::expect_match(app$get_html("#card"), "Card body")
    testthat::expect_match(app$get_html("#card"), "Card header")
    testthat::expect_match(app$get_html("#copy_button"), "Copy")
    testthat::expect_match(app$get_html("#popover"), "Popover body")
    testthat::expect_match(app$get_html("#tag"), "Tag")
    testthat::expect_match(app$get_html("#tooltip"), "Tooltip body")
    testthat::expect_match(app$get_html("#tree_item"), "Standalone item")

    testthat::expect_equal(
      app$get_text("#avatar_state"),
      'component = "#avatar"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('popover').getAttribute('for')"),
      "popover_target"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('tooltip').getAttribute('for')"),
      "tooltip_target"
    )
  }
)
