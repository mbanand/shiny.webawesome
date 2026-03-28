test_that("wa_tab_panel defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_tab_panel("Overview content")),
    c("<wa-tab-panel>Overview content</wa-tab-panel>")
  )
})

test_that("wa_tab_panel override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tab_panel(
        "Overview content",
        id = "overview-panel",
        name = "overview",
        active = TRUE,
        dir = "rtl",
        lang = "en"
      )
    ),
    c(paste0(
      '<wa-tab-panel id="overview-panel" name="overview" ',
      'active dir="rtl" lang="en">Overview content</wa-tab-panel>'
    ))
  )
})

test_that("wa_tab_panel active validates and renders correctly", {
  default_html <- render_html(
    shiny.webawesome:::wa_tab_panel("Overview content")
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tab_panel("Overview content", active = TRUE)
    ),
    c("<wa-tab-panel active>Overview content</wa-tab-panel>")
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_tab_panel("Overview content", active = FALSE)
    ),
    default_html
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_tab_panel("Overview content", active = NULL)
    ),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_tab_panel("Overview content", active = "yes"),
    "`active` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})
