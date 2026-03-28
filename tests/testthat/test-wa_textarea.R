test_that("wa_textarea requires input_id", {
  expect_error(
    shiny.webawesome:::wa_textarea(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_textarea defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_textarea("text_area")),
    c('<wa-textarea id="text_area"></wa-textarea>')
  )
})

test_that("wa_textarea override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_textarea(
        "text_area",
        value = "beta",
        disabled = TRUE,
        label = "Notes",
        hint = "Help",
        appearance = "filled",
        autocapitalize = "sentences",
        autofocus = TRUE,
        enterkeyhint = "send",
        inputmode = "text",
        placeholder = "Write here",
        readonly = TRUE,
        required = TRUE,
        resize = "horizontal",
        rows = 5,
        size = "large",
        spellcheck = TRUE,
        with_hint = TRUE,
        with_label = TRUE,
        hint_slot = "Hint slot",
        label_slot = "Label slot"
      )
    ),
    c(
      paste0(
        '<wa-textarea id="text_area" value="beta" disabled label="Notes" ',
        'hint="Help" appearance="filled" autocapitalize="sentences" ',
        'autofocus enterkeyhint="send" inputmode="text" ',
        'placeholder="Write here" readonly required resize="horizontal" ',
        'rows="5" size="large" spellcheck with-hint with-label>'
      ),
      '  <span slot="hint">Hint slot</span>',
      '  <span slot="label">Label slot</span>',
      "</wa-textarea>"
    )
  )
})

test_that("wa_textarea boolean args validate and render correctly", {
  boolean_args <- c(
    disabled = "disabled",
    autofocus = "autofocus",
    readonly = "readonly",
    required = "required",
    spellcheck = "spellcheck",
    with_hint = "with-hint",
    with_label = "with-label"
  )

  default_html <- render_html(shiny.webawesome:::wa_textarea("text_area"))

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_textarea,
      c(
        list(input_id = "text_area"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-textarea id="text_area" %s></wa-textarea>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_textarea,
      c(
        list(input_id = "text_area"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_textarea,
      c(
        list(input_id = "text_area"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_textarea,
        c(
          list(input_id = "text_area"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_textarea enum args validate exactly", {
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
      valid = "words",
      invalid = "caps"
    ),
    list(
      arg = "enterkeyhint",
      attr = "enterkeyhint",
      valid = "done",
      invalid = "return"
    ),
    list(
      arg = "inputmode",
      attr = "inputmode",
      valid = "search",
      invalid = "integer"
    ),
    list(
      arg = "resize",
      attr = "resize",
      valid = "vertical",
      invalid = "locked"
    ),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_textarea,
      c(
        list(input_id = "text_area"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-textarea id="text_area" %s="%s"></wa-textarea>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_textarea,
        c(
          list(input_id = "text_area"),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

test_that("update_wa_textarea sends only non-null values", {
  recorder <- new_message_recorder()

  expect_invisible(
    shiny.webawesome:::update_wa_textarea(
      session = recorder$session,
      input_id = "text_area",
      value = "beta",
      label = "Notes",
      hint = NULL,
      disabled = NULL
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        input_id = "text_area",
        message = list(value = "beta", label = "Notes")
      )
    )
  )
})
