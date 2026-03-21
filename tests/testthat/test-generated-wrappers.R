make_wa_option <- function(value, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-option", label),
    value = value
  )
}

make_wa_radio <- function(value, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-radio", label),
    value = value
  )
}

render_html <- function(tag) {
  as.character(htmltools::renderTags(tag)$html)
}

expect_exact_html <- function(actual, expected_lines) {
  testthat::expect_equal(actual, paste(expected_lines, collapse = "\n"))
}

test_that("wa_card renders exact fragments for defaults and overrides", {
  card_cases <- list(
    list(
      name = "default",
      tag = shiny.webawesome:::wa_card("Hello"),
      expected = c("<wa-card>Hello</wa-card>")
    ),
    list(
      name = "appearance",
      tag = shiny.webawesome:::wa_card("Hello", appearance = "filled"),
      expected = c('<wa-card appearance="filled">Hello</wa-card>')
    ),
    list(
      name = "id",
      tag = shiny.webawesome:::wa_card("Hello", id = "card"),
      expected = c('<wa-card id="card">Hello</wa-card>')
    ),
    list(
      name = "dir",
      tag = shiny.webawesome:::wa_card("Hello", dir = "rtl"),
      expected = c('<wa-card dir="rtl">Hello</wa-card>')
    ),
    list(
      name = "lang",
      tag = shiny.webawesome:::wa_card("Hello", lang = "en"),
      expected = c('<wa-card lang="en">Hello</wa-card>')
    ),
    list(
      name = "orientation",
      tag = shiny.webawesome:::wa_card("Hello", orientation = "horizontal"),
      expected = c('<wa-card orientation="horizontal">Hello</wa-card>')
    ),
    list(
      name = "actions",
      tag = shiny.webawesome:::wa_card("Hello", actions = "Act"),
      expected = c(
        "<wa-card>",
        "  Hello",
        '  <span slot="actions">Act</span>',
        "</wa-card>"
      )
    ),
    list(
      name = "footer",
      tag = shiny.webawesome:::wa_card("Hello", footer = "Foot"),
      expected = c(
        "<wa-card>",
        "  Hello",
        '  <span slot="footer">Foot</span>',
        "</wa-card>"
      )
    ),
    list(
      name = "footer_actions",
      tag = shiny.webawesome:::wa_card("Hello", footer_actions = "More"),
      expected = c(
        "<wa-card>",
        "  Hello",
        '  <span slot="footer-actions">More</span>',
        "</wa-card>"
      )
    ),
    list(
      name = "header",
      tag = shiny.webawesome:::wa_card("Hello", header = "Head"),
      expected = c(
        "<wa-card>",
        "  Hello",
        '  <span slot="header">Head</span>',
        "</wa-card>"
      )
    ),
    list(
      name = "header_actions",
      tag = shiny.webawesome:::wa_card("Hello", header_actions = "Set"),
      expected = c(
        "<wa-card>",
        "  Hello",
        '  <span slot="header-actions">Set</span>',
        "</wa-card>"
      )
    ),
    list(
      name = "media",
      tag = shiny.webawesome:::wa_card("Hello", media = "Media"),
      expected = c(
        "<wa-card>",
        "  Hello",
        '  <span slot="media">Media</span>',
        "</wa-card>"
      )
    )
  )

  for (case in card_cases) {
    testthat::expect_equal(case$name, case$name)
    expect_exact_html(render_html(case$tag), case$expected)
  }
})

