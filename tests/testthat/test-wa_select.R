test_that("wa_select requires input_id", {
  expect_error(
    shiny.webawesome:::wa_select(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_select defaults render the minimal semantic wrapper", {
  option_tag <- make_wa_option("a", "A")

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_select("select", option_tag)
    ),
    c(
      '<wa-select id="select">',
      '  <wa-option value="a">A</wa-option>',
      "</wa-select>"
    )
  )
})

test_that("wa_select override render includes attrs and slots", {
  option_tag <- make_wa_option("a", "A")

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_select(
        "select",
        option_tag,
        disabled = TRUE,
        label = "Pick one",
        appearance = "filled",
        multiple = TRUE,
        open = TRUE,
        pill = TRUE,
        placeholder = "Select one",
        placement = "top",
        required = TRUE,
        size = "large",
        with_clear = TRUE,
        clear_icon = "Clear",
        end = "End",
        label_slot = "Label slot",
        start = "Start"
      )
    ),
    c(
      paste0(
        '<wa-select id="select" disabled label="Pick one" ',
        'appearance="filled" multiple open pill placeholder="Select one" ',
        'placement="top" required size="large" with-clear>'
      ),
      '  <wa-option value="a">A</wa-option>',
      '  <span slot="clear-icon">Clear</span>',
      '  <span slot="end">End</span>',
      '  <span slot="label">Label slot</span>',
      '  <span slot="start">Start</span>',
      "</wa-select>"
    )
  )
})

test_that("wa_select boolean args validate and render correctly", {
  option_tag <- make_wa_option("a", "A")
  boolean_args <- c(
    disabled = "disabled",
    multiple = "multiple",
    open = "open",
    pill = "pill",
    required = "required",
    with_clear = "with-clear"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_select("select", option_tag)
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_select,
      c(
        list(input_id = "select", option_tag),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(
        sprintf('<wa-select id="select" %s>', attr_name),
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_select,
      c(
        list(input_id = "select", option_tag),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_select,
      c(
        list(input_id = "select", option_tag),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_select,
        c(
          list(input_id = "select", option_tag),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_select enum arguments validate exactly", {
  option_tag <- make_wa_option("a", "A")
  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "outlined",
      invalid = "glass"
    ),
    list(
      arg = "placement",
      attr = "placement",
      valid = "bottom",
      invalid = "left"
    ),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_select,
      c(
        list(input_id = "select", option_tag),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf('<wa-select id="select" %s="%s">', case$attr, case$valid),
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_select,
        c(
          list(input_id = "select", option_tag),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

test_that("update_wa_select sends only non-null values", {
  recorder <- new_message_recorder()

  expect_invisible(
    shiny.webawesome:::update_wa_select(
      session = recorder$session,
      input_id = "sel",
      value = "a",
      label = NULL,
      hint = "Help",
      disabled = TRUE
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        input_id = "sel",
        message = list(value = "a", hint = "Help", disabled = TRUE)
      )
    )
  )
})

test_that("update_wa_select skips sendInputMessage for all-NULL updates", {
  recorder <- new_message_recorder()

  expect_invisible(
    shiny.webawesome:::update_wa_select(
      session = recorder$session,
      input_id = "sel",
      value = NULL,
      label = NULL,
      hint = NULL,
      disabled = NULL
    )
  )

  expect_equal(recorder$seen$calls, list())
})
