library(htmltools)
library(shiny)
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

ui <- wa_page(
  title = "Representative runtime",
  tagAppendAttributes(
    wa_card(
      "Card body",
      header = "Card header"
    ),
    id = "card"
  ),
  wa_checkbox(
    "Accept terms",
    input_id = "checkbox",
    value = "accepted"
  ),
  wa_switch(
    input_id = "switch",
    "Enable notifications",
    value = "enabled"
  ),
  wa_rating(
    input_id = "rating",
    value = 2
  ),
  wa_radio_group(
    input_id = "radio_group",
    make_wa_radio("alpha", "Alpha"),
    make_wa_radio("beta", "Beta"),
    label = "Pick one"
  ),
  wa_select(
    make_wa_option("a", "Alpha"),
    make_wa_option("b", "Beta"),
    input_id = "select",
    label = "Pick one"
  ),
  wa_input(
    input_id = "text_input",
    label = "Input label"
  ),
  wa_textarea(
    input_id = "text_area",
    label = "Textarea label"
  ),
  wa_slider(
    input_id = "slider",
    label = "Slider label",
    min = 0,
    max = 10,
    value = 2
  ),
  actionButton("update_select", "Update select"),
  actionButton("update_input", "Update input"),
  actionButton("update_textarea", "Update textarea"),
  actionButton("update_slider", "Update slider"),
  verbatimTextOutput("checkbox_value"),
  verbatimTextOutput("switch_value"),
  verbatimTextOutput("rating_value"),
  verbatimTextOutput("radio_group_value"),
  verbatimTextOutput("select_value")
  ,
  verbatimTextOutput("text_input_value"),
  verbatimTextOutput("text_area_value"),
  verbatimTextOutput("slider_value")
)

server <- function(input, output, session) {
  output$checkbox_value <- renderText({
    if (is.null(input$checkbox)) {
      return("<null>")
    }

    if (isTRUE(input$checkbox)) {
      return("TRUE")
    }

    "FALSE"
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

  output$switch_value <- renderText({
    if (is.null(input$switch)) {
      return("<null>")
    }

    if (isTRUE(input$switch)) {
      return("TRUE")
    }

    "FALSE"
  })

  output$rating_value <- renderText({
    if (is.null(input$rating) || identical(input$rating, "")) {
      return("<null>")
    }

    as.character(input$rating)
  })

  output$radio_group_value <- renderText({
    if (is.null(input$radio_group) || identical(input$radio_group, "")) {
      return("<null>")
    }

    input$radio_group
  })

  output$text_input_value <- renderText({
    if (is.null(input$text_input) || identical(input$text_input, "")) {
      return("<null>")
    }

    input$text_input
  })

  output$text_area_value <- renderText({
    if (is.null(input$text_area) || identical(input$text_area, "")) {
      return("<null>")
    }

    input$text_area
  })

  output$slider_value <- renderText({
    if (is.null(input$slider) || identical(input$slider, "")) {
      return("<null>")
    }

    as.character(input$slider)
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

  observeEvent(input$update_input, {
    update_wa_input(
      session = session,
      input_id = "text_input",
      value = "beta",
      label = "Updated input label",
      hint = "Updated input hint"
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

  observeEvent(input$update_slider, {
    update_wa_slider(
      session = session,
      input_id = "slider",
      value = 7,
      label = "Updated slider label",
      hint = "Updated slider hint"
    )
  })
}

shinyApp(ui, server)
