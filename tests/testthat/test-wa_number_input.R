test_that("wa_number_input requires input_id", {
  expect_error(
    shiny.webawesome:::wa_number_input(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_number_input defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_number_input("number_input")),
    c('<wa-number-input id="number_input"></wa-number-input>')
  )
})

test_that("wa_number_input override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_number_input(
        "number_input",
        value = 2,
        disabled = TRUE,
        label = "Number",
        hint = "Count",
        appearance = "filled",
        autofocus = TRUE,
        enterkeyhint = "done",
        inputmode = "decimal",
        max = 10,
        min = 0,
        pill = TRUE,
        placeholder = "Enter number",
        readonly = TRUE,
        required = TRUE,
        size = "large",
        step = 2,
        with_hint = TRUE,
        with_label = TRUE,
        without_steppers = TRUE,
        decrement_icon = "Minus",
        end = "End",
        hint_slot = "Hint slot",
        increment_icon = "Plus",
        label_slot = "Label slot",
        start = "Start"
      )
    ),
    c(
      paste0(
        '<wa-number-input id="number_input" value="2" disabled ',
        'label="Number" hint="Count" appearance="filled" autofocus ',
        'enterkeyhint="done" inputmode="decimal" max="10" min="0" ',
        'pill placeholder="Enter number" readonly required size="large" ',
        'step="2" with-hint with-label without-steppers>'
      ),
      '  <span slot="decrement-icon">Minus</span>',
      '  <span slot="end">End</span>',
      '  <span slot="hint">Hint slot</span>',
      '  <span slot="increment-icon">Plus</span>',
      '  <span slot="label">Label slot</span>',
      '  <span slot="start">Start</span>',
      "</wa-number-input>"
    )
  )
})

test_that("wa_number_input boolean args validate and render correctly", {
  boolean_args <- c(
    disabled = "disabled",
    autofocus = "autofocus",
    pill = "pill",
    readonly = "readonly",
    required = "required",
    with_hint = "with-hint",
    with_label = "with-label",
    without_steppers = "without-steppers"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_number_input("number_input")
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_number_input,
      c(
        list(input_id = "number_input"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(
        sprintf(
          '<wa-number-input id="number_input" %s></wa-number-input>',
          attr_name
        )
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_number_input,
      c(
        list(input_id = "number_input"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_number_input,
      c(
        list(input_id = "number_input"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_number_input,
        c(
          list(input_id = "number_input"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_number_input enum args validate exactly", {
  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "outlined",
      invalid = "glass"
    ),
    list(
      arg = "enterkeyhint",
      attr = "enterkeyhint",
      valid = "search",
      invalid = "return"
    ),
    list(
      arg = "inputmode",
      attr = "inputmode",
      valid = "numeric",
      invalid = "integer"
    ),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_number_input,
      c(
        list(input_id = "number_input"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-number-input id="number_input" %s="%s"></wa-number-input>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_number_input,
        c(
          list(input_id = "number_input"),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

test_that("update_wa_number_input sends only non-null values", {
  recorder <- new_message_recorder()

  expect_invisible(
    shiny.webawesome:::update_wa_number_input(
      session = recorder$session,
      input_id = "number_input",
      value = 6,
      label = "Amount",
      hint = "Count",
      disabled = TRUE
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        input_id = "number_input",
        message = list(
          value = 6,
          label = "Amount",
          hint = "Count",
          disabled = TRUE
        )
      )
    )
  )
})
