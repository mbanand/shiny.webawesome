test_that("wa_breadcrumb_item defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_breadcrumb_item("Home")),
    c("<wa-breadcrumb-item>Home</wa-breadcrumb-item>")
  )
})

test_that("wa_breadcrumb_item override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_breadcrumb_item(
        "Home",
        id = "item",
        href = "/",
        rel = "noopener",
        target = "_blank",
        end = "End",
        separator = ">",
        start = "Start"
      )
    ),
    c(
      '<wa-breadcrumb-item id="item" href="/" rel="noopener" target="_blank">',
      "  Home",
      '  <span slot="end">End</span>',
      '  <span slot="separator">&gt;</span>',
      '  <span slot="start">Start</span>',
      "</wa-breadcrumb-item>"
    )
  )
})
