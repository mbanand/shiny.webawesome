library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)

ui <- wa_page(
  title = "Command Layer Harness",
  tags$main(
    class = "wa-stack wa-gap-m",
    actionButton("open_dialog", "Open dialog"),
    actionButton("close_dialog", "Close dialog"),
    actionButton("update_input_label", "Update input label"),
    actionButton("show_details", "Show details"),
    actionButton("hide_details", "Hide details"),
    actionButton("set_checkbox_error", "Set checkbox validity"),
    actionButton("clear_checkbox_error", "Clear checkbox validity"),
    wa_dialog(
      input_id = "dialog",
      "Dialog body",
      label = "Command layer dialog"
    ),
    wa_input(
      input_id = "text_input",
      label = "Before",
      value = "alpha"
    ),
    wa_details(
      input_id = "details",
      "Details body",
      summary = "Command layer details"
    ),
    wa_checkbox(
      input_id = "check",
      value = "yes",
      "Accept terms"
    ),
    verbatimTextOutput("dialog_state"),
    verbatimTextOutput("details_state")
  )
)

server <- function(input, output, session) {
  observeEvent(input$open_dialog, {
    shiny.webawesome::wa_set_property("dialog", "open", TRUE, session = session)
  })

  observeEvent(input$close_dialog, {
    shiny.webawesome::wa_set_property(
      "dialog",
      "open",
      FALSE,
      session = session
    )
  })

  observeEvent(input$update_input_label, {
    shiny.webawesome::wa_set_property(
      "text_input",
      "label",
      "After",
      session = session
    )
  })

  observeEvent(input$show_details, {
    shiny.webawesome::wa_call_method("details", "show", session = session)
  })

  observeEvent(input$hide_details, {
    shiny.webawesome::wa_call_method("details", "hide", session = session)
  })

  observeEvent(input$set_checkbox_error, {
    shiny.webawesome::wa_call_method(
      "check",
      "setCustomValidity",
      args = list("Please accept the terms."),
      session = session
    )
  })

  observeEvent(input$clear_checkbox_error, {
    shiny.webawesome::wa_call_method(
      "check",
      "setCustomValidity",
      args = list(""),
      session = session
    )
  })

  output$dialog_state <- renderText({
    paste0("input$dialog = ", deparse(input$dialog))
  })

  output$details_state <- renderText({
    paste0("input$details = ", deparse(input$details))
  })
}

shinyApp(ui, server)
