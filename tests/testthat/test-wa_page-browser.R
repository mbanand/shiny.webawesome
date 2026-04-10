test_that("wa_page renders and upgrades in the dedicated page harness", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("shinytest2")
  skip_if_no_chrome()

  app <- new_browser_runtime_app("runtime-page")
  on.exit(app$stop(), add = TRUE)

  wait_for_custom_elements(app, "wa-page")

  testthat::expect_match(
    app$get_html("#page_component"),
    "navigation-placement=\"end\""
  )
  testthat::expect_match(app$get_html("#page_component"), "Page header")
  testthat::expect_match(app$get_html("#page_component"), "Page navigation")
  testthat::expect_match(app$get_html("#page_component"), "Main header")
  testthat::expect_match(app$get_html("#page_component"), "Main content")
  testthat::expect_match(app$get_html("#page_component"), "Page footer")

  testthat::expect_equal(
    app$get_text("#page_state"),
    'component = "#page_component"'
  )
  testthat::expect_equal(
    app$get_js("document.getElementById('page_component').tagName"),
    "WA-PAGE"
  )
})
