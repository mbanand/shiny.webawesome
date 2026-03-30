test_that("wa_js attaches the package dependency", {
  ui <- shiny.webawesome::wa_js("console.log('hello');")

  deps <- htmltools::findDependencies(ui)
  dep_names <- vapply(deps, `[[`, character(1), "name")

  expect_equal(sum(dep_names == "shiny.webawesome"), 1L)
})

test_that("wa_js renders one inline script tag", {
  ui <- shiny.webawesome::wa_js(
    "window.Shiny.setInputValue('details_open_state', true);"
  )

  rendered <- htmltools::renderTags(ui)

  expect_match(rendered$html, "<script[^>]*>", perl = TRUE)
  expect_match(
    rendered$html,
    "window.Shiny.setInputValue\\('details_open_state', true\\);",
    perl = TRUE
  )
})

test_that("wa_js validates code", {
  expect_error(
    shiny.webawesome::wa_js(character()),
    "`code` must be one non-missing string.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome::wa_js(NA_character_),
    "`code` must be one non-missing string.",
    fixed = TRUE
  )
})
