test_that("wa_container attaches the package dependency", {
  ui <- shiny.webawesome::wa_container("Hello")

  deps <- htmltools::findDependencies(ui)
  dep_names <- vapply(deps, `[[`, character(1), "name")

  expect_equal(sum(dep_names == "shiny.webawesome"), 1L)
})

test_that("wa_container renders a div with explicit attributes", {
  ui <- shiny.webawesome::wa_container(
    "Hello",
    `data-role` = "layout",
    id = "shell",
    class = "stack gap-l",
    style = "padding: 1rem;"
  )

  rendered <- htmltools::renderTags(ui)

  expect_match(rendered$html, "<div[^>]*id=\"shell\"", perl = TRUE)
  expect_match(rendered$html, "class=\"stack gap-l\"", perl = TRUE)
  expect_match(rendered$html, "style=\"padding: 1rem;\"", perl = TRUE)
  expect_match(rendered$html, "data-role=\"layout\"", perl = TRUE)
  expect_match(rendered$html, ">Hello</div>", perl = TRUE)
})
