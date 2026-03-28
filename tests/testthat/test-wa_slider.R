test_that("wa_slider requires input_id", {
  expect_error(
    shiny.webawesome:::wa_slider(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_slider defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_slider("slider")),
    c('<wa-slider id="slider"></wa-slider>')
  )
})

test_that("wa_slider override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_slider(
        "slider",
        value = 2,
        disabled = TRUE,
        label = "Range",
        hint = "Slide",
        autofocus = TRUE,
        indicator_offset = 1,
        max = 10,
        max_value = 8,
        min = 0,
        min_value = 2,
        orientation = "vertical",
        range = TRUE,
        readonly = TRUE,
        required = TRUE,
        size = "large",
        step = 1,
        tooltip_distance = 12,
        tooltip_placement = "left",
        with_markers = TRUE,
        with_tooltip = TRUE,
        hint_slot = "Hint slot",
        label_slot = "Label slot",
        reference = "Reference"
      )
    ),
    c(
      paste0(
        '<wa-slider id="slider" value="2" disabled label="Range" ',
        'hint="Slide" autofocus indicator-offset="1" max="10" ',
        'max-value="8" min="0" min-value="2" orientation="vertical" ',
        'range readonly required size="large" step="1" ',
        'tooltip-distance="12" tooltip-placement="left" ',
        "with-markers with-tooltip>"
      ),
      '  <span slot="hint">Hint slot</span>',
      '  <span slot="label">Label slot</span>',
      '  <span slot="reference">Reference</span>',
      "</wa-slider>"
    )
  )
})

test_that("wa_slider boolean args validate and render correctly", {
  boolean_args <- c(
    disabled = "disabled",
    autofocus = "autofocus",
    range = "range",
    readonly = "readonly",
    required = "required",
    with_markers = "with-markers",
    with_tooltip = "with-tooltip"
  )

  default_html <- render_html(shiny.webawesome:::wa_slider("slider"))

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_slider,
      c(
        list(input_id = "slider"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-slider id="slider" %s></wa-slider>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_slider,
      c(
        list(input_id = "slider"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_slider,
      c(
        list(input_id = "slider"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_slider,
        c(
          list(input_id = "slider"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_slider enum args validate exactly", {
  enum_cases <- list(
    list(
      arg = "orientation",
      attr = "orientation",
      valid = "horizontal",
      invalid = "diagonal"
    ),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny"),
    list(
      arg = "tooltip_placement",
      attr = "tooltip-placement",
      valid = "top",
      invalid = "center"
    )
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_slider,
      c(
        list(input_id = "slider"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-slider id="slider" %s="%s"></wa-slider>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_slider,
        c(
          list(input_id = "slider"),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

test_that("update_wa_slider sends only non-null values", {
  recorder <- new_message_recorder()

  expect_invisible(
    shiny.webawesome:::update_wa_slider(
      session = recorder$session,
      input_id = "slider",
      value = 7,
      label = "Range",
      hint = "Slide",
      disabled = NULL
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        input_id = "slider",
        message = list(value = 7, label = "Range", hint = "Slide")
      )
    )
  )
})
