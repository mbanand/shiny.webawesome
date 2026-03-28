# Wrapper coverage only: browser-side action-plus-payload behavior remains in
# the runtime suite, not here.

test_that("wa_dropdown requires input_id", {
  expect_error(
    shiny.webawesome:::wa_dropdown(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_dropdown defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_dropdown(
        "menu",
        make_wa_dropdown_item("alpha", "Alpha")
      )
    ),
    c(
      '<wa-dropdown id="menu">',
      '  <wa-dropdown-item value="alpha">Alpha</wa-dropdown-item>',
      "</wa-dropdown>"
    )
  )
})

test_that("wa_dropdown override render includes attrs and trigger slot", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_dropdown(
        "menu",
        make_wa_dropdown_item("alpha", "Alpha"),
        distance = 8,
        open = TRUE,
        placement = "bottom-end",
        size = "small",
        skidding = 4,
        trigger = "Open menu"
      )
    ),
    c(
      paste0(
        '<wa-dropdown id="menu" distance="8" open ',
        'placement="bottom-end" size="small" skidding="4">'
      ),
      '  <wa-dropdown-item value="alpha">Alpha</wa-dropdown-item>',
      '  <span slot="trigger">Open menu</span>',
      "</wa-dropdown>"
    )
  )
})

test_that("wa_dropdown boolean args validate and render correctly", {
  default_html <- render_html(
    shiny.webawesome:::wa_dropdown(
      "menu",
      make_wa_dropdown_item("alpha", "Alpha")
    )
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_dropdown(
        "menu",
        make_wa_dropdown_item("alpha", "Alpha"),
        open = TRUE
      )
    ),
    c(
      '<wa-dropdown id="menu" open>',
      '  <wa-dropdown-item value="alpha">Alpha</wa-dropdown-item>',
      "</wa-dropdown>"
    )
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_dropdown(
        "menu",
        make_wa_dropdown_item("alpha", "Alpha"),
        open = FALSE
      )
    ),
    default_html
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_dropdown(
        "menu",
        make_wa_dropdown_item("alpha", "Alpha"),
        open = NULL
      )
    ),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_dropdown(
      "menu",
      make_wa_dropdown_item("alpha", "Alpha"),
      open = "yes"
    ),
    "`open` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

test_that("wa_dropdown enum arguments validate exactly", {
  enum_cases <- list(
    list(
      arg = "placement",
      attr = "placement",
      valid = "top-start",
      invalid = "center"
    ),
    list(arg = "size", attr = "size", valid = "large", invalid = "tiny")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_dropdown,
      c(
        list(input_id = "menu", make_wa_dropdown_item("alpha", "Alpha")),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf('<wa-dropdown id="menu" %s="%s">', case$attr, case$valid),
        '  <wa-dropdown-item value="alpha">Alpha</wa-dropdown-item>',
        "</wa-dropdown>"
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_dropdown,
        c(
          list(input_id = "menu", make_wa_dropdown_item("alpha", "Alpha")),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})
