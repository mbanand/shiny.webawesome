test_that("wa_switch requires input_id", {
  expect_error(
    shiny.webawesome:::wa_switch(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_switch defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_switch("sw", "On")),
    c('<wa-switch id="sw">On</wa-switch>')
  )
})

test_that("wa_switch override render includes attrs and hint slot", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_switch(
        "sw",
        "On",
        value = "yes",
        checked = TRUE,
        disabled = TRUE,
        hint = "Help",
        name = "toggle",
        dir = "rtl",
        lang = "en",
        required = TRUE,
        size = "large",
        title = "Switch",
        with_hint = TRUE,
        hint_slot = "Hint slot"
      )
    ),
    c(
      paste0(
        '<wa-switch id="sw" value="yes" checked disabled hint="Help" ',
        'name="toggle" dir="rtl" lang="en" required size="large" ',
        'title="Switch" with-hint>'
      ),
      "  On",
      '  <span slot="hint">Hint slot</span>',
      "</wa-switch>"
    )
  )
})

test_that("wa_switch boolean args validate and render correctly", {
  boolean_args <- c(
    checked = "checked",
    disabled = "disabled",
    required = "required",
    with_hint = "with-hint"
  )

  default_html <- render_html(shiny.webawesome:::wa_switch("sw", "On"))

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_switch,
      c(
        list(input_id = "sw", "On"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-switch id="sw" %s>On</wa-switch>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_switch,
      c(
        list(input_id = "sw", "On"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_switch,
      c(
        list(input_id = "sw", "On"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_switch,
        c(
          list(input_id = "sw", "On"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_switch size enum validates exactly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_switch("sw", "On", size = "small")
    ),
    c('<wa-switch id="sw" size="small">On</wa-switch>')
  )

  expect_error(
    shiny.webawesome:::wa_switch("sw", "On", size = "tiny"),
    "`size` must be one of ",
    fixed = TRUE
  )
})
