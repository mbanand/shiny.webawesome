test_that("wa_split_panel defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_split_panel()),
    c("<wa-split-panel></wa-split-panel>")
  )
})

test_that("wa_split_panel override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_split_panel(
        id = "split",
        disabled = TRUE,
        dir = "rtl",
        lang = "en",
        orientation = "vertical",
        position = 60,
        position_in_pixels = 180,
        primary = "start",
        snap = "25% 75%",
        snap_threshold = 8,
        divider = "Divider",
        end = "End panel",
        start = "Start panel"
      )
    ),
    c(
      paste0(
        '<wa-split-panel id="split" disabled dir="rtl" lang="en" ',
        'orientation="vertical" position="60" position-in-pixels="180" ',
        'primary="start" snap="25% 75%" snap-threshold="8">'
      ),
      '  <span slot="divider">Divider</span>',
      '  <span slot="end">End panel</span>',
      '  <span slot="start">Start panel</span>',
      "</wa-split-panel>"
    )
  )
})

test_that("wa_split_panel disabled validates and renders correctly", {
  default_html <- render_html(shiny.webawesome:::wa_split_panel())

  expect_exact_html(
    render_html(shiny.webawesome:::wa_split_panel(disabled = TRUE)),
    c("<wa-split-panel disabled></wa-split-panel>")
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_split_panel(disabled = FALSE)),
    default_html
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_split_panel(disabled = NULL)),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_split_panel(disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

test_that("wa_split_panel orientation enum validates exactly", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_split_panel(orientation = "horizontal")),
    c('<wa-split-panel orientation="horizontal"></wa-split-panel>')
  )

  expect_error(
    shiny.webawesome:::wa_split_panel(orientation = "diagonal"),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})
