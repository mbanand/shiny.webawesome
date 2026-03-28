test_that("wa_button_group defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_button_group(
        shiny.webawesome:::wa_button("a", "A")
      )
    ),
    c(
      "<wa-button-group>",
      '  <wa-button id="a">A</wa-button>',
      "</wa-button-group>"
    )
  )
})

test_that("wa_button_group override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_button_group(
        shiny.webawesome:::wa_button("a", "A"),
        id = "group",
        label = "Actions",
        orientation = "vertical"
      )
    ),
    c(
      '<wa-button-group id="group" label="Actions" orientation="vertical">',
      '  <wa-button id="a">A</wa-button>',
      "</wa-button-group>"
    )
  )
})

test_that("wa_button_group orientation validates exactly", {
  expect_error(
    shiny.webawesome:::wa_button_group(orientation = "diagonal"),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})
