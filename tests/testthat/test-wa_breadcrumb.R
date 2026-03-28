test_that("wa_breadcrumb defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_breadcrumb(
        shiny.webawesome:::wa_breadcrumb_item("Home")
      )
    ),
    c(
      "<wa-breadcrumb>",
      "  <wa-breadcrumb-item>Home</wa-breadcrumb-item>",
      "</wa-breadcrumb>"
    )
  )
})

test_that("wa_breadcrumb override render includes attrs and separator slot", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_breadcrumb(
        shiny.webawesome:::wa_breadcrumb_item("Home"),
        id = "breadcrumb",
        label = "Trail",
        separator = ">"
      )
    ),
    c(
      '<wa-breadcrumb id="breadcrumb" label="Trail">',
      "  <wa-breadcrumb-item>Home</wa-breadcrumb-item>",
      '  <span slot="separator">&gt;</span>',
      "</wa-breadcrumb>"
    )
  )
})
