skip_if_no_chrome <- function() {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    testthat::skip("chromote is not available")
  }

  chrome <- suppressMessages(chromote::find_chrome())
  if (is.null(chrome)) {
    testthat::skip("No Chromium-based browser available for shinytest2")
  }
}

test_that("representative components work end to end in a browser", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("shinytest2")
  skip_if_no_chrome()

  app <- shinytest2::AppDriver$new(
    app_dir = testthat::test_path("apps", "representative-runtime"),
    name = "representative-runtime"
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle()
  app$wait_for_js(
    paste(
      "Boolean(window.customElements.get('wa-card'))",
      "&& Boolean(window.customElements.get('wa-checkbox'))",
      "&& Boolean(window.customElements.get('wa-select'))"
    )
  )

  testthat::expect_match(app$get_html("#card"), "Card body")
  testthat::expect_match(app$get_html("#card"), "Card header")

  app$run_js(
    paste(
      "const el = document.getElementById('checkbox');",
      "el.checked = true;",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('checkbox_value').innerText.trim() === 'TRUE'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('select');",
      "el.value = 'a';",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('select_value').innerText.trim() === 'a'"
  )

  app$click("update_select")
  app$wait_for_js(
    paste(
      "const el = document.getElementById('select');",
      "el.value === 'b'",
      "&& el.label === 'Updated label'",
      "&& el.hint === 'Updated hint'",
      "&& document.getElementById('select_value').innerText.trim() === 'b'"
    )
  )
})
