test_that("wa_radio_group requires input_id", {
  expect_error(
    shiny.webawesome:::wa_radio_group(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_radio_group defaults render the minimal wrapper", {
  radio_a <- make_wa_radio("alpha", "Alpha")
  radio_b <- make_wa_radio("beta", "Beta")

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_radio_group(
        "group",
        radio_a,
        radio_b,
        label = "Pick one"
      )
    ),
    c(
      '<wa-radio-group id="group" label="Pick one">',
      '  <wa-radio value="alpha">Alpha</wa-radio>',
      '  <wa-radio value="beta">Beta</wa-radio>',
      "</wa-radio-group>"
    )
  )
})

test_that("wa_radio_group override render includes attrs and slots", {
  radio_a <- make_wa_radio("alpha", "Alpha")

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_radio_group(
        "group",
        radio_a,
        value = "alpha",
        disabled = TRUE,
        label = "Pick one",
        hint = "Choose wisely",
        orientation = "horizontal",
        required = TRUE,
        size = "large",
        with_hint = TRUE,
        with_label = TRUE,
        hint_slot = "Hint slot",
        label_slot = "Label slot"
      )
    ),
    c(
      paste0(
        '<wa-radio-group id="group" value="alpha" disabled ',
        'label="Pick one" hint="Choose wisely" orientation="horizontal" ',
        'required size="large" with-hint with-label>'
      ),
      '  <wa-radio value="alpha">Alpha</wa-radio>',
      '  <span slot="hint">Hint slot</span>',
      '  <span slot="label">Label slot</span>',
      "</wa-radio-group>"
    )
  )
})

test_that("wa_radio_group boolean and enum args validate exactly", {
  radio_a <- make_wa_radio("alpha", "Alpha")

  expect_error(
    shiny.webawesome:::wa_radio_group(
      "group",
      radio_a,
      disabled = "yes"
    ),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome:::wa_radio_group(
      "group",
      radio_a,
      orientation = "diagonal"
    ),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})
