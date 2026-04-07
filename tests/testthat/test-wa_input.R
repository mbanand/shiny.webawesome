test_that("wa_input requires input_id", {
  expect_error(
    shiny.webawesome:::wa_input(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_input defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_input("text_input")),
    c('<wa-input id="text_input"></wa-input>')
  )
})

test_that("wa_input override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_input(
        "text_input",
        value = "alpha",
        disabled = TRUE,
        label = "Name",
        hint = "Help",
        appearance = "filled",
        autocapitalize = "words",
        autocorrect = TRUE,
        autofocus = TRUE,
        enterkeyhint = "next",
        inputmode = "text",
        password_toggle = TRUE,
        password_visible = TRUE,
        pill = TRUE,
        placeholder = "Type here",
        readonly = TRUE,
        required = TRUE,
        size = "small",
        type = "password",
        with_clear = TRUE,
        with_hint = TRUE,
        with_label = TRUE,
        without_spin_buttons = TRUE,
        clear_icon = "Clear",
        end = "End",
        hint_slot = "Hint slot",
        label_slot = "Label slot",
        start = "Start"
      )
    ),
    c(
      paste0(
        '<wa-input id="text_input" value="alpha" disabled label="Name" ',
        'hint="Help" appearance="filled" autocapitalize="words" ',
        'autocorrect="on" autofocus enterkeyhint="next" inputmode="text" ',
        'password-toggle password-visible pill placeholder="Type here" ',
        'readonly required size="small" type="password" with-clear ',
        "with-hint with-label without-spin-buttons>"
      ),
      '  <span slot="clear-icon">Clear</span>',
      '  <span slot="end">End</span>',
      '  <span slot="hint">Hint slot</span>',
      '  <span slot="label">Label slot</span>',
      '  <span slot="start">Start</span>',
      "</wa-input>"
    )
  )
})

test_that("wa_input boolean args validate and render correctly", {
  boolean_args <- c(
    disabled = "disabled",
    autofocus = "autofocus",
    password_toggle = "password-toggle",
    password_visible = "password-visible",
    pill = "pill",
    readonly = "readonly",
    required = "required",
    with_clear = "with-clear",
    with_hint = "with-hint",
    with_label = "with-label",
    without_spin_buttons = "without-spin-buttons"
  )

  default_html <- render_html(shiny.webawesome:::wa_input("text_input"))

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_input,
      c(
        list(input_id = "text_input"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-input id="text_input" %s></wa-input>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_input,
      c(
        list(input_id = "text_input"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_input,
      c(
        list(input_id = "text_input"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_input,
        c(
          list(input_id = "text_input"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that(
  "wa_input autocorrect supports logical and string constructor values",
  {
    default_html <- render_html(shiny.webawesome:::wa_input("text_input"))

    expect_exact_html(
      render_html(
        shiny.webawesome:::wa_input("text_input", autocorrect = TRUE)
      ),
      c('<wa-input id="text_input" autocorrect="on"></wa-input>')
    )
    expect_exact_html(
      render_html(
        shiny.webawesome:::wa_input("text_input", autocorrect = FALSE)
      ),
      c('<wa-input id="text_input" autocorrect="off"></wa-input>')
    )
    expect_exact_html(
      render_html(
        shiny.webawesome:::wa_input("text_input", autocorrect = "on")
      ),
      c('<wa-input id="text_input" autocorrect="on"></wa-input>')
    )
    expect_exact_html(
      render_html(
        shiny.webawesome:::wa_input("text_input", autocorrect = "off")
      ),
      c('<wa-input id="text_input" autocorrect="off"></wa-input>')
    )
    expect_equal(
      render_html(
        shiny.webawesome:::wa_input("text_input", autocorrect = NULL)
      ),
      default_html
    )
    expect_error(
      shiny.webawesome:::wa_input("text_input", autocorrect = "auto"),
      "`autocorrect` must be one of \"TRUE\", \"FALSE\", \"on\", \"off\".",
      fixed = TRUE
    )
  }
)

test_that("wa_input enum args validate exactly", {
  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "outlined",
      invalid = "glass"
    ),
    list(
      arg = "autocapitalize",
      attr = "autocapitalize",
      valid = "sentences",
      invalid = "caps"
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
      valid = "email",
      invalid = "integer"
    ),
    list(arg = "size", attr = "size", valid = "large", invalid = "tiny"),
    list(arg = "type", attr = "type", valid = "text", invalid = "file")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_input,
      c(
        list(input_id = "text_input"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-input id="text_input" %s="%s"></wa-input>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_input,
        c(
          list(input_id = "text_input"),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

test_that("update_wa_input sends only non-null values", {
  recorder <- new_message_recorder()

  expect_invisible(
    shiny.webawesome:::update_wa_input(
      session = recorder$session,
      input_id = "text_input",
      value = "alpha",
      label = NULL,
      hint = "Help",
      disabled = TRUE
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        input_id = "text_input",
        message = list(value = "alpha", hint = "Help", disabled = TRUE)
      )
    )
  )
})