test_that("wa_checkbox renders exact fragments for defaults and overrides", {
  checkbox_cases <- list(
    list(
      name = "default",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label"),
      expected = c('<wa-checkbox id="checkbox">Label</wa-checkbox>')
    ),
    list(
      name = "input_id",
      tag = shiny.webawesome:::wa_checkbox("cb", "Label"),
      expected = c('<wa-checkbox id="cb">Label</wa-checkbox>')
    ),
    list(
      name = "value",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", value = "yes"),
      expected = c('<wa-checkbox id="checkbox" value="yes">Label</wa-checkbox>')
    ),
    list(
      name = "checked",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", checked = TRUE),
      expected = c('<wa-checkbox id="checkbox" checked>Label</wa-checkbox>')
    ),
    list(
      name = "disabled",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", disabled = TRUE),
      expected = c('<wa-checkbox id="checkbox" disabled>Label</wa-checkbox>')
    ),
    list(
      name = "hint",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", hint = "Hint"),
      expected = c('<wa-checkbox id="checkbox" hint="Hint">Label</wa-checkbox>')
    ),
    list(
      name = "name",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", name = "choice"),
      expected = c('<wa-checkbox id="checkbox" name="choice">Label</wa-checkbox>')
    ),
    list(
      name = "custom_error",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", custom_error = "Nope"),
      expected = c('<wa-checkbox id="checkbox" custom-error="Nope">Label</wa-checkbox>')
    ),
    list(
      name = "dir",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", dir = "rtl"),
      expected = c('<wa-checkbox id="checkbox" dir="rtl">Label</wa-checkbox>')
    ),
    list(
      name = "indeterminate",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", indeterminate = TRUE),
      expected = c('<wa-checkbox id="checkbox" indeterminate>Label</wa-checkbox>')
    ),
    list(
      name = "lang",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", lang = "en"),
      expected = c('<wa-checkbox id="checkbox" lang="en">Label</wa-checkbox>')
    ),
    list(
      name = "required",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", required = TRUE),
      expected = c('<wa-checkbox id="checkbox" required>Label</wa-checkbox>')
    ),
    list(
      name = "size",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", size = "large"),
      expected = c('<wa-checkbox id="checkbox" size="large">Label</wa-checkbox>')
    ),
    list(
      name = "title",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", title = "Title"),
      expected = c('<wa-checkbox id="checkbox" title="Title">Label</wa-checkbox>')
    ),
    list(
      name = "hint_slot",
      tag = shiny.webawesome:::wa_checkbox("checkbox", "Label", hint_slot = "Hint slot"),
      expected = c(
        '<wa-checkbox id="checkbox">',
        "  Label",
        '  <span slot="hint">Hint slot</span>',
        "</wa-checkbox>"
      )
    )
  )

  for (case in checkbox_cases) {
    testthat::expect_equal(case$name, case$name)
    expect_exact_html(render_html(case$tag), case$expected)
  }
})

