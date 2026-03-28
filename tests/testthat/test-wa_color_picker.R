test_that("wa_color_picker requires input_id", {
  expect_error(
    shiny.webawesome:::wa_color_picker(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_color_picker defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_color_picker("color_picker")),
    c('<wa-color-picker id="color_picker"></wa-color-picker>')
  )
})

test_that("wa_color_picker override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_color_picker(
        "color_picker",
        value = "#112233",
        disabled = TRUE,
        label = "Color",
        hint = "Pick one",
        format = "rgb",
        opacity = TRUE,
        open = TRUE,
        required = TRUE,
        size = "large",
        swatches = "#000000;#ffffff",
        uppercase = TRUE,
        with_hint = TRUE,
        with_label = TRUE,
        without_format_toggle = TRUE,
        hint_slot = "Hint slot",
        label_slot = "Label slot"
      )
    ),
    c(
      paste0(
        '<wa-color-picker id="color_picker" value="#112233" disabled ',
        'label="Color" hint="Pick one" format="rgb" opacity open ',
        'required size="large" swatches="#000000;#ffffff" uppercase ',
        "with-hint with-label without-format-toggle>"
      ),
      '  <span slot="hint">Hint slot</span>',
      '  <span slot="label">Label slot</span>',
      "</wa-color-picker>"
    )
  )
})

test_that("wa_color_picker boolean and enum args validate exactly", {
  boolean_args <- c(
    disabled = "disabled",
    opacity = "opacity",
    open = "open",
    required = "required",
    uppercase = "uppercase",
    with_hint = "with-hint",
    with_label = "with-label",
    without_format_toggle = "without-format-toggle"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_color_picker("color_picker")
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]
    true_tag <- do.call(
      shiny.webawesome:::wa_color_picker,
      c(list(input_id = "color_picker"), stats::setNames(list(TRUE), arg_name))
    )
    expect_exact_html(
      render_html(true_tag),
      c(
        sprintf(
          '<wa-color-picker id="color_picker" %s></wa-color-picker>',
          attr_name
        )
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_color_picker,
      c(list(input_id = "color_picker"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)
  }

  enum_cases <- list(
    list(arg = "format", attr = "format", valid = "hex", invalid = "cmyk"),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_color_picker,
      c(
        list(input_id = "color_picker"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-color-picker id="color_picker" %s="%s"></wa-color-picker>',
          case$attr,
          case$valid
        )
      )
    )
  }
})
