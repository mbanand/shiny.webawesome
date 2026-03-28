test_that("wa_dialog requires input_id", {
  expect_error(
    shiny.webawesome:::wa_dialog(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_dialog defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_dialog("dialog", "Dialog body")
    ),
    c('<wa-dialog id="dialog">Dialog body</wa-dialog>')
  )
})

test_that("wa_dialog override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_dialog(
        "dialog",
        "Dialog body",
        label = "Dialog title",
        dir = "rtl",
        lang = "en",
        light_dismiss = TRUE,
        open = TRUE,
        without_header = TRUE,
        footer = "Footer actions",
        header_actions = "Header actions",
        label_slot = "Slot title"
      )
    ),
    c(
      paste0(
        '<wa-dialog id="dialog" label="Dialog title" dir="rtl" ',
        'lang="en" light-dismiss open without-header>'
      ),
      "  Dialog body",
      '  <span slot="footer">Footer actions</span>',
      '  <span slot="header-actions">Header actions</span>',
      '  <span slot="label">Slot title</span>',
      "</wa-dialog>"
    )
  )
})

test_that("wa_dialog boolean args validate and render correctly", {
  boolean_args <- c(
    light_dismiss = "light-dismiss",
    open = "open",
    without_header = "without-header"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_dialog("dialog", "Dialog body")
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_dialog,
      c(
        list(input_id = "dialog", "Dialog body"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-dialog id="dialog" %s>Dialog body</wa-dialog>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_dialog,
      c(
        list(input_id = "dialog", "Dialog body"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_dialog,
      c(
        list(input_id = "dialog", "Dialog body"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_dialog,
        c(
          list(input_id = "dialog", "Dialog body"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})