test_that("wa_select renders exact fragments for defaults and overrides", {
  option_tag <- make_wa_option("a", "A")

  select_cases <- list(
    list(
      name = "default",
      tag = shiny.webawesome:::wa_select("select", option_tag),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "input_id",
      tag = shiny.webawesome:::wa_select("sel", option_tag),
      expected = c(
        '<wa-select id="sel">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "value",
      tag = shiny.webawesome:::wa_select("select", option_tag, value = "a"),
      expected = c(
        '<wa-select id="select" value="a">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "disabled",
      tag = shiny.webawesome:::wa_select("select", option_tag, disabled = TRUE),
      expected = c(
        '<wa-select id="select" disabled>',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "label",
      tag = shiny.webawesome:::wa_select("select", option_tag, label = "Pick one"),
      expected = c(
        '<wa-select id="select" label="Pick one">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "hint",
      tag = shiny.webawesome:::wa_select("select", option_tag, hint = "Help"),
      expected = c(
        '<wa-select id="select" hint="Help">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "name",
      tag = shiny.webawesome:::wa_select("select", option_tag, name = "sel"),
      expected = c(
        '<wa-select id="select" name="sel">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "appearance",
      tag = shiny.webawesome:::wa_select("select", option_tag, appearance = "filled"),
      expected = c(
        '<wa-select id="select" appearance="filled">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "custom_error",
      tag = shiny.webawesome:::wa_select("select", option_tag, custom_error = "Nope"),
      expected = c(
        '<wa-select id="select" custom-error="Nope">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "dir",
      tag = shiny.webawesome:::wa_select("select", option_tag, dir = "rtl"),
      expected = c(
        '<wa-select id="select" dir="rtl">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "lang",
      tag = shiny.webawesome:::wa_select("select", option_tag, lang = "en"),
      expected = c(
        '<wa-select id="select" lang="en">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "max_options_visible",
      tag = shiny.webawesome:::wa_select("select", option_tag, max_options_visible = 5),
      expected = c(
        '<wa-select id="select" max-options-visible="5">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "multiple",
      tag = shiny.webawesome:::wa_select("select", option_tag, multiple = TRUE),
      expected = c(
        '<wa-select id="select" multiple>',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "open",
      tag = shiny.webawesome:::wa_select("select", option_tag, open = TRUE),
      expected = c(
        '<wa-select id="select" open>',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "pill",
      tag = shiny.webawesome:::wa_select("select", option_tag, pill = TRUE),
      expected = c(
        '<wa-select id="select" pill>',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "placeholder",
      tag = shiny.webawesome:::wa_select(
        "select",
        option_tag,
        placeholder = "Select one"
      ),
      expected = c(
        '<wa-select id="select" placeholder="Select one">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "placement",
      tag = shiny.webawesome:::wa_select("select", option_tag, placement = "top"),
      expected = c(
        '<wa-select id="select" placement="top">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "required",
      tag = shiny.webawesome:::wa_select("select", option_tag, required = TRUE),
      expected = c(
        '<wa-select id="select" required>',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "size",
      tag = shiny.webawesome:::wa_select("select", option_tag, size = "large"),
      expected = c(
        '<wa-select id="select" size="large">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "with_clear",
      tag = shiny.webawesome:::wa_select("select", option_tag, with_clear = TRUE),
      expected = c(
        '<wa-select id="select" with-clear>',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "clear_icon",
      tag = shiny.webawesome:::wa_select("select", option_tag, clear_icon = "X"),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="clear-icon">X</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "end",
      tag = shiny.webawesome:::wa_select("select", option_tag, end = "End"),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="end">End</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "expand_icon",
      tag = shiny.webawesome:::wa_select("select", option_tag, expand_icon = "Expand"),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="expand-icon">Expand</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "hint_slot",
      tag = shiny.webawesome:::wa_select("select", option_tag, hint_slot = "Hint slot"),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="hint">Hint slot</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "label_slot",
      tag = shiny.webawesome:::wa_select("select", option_tag, label_slot = "Label slot"),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="label">Label slot</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "start",
      tag = shiny.webawesome:::wa_select("select", option_tag, start = "Start"),
      expected = c(
        '<wa-select id="select">',
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="start">Start</span>',
        "</wa-select>"
      )
    )
  )

  for (case in select_cases) {
    testthat::expect_equal(case$name, case$name)
    expect_exact_html(render_html(case$tag), case$expected)
  }
})

test_that("update_wa_select sends only non-null values", {
  seen <- new.env(parent = emptyenv())
  session <- list(
    sendInputMessage = function(input_id, message) {
      seen$input_id <- input_id
      seen$message <- message
    }
  )

  shiny.webawesome:::update_wa_select(
    session = session,
    input_id = "sel",
    value = "a",
    label = NULL,
    hint = "Help",
    disabled = TRUE
  )

  testthat::expect_equal(seen$input_id, "sel")
  testthat::expect_equal(
    seen$message,
    list(value = "a", hint = "Help", disabled = TRUE)
  )
})

test_that("new heuristic-classified wrappers render expected fragments", {
  radio_a <- make_wa_radio("alpha", "Alpha")
  radio_b <- make_wa_radio("beta", "Beta")

  expect_exact_html(
    render_html(shiny.webawesome:::wa_switch("sw", "On")),
    c('<wa-switch id="sw">On</wa-switch>')
  )

  expect_exact_html(
    render_html(shiny.webawesome:::wa_rating("rating", value = 3)),
    c('<wa-rating id="rating" value="3"></wa-rating>')
  )

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

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_input(
        "text_input",
        placeholder = "Type here"
      )
    ),
    c('<wa-input id="text_input" placeholder="Type here"></wa-input>')
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_textarea(
        "text_area",
        label = "Notes"
      )
    ),
    c('<wa-textarea id="text_area" label="Notes"></wa-textarea>')
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_slider(
        "slider",
        min = 0,
        max = 10,
        value = 2
      )
    ),
    c('<wa-slider id="slider" value="2" max="10" min="0"></wa-slider>')
  )
})

test_that("new update helpers send only non-null values", {
  seen <- new.env(parent = emptyenv())
  session <- list(
    sendInputMessage = function(input_id, message) {
      seen$input_id <- input_id
      seen$message <- message
    }
  )

  shiny.webawesome:::update_wa_input(
    session = session,
    input_id = "text_input",
    value = "alpha",
    label = NULL,
    hint = "Help",
    disabled = TRUE
  )
  testthat::expect_equal(seen$input_id, "text_input")
  testthat::expect_equal(
    seen$message,
    list(value = "alpha", hint = "Help", disabled = TRUE)
  )

  shiny.webawesome:::update_wa_textarea(
    session = session,
    input_id = "text_area",
    value = "beta",
    label = "Notes",
    hint = NULL,
    disabled = NULL
  )
  testthat::expect_equal(seen$input_id, "text_area")
  testthat::expect_equal(
    seen$message,
    list(value = "beta", label = "Notes")
  )

  shiny.webawesome:::update_wa_slider(
    session = session,
    input_id = "slider",
    value = 7,
    label = "Range",
    hint = "Slide",
    disabled = NULL
  )
  testthat::expect_equal(seen$input_id, "slider")
  testthat::expect_equal(
    seen$message,
    list(value = 7, label = "Range", hint = "Slide")
  )
})
