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
      "Boolean(window.customElements.get('wa-avatar'))",
      "&& Boolean(window.customElements.get('wa-badge'))",
      "&& Boolean(window.customElements.get('wa-button'))",
      "&& Boolean(window.customElements.get('wa-callout'))",
      "&& Boolean(window.customElements.get('wa-card'))",
      "&& Boolean(window.customElements.get('wa-carousel'))",
      "&& Boolean(window.customElements.get('wa-checkbox'))",
      "&& Boolean(window.customElements.get('wa-color-picker'))",
      "&& Boolean(window.customElements.get('wa-copy-button'))",
      "&& Boolean(window.customElements.get('wa-details'))",
      "&& Boolean(window.customElements.get('wa-dialog'))",
      "&& Boolean(window.customElements.get('wa-divider'))",
      "&& Boolean(window.customElements.get('wa-input'))",
      "&& Boolean(window.customElements.get('wa-number-input'))",
      "&& Boolean(window.customElements.get('wa-popover'))",
      "&& Boolean(window.customElements.get('wa-popup'))",
      "&& Boolean(window.customElements.get('wa-radio-group'))",
      "&& Boolean(window.customElements.get('wa-rating'))",
      "&& Boolean(window.customElements.get('wa-select'))",
      "&& Boolean(window.customElements.get('wa-slider'))",
      "&& Boolean(window.customElements.get('wa-switch'))",
      "&& Boolean(window.customElements.get('wa-tab-group'))",
      "&& Boolean(window.customElements.get('wa-tag'))",
      "&& Boolean(window.customElements.get('wa-textarea'))",
      "&& Boolean(window.customElements.get('wa-tooltip'))"
    )
  )

  testthat::expect_match(app$get_html("#avatar"), "initials=\"AV\"")
  testthat::expect_match(app$get_html("#badge"), "Beta")
  testthat::expect_match(app$get_html("#button"), "Run")
  testthat::expect_match(app$get_html("#callout"), "Heads up")
  testthat::expect_match(app$get_html("#card"), "Card body")
  testthat::expect_match(app$get_html("#card"), "Card header")
  testthat::expect_match(app$get_html("#copy_button"), "Copy")
  testthat::expect_match(app$get_html("#details"), "summary=\"More\"")
  testthat::expect_match(app$get_html("#dialog"), "Dialog title")
  testthat::expect_match(app$get_html("#popover"), "Popover body")
  testthat::expect_match(app$get_html("#tag"), "Tag")
  testthat::expect_match(app$get_html("#tooltip"), "Tooltip body")

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
      "const el = document.getElementById('color_picker');",
      "el.value = '#445566';",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('color_picker_value').innerText.trim() === '#445566'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('number_input');",
      "el.value = 4;",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('number_input_value').innerText.trim() === '4'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('switch');",
      "el.checked = true;",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('switch_value').innerText.trim() === 'TRUE'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('rating');",
      "el.value = 4;",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('rating_value').innerText.trim() === '4'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('radio_group');",
      "el.value = 'beta';",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('radio_group_value').innerText.trim() === 'beta'"
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

  app$run_js(
    paste(
      "const el = document.getElementById('text_input');",
      "el.value = 'alpha';",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('text_input_value').innerText.trim() === 'alpha'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('text_area');",
      "el.value = 'delta';",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('text_area_value').innerText.trim() === 'delta'"
  )

  app$run_js(
    paste(
      "const el = document.getElementById('slider');",
      "el.value = 5;",
      "el.dispatchEvent(new Event('change', { bubbles: true }));"
    )
  )
  app$wait_for_js(
    "document.getElementById('slider_value').innerText.trim() === '5'"
  )

  app$click("update_number_input")
  app$wait_for_js(
    paste(
      "const el = document.getElementById('number_input');",
      "String(el.value) === '6'",
      "&& el.label === 'Updated number label'",
      "&& el.hint === 'Updated number hint'",
      "&& document.getElementById('number_input_value').innerText.trim() === '6'"
    )
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

  app$click("update_input")
  app$wait_for_js(
    paste(
      "const el = document.getElementById('text_input');",
      "el.value === 'beta'",
      "&& el.label === 'Updated input label'",
      "&& el.hint === 'Updated input hint'",
      "&& document.getElementById('text_input_value').innerText.trim() === 'beta'"
    )
  )

  app$click("update_textarea")
  app$wait_for_js(
    paste(
      "const el = document.getElementById('text_area');",
      "el.value === 'gamma'",
      "&& el.label === 'Updated textarea label'",
      "&& el.hint === 'Updated textarea hint'",
      "&& document.getElementById('text_area_value').innerText.trim() === 'gamma'"
    )
  )

  app$click("update_slider")
  app$wait_for_js(
    paste(
      "const el = document.getElementById('slider');",
      "String(el.value) === '7'",
      "&& el.label === 'Updated slider label'",
      "&& el.hint === 'Updated slider hint'",
      "&& document.getElementById('slider_value').innerText.trim() === '7'"
    )
  )
})
