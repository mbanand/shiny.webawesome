library(htmltools)
library(shiny)
# Representative harness apps load the local package in a way static linting
# cannot fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)

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

make_wa_tab <- function(panel, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-tab", label),
    panel = panel
  )
}

make_wa_tab_panel <- function(name, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-tab-panel", label),
    name = name
  )
}

ui <- wa_page(
  title = "Representative runtime",
  wa_avatar(
    id = "avatar",
    initials = "AV",
    label = "Avatar"
  ),
  wa_badge(
    "Beta",
    id = "badge",
    variant = "brand"
  ),
  wa_button(
    "button",
    "Run",
    variant = "brand"
  ),
  wa_callout(
    "Heads up",
    id = "callout",
    appearance = "outlined"
  ),
  tagAppendAttributes(
    wa_card(
      "Card body",
      header = "Card header"
    ),
    id = "card"
  ),
  wa_carousel(
    input_id = "carousel",
    htmltools::tag("wa-carousel-item", "Slide 1"),
    htmltools::tag("wa-carousel-item", "Slide 2")
  ),
  wa_checkbox(
    "Accept terms",
    input_id = "checkbox",
    value = "accepted"
  ),
  wa_color_picker(
    input_id = "color_picker",
    label = "Color",
    value = "#112233"
  ),
  wa_copy_button(
    "Copy",
    id = "copy_button",
    value = "Copy me"
  ),
  wa_details(
    input_id = "details",
    "Details body",
    summary = "More"
  ),
  wa_dialog(
    input_id = "dialog",
    "Dialog body",
    label = "Dialog title"
  ),
  wa_drawer(
    input_id = "drawer",
    "Drawer body",
    label = "Drawer title"
  ),
  wa_divider(id = "divider"),
  wa_input(
    input_id = "text_input",
    label = "Input label"
  ),
  wa_number_input(
    input_id = "number_input",
    label = "Number label",
    max = 10,
    min = 0,
    value = 2
  ),
  htmltools::tagList(
    tags$button(
      id = "popover_target",
      type = "button",
      "Popover target"
    ),
    wa_popover(
      "Popover body",
      id = "popover",
      `for` = "popover_target",
      placement = "top"
    )
  ),
  wa_popup(
    "Popup body",
    id = "popup"
  ),
  wa_radio_group(
    input_id = "radio_group",
    make_wa_radio("alpha", "Alpha"),
    make_wa_radio("beta", "Beta"),
    label = "Pick one"
  ),
  wa_rating(
    input_id = "rating",
    value = 2
  ),
  wa_select(
    make_wa_option("a", "Alpha"),
    make_wa_option("b", "Beta"),
    input_id = "select",
    label = "Pick one"
  ),
  wa_slider(
    input_id = "slider",
    label = "Slider label",
    min = 0,
    max = 10,
    value = 2
  ),
  wa_switch(
    input_id = "switch",
    "Enable notifications",
    value = "enabled"
  ),
  wa_tab_group(
    input_id = "tab_group",
    make_wa_tab_panel("first", "First panel"),
    make_wa_tab_panel("second", "Second panel"),
    nav = htmltools::tagList(
      make_wa_tab("first", "First"),
      make_wa_tab("second", "Second")
    )
  ),
  wa_tag(
    "Tag",
    id = "tag",
    variant = "brand"
  ),
  wa_tree(
    input_id = "tree",
    wa_tree_item("Node A", id = "tree_item_a"),
    wa_tree_item("Node B", id = "tree_item_b")
  ),
  wa_textarea(
    input_id = "text_area",
    label = "Textarea label"
  ),
  htmltools::tagList(
    tags$button(
      id = "tooltip_target",
      type = "button",
      "Tooltip target"
    ),
    wa_tooltip(
      "Tooltip body",
      id = "tooltip",
      `for` = "tooltip_target",
      trigger = "manual"
    )
  ),
  actionButton("update_input", "Update input"),
  actionButton("update_number_input", "Update number input"),
  actionButton("update_select", "Update select"),
  actionButton("update_slider", "Update slider"),
  actionButton("update_textarea", "Update textarea"),
  verbatimTextOutput("carousel_value"),
  verbatimTextOutput("checkbox_value"),
  verbatimTextOutput("color_picker_value"),
  verbatimTextOutput("details_value"),
  verbatimTextOutput("dialog_value"),
  verbatimTextOutput("drawer_value"),
  verbatimTextOutput("number_input_value"),
  verbatimTextOutput("radio_group_value"),
  verbatimTextOutput("rating_value"),
  verbatimTextOutput("select_value"),
  verbatimTextOutput("slider_value"),
  verbatimTextOutput("switch_value"),
  verbatimTextOutput("tab_group_value"),
  verbatimTextOutput("text_area_value"),
  verbatimTextOutput("text_input_value"),
  verbatimTextOutput("tree_value")
)

