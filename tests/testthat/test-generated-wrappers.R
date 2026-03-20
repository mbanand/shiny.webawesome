make_wa_option <- function(value, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-option", label),
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
      name = "with_footer",
      tag = shiny.webawesome:::wa_card("Hello", with_footer = TRUE),
      expected = c("<wa-card with-footer>Hello</wa-card>")
    ),
    list(
      name = "with_header",
      tag = shiny.webawesome:::wa_card("Hello", with_header = TRUE),
      expected = c("<wa-card with-header>Hello</wa-card>")
    ),
    list(
      name = "with_media",
      tag = shiny.webawesome:::wa_card("Hello", with_media = TRUE),
      expected = c("<wa-card with-media>Hello</wa-card>")
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
      tag = shiny.webawesome:::wa_checkbox("Label"),
      expected = c("<wa-checkbox>Label</wa-checkbox>")
    ),
    list(
      name = "id",
      tag = shiny.webawesome:::wa_checkbox("Label", id = "cb"),
      expected = c('<wa-checkbox id="cb">Label</wa-checkbox>')
    ),
    list(
      name = "value",
      tag = shiny.webawesome:::wa_checkbox("Label", value = "yes"),
      expected = c('<wa-checkbox value="yes">Label</wa-checkbox>')
    ),
    list(
      name = "checked",
      tag = shiny.webawesome:::wa_checkbox("Label", checked = TRUE),
      expected = c("<wa-checkbox checked>Label</wa-checkbox>")
    ),
    list(
      name = "disabled",
      tag = shiny.webawesome:::wa_checkbox("Label", disabled = TRUE),
      expected = c("<wa-checkbox disabled>Label</wa-checkbox>")
    ),
    list(
      name = "hint",
      tag = shiny.webawesome:::wa_checkbox("Label", hint = "Hint"),
      expected = c('<wa-checkbox hint="Hint">Label</wa-checkbox>')
    ),
    list(
      name = "name",
      tag = shiny.webawesome:::wa_checkbox("Label", name = "choice"),
      expected = c('<wa-checkbox name="choice">Label</wa-checkbox>')
    ),
    list(
      name = "custom_error",
      tag = shiny.webawesome:::wa_checkbox("Label", custom_error = "Nope"),
      expected = c('<wa-checkbox custom-error="Nope">Label</wa-checkbox>')
    ),
    list(
      name = "dir",
      tag = shiny.webawesome:::wa_checkbox("Label", dir = "rtl"),
      expected = c('<wa-checkbox dir="rtl">Label</wa-checkbox>')
    ),
    list(
      name = "indeterminate",
      tag = shiny.webawesome:::wa_checkbox("Label", indeterminate = TRUE),
      expected = c("<wa-checkbox indeterminate>Label</wa-checkbox>")
    ),
    list(
      name = "lang",
      tag = shiny.webawesome:::wa_checkbox("Label", lang = "en"),
      expected = c('<wa-checkbox lang="en">Label</wa-checkbox>')
    ),
    list(
      name = "required",
      tag = shiny.webawesome:::wa_checkbox("Label", required = TRUE),
      expected = c("<wa-checkbox required>Label</wa-checkbox>")
    ),
    list(
      name = "size",
      tag = shiny.webawesome:::wa_checkbox("Label", size = "large"),
      expected = c('<wa-checkbox size="large">Label</wa-checkbox>')
    ),
    list(
      name = "title",
      tag = shiny.webawesome:::wa_checkbox("Label", title = "Title"),
      expected = c('<wa-checkbox title="Title">Label</wa-checkbox>')
    ),
    list(
      name = "hint_slot",
      tag = shiny.webawesome:::wa_checkbox("Label", hint_slot = "Hint slot"),
      expected = c(
        "<wa-checkbox>",
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
      tag = shiny.webawesome:::wa_select(option_tag),
      expected = c(
        "<wa-select>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "id",
      tag = shiny.webawesome:::wa_select(option_tag, id = "sel"),
      expected = c(
        '<wa-select id="sel">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "value",
      tag = shiny.webawesome:::wa_select(option_tag, value = "a"),
      expected = c(
        '<wa-select value="a">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "disabled",
      tag = shiny.webawesome:::wa_select(option_tag, disabled = TRUE),
      expected = c(
        "<wa-select disabled>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "label",
      tag = shiny.webawesome:::wa_select(option_tag, label = "Pick one"),
      expected = c(
        '<wa-select label="Pick one">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "hint",
      tag = shiny.webawesome:::wa_select(option_tag, hint = "Help"),
      expected = c(
        '<wa-select hint="Help">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "name",
      tag = shiny.webawesome:::wa_select(option_tag, name = "sel"),
      expected = c(
        '<wa-select name="sel">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "appearance",
      tag = shiny.webawesome:::wa_select(option_tag, appearance = "filled"),
      expected = c(
        '<wa-select appearance="filled">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "custom_error",
      tag = shiny.webawesome:::wa_select(option_tag, custom_error = "Nope"),
      expected = c(
        '<wa-select custom-error="Nope">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "dir",
      tag = shiny.webawesome:::wa_select(option_tag, dir = "rtl"),
      expected = c(
        '<wa-select dir="rtl">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "lang",
      tag = shiny.webawesome:::wa_select(option_tag, lang = "en"),
      expected = c(
        '<wa-select lang="en">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "max_options_visible",
      tag = shiny.webawesome:::wa_select(option_tag, max_options_visible = 5),
      expected = c(
        '<wa-select max-options-visible="5">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "multiple",
      tag = shiny.webawesome:::wa_select(option_tag, multiple = TRUE),
      expected = c(
        "<wa-select multiple>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "open",
      tag = shiny.webawesome:::wa_select(option_tag, open = TRUE),
      expected = c(
        "<wa-select open>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "pill",
      tag = shiny.webawesome:::wa_select(option_tag, pill = TRUE),
      expected = c(
        "<wa-select pill>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "placeholder",
      tag = shiny.webawesome:::wa_select(
        option_tag,
        placeholder = "Select one"
      ),
      expected = c(
        '<wa-select placeholder="Select one">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "placement",
      tag = shiny.webawesome:::wa_select(option_tag, placement = "top"),
      expected = c(
        '<wa-select placement="top">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "required",
      tag = shiny.webawesome:::wa_select(option_tag, required = TRUE),
      expected = c(
        "<wa-select required>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "size",
      tag = shiny.webawesome:::wa_select(option_tag, size = "large"),
      expected = c(
        '<wa-select size="large">',
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "with_clear",
      tag = shiny.webawesome:::wa_select(option_tag, with_clear = TRUE),
      expected = c(
        "<wa-select with-clear>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "with_hint",
      tag = shiny.webawesome:::wa_select(option_tag, with_hint = TRUE),
      expected = c(
        "<wa-select with-hint>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "with_label",
      tag = shiny.webawesome:::wa_select(option_tag, with_label = TRUE),
      expected = c(
        "<wa-select with-label>",
        '  <wa-option value="a">A</wa-option>',
        "</wa-select>"
      )
    ),
    list(
      name = "clear_icon",
      tag = shiny.webawesome:::wa_select(option_tag, clear_icon = "X"),
      expected = c(
        "<wa-select>",
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="clear-icon">X</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "end",
      tag = shiny.webawesome:::wa_select(option_tag, end = "End"),
      expected = c(
        "<wa-select>",
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="end">End</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "expand_icon",
      tag = shiny.webawesome:::wa_select(option_tag, expand_icon = "Expand"),
      expected = c(
        "<wa-select>",
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="expand-icon">Expand</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "hint_slot",
      tag = shiny.webawesome:::wa_select(option_tag, hint_slot = "Hint slot"),
      expected = c(
        "<wa-select>",
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="hint">Hint slot</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "label_slot",
      tag = shiny.webawesome:::wa_select(option_tag, label_slot = "Label slot"),
      expected = c(
        "<wa-select>",
        '  <wa-option value="a">A</wa-option>',
        '  <span slot="label">Label slot</span>',
        "</wa-select>"
      )
    ),
    list(
      name = "start",
      tag = shiny.webawesome:::wa_select(option_tag, start = "Start"),
      expected = c(
        "<wa-select>",
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
