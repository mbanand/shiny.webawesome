test_that("wa_tab defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_tab("Overview")),
    c("<wa-tab>Overview</wa-tab>")
  )
})

test_that("wa_tab override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tab(
        "Overview",
        id = "overview-tab",
        disabled = TRUE,
        dir = "rtl",
        lang = "en",
        panel = "overview"
      )
    ),
    c(paste0(
      '<wa-tab id="overview-tab" disabled dir="rtl" lang="en" ',
      'panel="overview">Overview</wa-tab>'
    ))
  )
})

test_that("wa_tab disabled validates and renders correctly", {
  default_html <- render_html(shiny.webawesome:::wa_tab("Overview"))

  expect_exact_html(
    render_html(shiny.webawesome:::wa_tab("Overview", disabled = TRUE)),
    c("<wa-tab disabled>Overview</wa-tab>")
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_tab("Overview", disabled = FALSE)),
    default_html
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_tab("Overview", disabled = NULL)),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_tab("Overview", disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})
