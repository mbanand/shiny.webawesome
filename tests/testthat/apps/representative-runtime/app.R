library(htmltools)
library(shiny)
library(shiny.webawesome)

make_wa_option <- function(value, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-option", label),
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
    id = "checkbox",
    value = "accepted"
  ),
  wa_select(
    make_wa_option("a", "Alpha"),
    make_wa_option("b", "Beta"),
    id = "select",
    label = "Pick one"
  ),
  actionButton("update_select", "Update select"),
  verbatimTextOutput("checkbox_value"),
  verbatimTextOutput("select_value")
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

  observeEvent(input$update_select, {
    update_wa_select(
      session = session,
      input_id = "select",
      value = "b",
      label = "Updated label",
      hint = "Updated hint"
    )
  })
}

shinyApp(ui, server)
