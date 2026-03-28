test_that("wa_tab_group requires input_id", {
  expect_error(
    shiny.webawesome:::wa_tab_group(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_tab_group defaults render the minimal semantic wrapper", {
  panel_a <- make_wa_tab_panel("first", "First panel")
  panel_b <- make_wa_tab_panel("second", "Second panel")
  tab_a <- make_wa_tab("first", "First")
  tab_b <- make_wa_tab("second", "Second")

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tab_group(
        "tab_group",
        panel_a,
        panel_b,
        nav = htmltools::tagList(tab_a, tab_b)
      )
    ),
    c(
      '<wa-tab-group id="tab_group">',
      '  <wa-tab-panel name="first">First panel</wa-tab-panel>',
      '  <wa-tab-panel name="second">Second panel</wa-tab-panel>',
      "  <span slot=\"nav\">",
      "    <wa-tab panel=\"first\">First</wa-tab>",
      "    <wa-tab panel=\"second\">Second</wa-tab>",
      "  </span>",
      "</wa-tab-group>"
    )
  )
})

test_that("wa_tab_group override render includes attrs and nav slot", {
  panel_a <- make_wa_tab_panel("first", "First panel")
  tab_a <- make_wa_tab("first", "First")

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tab_group(
        "tab_group",
        panel_a,
        activation = "manual",
        active = "first",
        dir = "rtl",
        lang = "en",
        placement = "end",
        without_scroll_controls = TRUE,
        nav = tab_a
      )
    ),
    c(
      paste0(
        '<wa-tab-group id="tab_group" activation="manual" active="first" ',
        'dir="rtl" lang="en" placement="end" without-scroll-controls>'
      ),
      '  <wa-tab-panel name="first">First panel</wa-tab-panel>',
      '  <wa-tab panel="first" slot="nav">First</wa-tab>',
      "</wa-tab-group>"
    )
  )
})

test_that("wa_tab_group boolean args validate and render correctly", {
  panel_a <- make_wa_tab_panel("first", "First panel")

  default_html <- render_html(
    shiny.webawesome:::wa_tab_group("tab_group", panel_a)
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tab_group(
        "tab_group",
        panel_a,
        without_scroll_controls = TRUE
      )
    ),
    c(
      '<wa-tab-group id="tab_group" without-scroll-controls>',
      '  <wa-tab-panel name="first">First panel</wa-tab-panel>',
      "</wa-tab-group>"
    )
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_tab_group(
        "tab_group",
        panel_a,
        without_scroll_controls = FALSE
      )
    ),
    default_html
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_tab_group(
        "tab_group",
        panel_a,
        without_scroll_controls = NULL
      )
    ),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_tab_group(
      "tab_group",
      panel_a,
      without_scroll_controls = "yes"
    ),
    "`without_scroll_controls` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

test_that("wa_tab_group enum args validate exactly", {
  panel_a <- make_wa_tab_panel("first", "First panel")
  enum_cases <- list(
    list(
      arg = "activation",
      attr = "activation",
      valid = "auto",
      invalid = "hover"
    ),
    list(
      arg = "placement",
      attr = "placement",
      valid = "bottom",
      invalid = "left"
    )
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_tab_group,
      c(
        list(input_id = "tab_group", panel_a),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf('<wa-tab-group id="tab_group" %s="%s">', case$attr, case$valid),
        '  <wa-tab-panel name="first">First panel</wa-tab-panel>',
        "</wa-tab-group>"
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_tab_group,
        c(
          list(input_id = "tab_group", panel_a),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})
