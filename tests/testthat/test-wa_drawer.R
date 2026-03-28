test_that("wa_drawer requires input_id", {
  expect_error(
    shiny.webawesome:::wa_drawer(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_drawer defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_drawer("drawer", "Drawer body")),
    c('<wa-drawer id="drawer">Drawer body</wa-drawer>')
  )
})

test_that("wa_drawer override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_drawer(
        "drawer",
        "Drawer body",
        label = "Drawer title",
        light_dismiss = TRUE,
        open = TRUE,
        placement = "top",
        without_header = TRUE,
        footer = "Footer",
        header_actions = "Actions",
        label_slot = "Label slot"
      )
    ),
    c(
      paste0(
        '<wa-drawer id="drawer" label="Drawer title" light-dismiss open ',
        'placement="top" without-header>'
      ),
      "  Drawer body",
      '  <span slot="footer">Footer</span>',
      '  <span slot="header-actions">Actions</span>',
      '  <span slot="label">Label slot</span>',
      "</wa-drawer>"
    )
  )
})

test_that("wa_drawer boolean and enum args validate exactly", {
  boolean_args <- c(
    light_dismiss = "light-dismiss",
    open = "open",
    without_header = "without-header"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_drawer("drawer", "Drawer body")
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]
    true_tag <- do.call(
      shiny.webawesome:::wa_drawer,
      c(
        list(input_id = "drawer", "Drawer body"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-drawer id="drawer" %s>Drawer body</wa-drawer>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_drawer,
      c(
        list(input_id = "drawer", "Drawer body"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)
  }

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_drawer(
        "drawer",
        "Drawer body",
        placement = "bottom"
      )
    ),
    c('<wa-drawer id="drawer" placement="bottom">Drawer body</wa-drawer>')
  )

  expect_error(
    shiny.webawesome:::wa_drawer("drawer", "Drawer body", placement = "left"),
    "`placement` must be one of ",
    fixed = TRUE
  )
})