server <- function(input, output, session) {
  output$carousel_value <- renderText({
    if (is.null(input$carousel) || identical(input$carousel, "")) {
      return("<null>")
    }

    as.character(input$carousel)
  })

  output$checkbox_value <- renderText({
    if (is.null(input$checkbox)) {
      return("<null>")
    }

    if (isTRUE(input$checkbox)) {
      return("TRUE")
    }

    "FALSE"
  })

  output$color_picker_value <- renderText({
    if (is.null(input$color_picker) || identical(input$color_picker, "")) {
      return("<null>")
    }

    input$color_picker
  })

  output$details_value <- renderText({
    if (is.null(input$details)) {
      return("<null>")
    }

    if (isTRUE(input$details)) {
      return("TRUE")
    }

    "FALSE"
  })

  output$dialog_value <- renderText({
    if (is.null(input$dialog)) {
      return("<null>")
    }

    if (isTRUE(input$dialog)) {
      return("TRUE")
    }

    "FALSE"
  })

  output$drawer_value <- renderText({
    if (is.null(input$drawer)) {
      return("<null>")
    }

    if (isTRUE(input$drawer)) {
      return("TRUE")
    }

    "FALSE"
  })

  output$number_input_value <- renderText({
    if (is.null(input$number_input) || identical(input$number_input, "")) {
      return("<null>")
    }

    as.character(input$number_input)
  })

  output$radio_group_value <- renderText({
    if (is.null(input$radio_group) || identical(input$radio_group, "")) {
      return("<null>")
    }

    input$radio_group
  })

  output$rating_value <- renderText({
    if (is.null(input$rating) || identical(input$rating, "")) {
      return("<null>")
    }

    as.character(input$rating)
  })

  output$select_value <- renderText({
    if (is.null(input$select) || identical(input$select, "")) {
      return("<null>")
    }

    if (length(input$select) > 1L) {
      return(paste(input$select, collapse = ","))
    }

    input$select
  })

  output$slider_value <- renderText({
    if (is.null(input$slider) || identical(input$slider, "")) {
      return("<null>")
    }

    as.character(input$slider)
  })

  output$switch_value <- renderText({
    if (is.null(input$switch)) {
      return("<null>")
    }

    if (isTRUE(input$switch)) {
      return("TRUE")
    }

    "FALSE"
  })

  output$tab_group_value <- renderText({
    if (is.null(input$tab_group) || identical(input$tab_group, "")) {
      return("<null>")
    }

    input$tab_group
  })

  output$text_area_value <- renderText({
    if (is.null(input$text_area) || identical(input$text_area, "")) {
      return("<null>")
    }

    input$text_area
  })

  output$text_input_value <- renderText({
    if (is.null(input$text_input) || identical(input$text_input, "")) {
      return("<null>")
    }

    input$text_input
  })

  output$tree_value <- renderText({
    if (is.null(input$tree) || length(input$tree) == 0L) {
      return("<null>")
    }

    paste(input$tree, collapse = ",")
  })

  # These update helpers are exported by the local package, but
  # object_usage_linter cannot resolve them reliably in this harness context.
  # nolint start: object_usage_linter
  observeEvent(input$update_input, {
    update_wa_input(
      session = session,
      input_id = "text_input",
      value = "beta",
      label = "Updated input label",
      hint = "Updated input hint"
    )
  })

  observeEvent(input$update_number_input, {
    update_wa_number_input(
      session = session,
      input_id = "number_input",
      value = 6,
      label = "Updated number label",
      hint = "Updated number hint"
    )
  })

  observeEvent(input$update_select, {
    update_wa_select(
      session = session,
      input_id = "select",
      value = "b",
      label = "Updated label",
      hint = "Updated hint"
    )
  })

  observeEvent(input$update_slider, {
    update_wa_slider(
      session = session,
      input_id = "slider",
      value = 7,
      label = "Updated slider label",
      hint = "Updated slider hint"
    )
  })

  observeEvent(input$update_textarea, {
    update_wa_textarea(
      session = session,
      input_id = "text_area",
      value = "gamma",
      label = "Updated textarea label",
      hint = "Updated textarea hint"
    )
  })
  # nolint end
}

shinyApp(ui, server)
