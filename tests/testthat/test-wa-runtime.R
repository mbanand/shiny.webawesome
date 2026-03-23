test_that("wa_page attaches the package dependency once", {
  page <- shiny.webawesome::wa_page(
    shiny.webawesome:::.wa_component("wa-card", "Hello"),
    shiny.webawesome:::.wa_component("wa-checkbox")
  )

  deps <- htmltools::findDependencies(page)
  dep_names <- vapply(deps, `[[`, character(1), "name")

  expect_equal(sum(dep_names == "shiny.webawesome"), 1L)
})

test_that("wa_page returns an html page scaffold", {
  page <- shiny.webawesome::wa_page(
    title = "Runtime test",
    lang = "en",
    body_class = "app-shell",
    shiny.webawesome:::.wa_component("wa-card", "Hello")
  )

  rendered <- htmltools::renderTags(page)

  expect_match(rendered$html, "<html[^>]*lang=\"en\"", perl = TRUE)
  expect_match(rendered$head, "<title>Runtime test</title>", perl = TRUE)
  expect_match(rendered$html, "<body[^>]*class=\"app-shell\"", perl = TRUE)
})

test_that(
  "internal component helper attaches the dependency in fluidPage usage",
  {
    ui <- shiny::fluidPage(
      shiny.webawesome:::.wa_component("wa-card", "Hello")
    )

    deps <- htmltools::findDependencies(ui)
    dep_names <- vapply(deps, `[[`, character(1), "name")

    expect_equal(sum(dep_names == "shiny.webawesome"), 1L)
  }
)

test_that("package dependency points at the shipped bootstrap assets", {
  dep <- shiny.webawesome:::.wa_dependency()
  script_src <- vapply(dep$script, `[[`, character(1), "src")

  expect_equal(dep$name, "shiny.webawesome")
  expect_equal(dep$src$file, ".")
  expect_equal(dep$stylesheet, "www/wa/styles/webawesome.css")
  expect_equal(script_src[[1]], "www/webawesome-init.js")
  expect_equal(dep$script[[1]]$type, "module")
  expect_true("bindings/wa_checkbox.js" %in% script_src)
  expect_true("bindings/wa_color_picker.js" %in% script_src)
  expect_true("bindings/wa_input.js" %in% script_src)
  expect_true("bindings/wa_number_input.js" %in% script_src)
  expect_true("bindings/wa_radio_group.js" %in% script_src)
  expect_true("bindings/wa_rating.js" %in% script_src)
  expect_true("bindings/wa_select.js" %in% script_src)
  expect_true("bindings/wa_slider.js" %in% script_src)
  expect_true("bindings/wa_switch.js" %in% script_src)
  expect_true("bindings/wa_textarea.js" %in% script_src)
})
