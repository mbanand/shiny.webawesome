test_that("wa_checkbox requires input_id", {
  expect_error(
    shiny.webawesome:::wa_checkbox(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_checkbox defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_checkbox("checkbox", "Label")
    ),
    c('<wa-checkbox id="checkbox">Label</wa-checkbox>')
  )
})

test_that("wa_checkbox representative overrides render expected attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_checkbox(
        "checkbox",
        "Label",
        value = "yes",
        checked = TRUE,
        disabled = TRUE,
        hint = "Hint",
        name = "choice",
        custom_error = "Nope",
        dir = "rtl",
        indeterminate = TRUE,
        lang = "en",
        required = TRUE,
        size = "large",
        title = "Pick one"
      )
    ),
    c(
      paste0(
        '<wa-checkbox id="checkbox" value="yes" checked disabled ',
        'hint="Hint" name="choice" custom-error="Nope" dir="rtl" ',
        'indeterminate lang="en" required size="large" title="Pick one">',
        "Label</wa-checkbox>"
      )
    )
  )
})

test_that("wa_checkbox boolean args validate and render correctly", {
  boolean_args <- c(
    checked = "checked",
    disabled = "disabled",
    indeterminate = "indeterminate",
    required = "required"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_checkbox("checkbox", "Label")
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_checkbox,
      c(
        list(input_id = "checkbox", "Label"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(
        sprintf(
          '<wa-checkbox id="checkbox" %s>Label</wa-checkbox>',
          attr_name
        )
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_checkbox,
      c(
        list(input_id = "checkbox", "Label"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_checkbox,
      c(
        list(input_id = "checkbox", "Label"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_checkbox,
        c(
          list(input_id = "checkbox", "Label"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_checkbox enum arguments validate exactly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_checkbox(
        "checkbox",
        "Label",
        size = "small"
      )
    ),
    c('<wa-checkbox id="checkbox" size="small">Label</wa-checkbox>')
  )

  expect_error(
    shiny.webawesome:::wa_checkbox("checkbox", "Label", size = "tiny"),
    "`size` must be one of ",
    fixed = TRUE
  )
})

test_that("wa_checkbox hint slot renders correctly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_checkbox(
        "checkbox",
        "Label",
        hint_slot = "Hint slot"
      )
    ),
    c(
      '<wa-checkbox id="checkbox">',
      "  Label",
      '  <span slot="hint">Hint slot</span>',
      "</wa-checkbox>"
    )
  )
})
