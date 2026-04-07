library(shiny)
library(shiny.webawesome) # nolint: object_usage_linter.

ui <- webawesomePage(
  title = "Binding example",
  wa_container(
    class = "wa-stack",
    wa_select(
      "favorite_letter",
      wa_option("A", value = "a"),
      wa_option("B", value = "b"),
      wa_option("C", value = "c")
    ),
    wa_switch("notifications_enabled", "Notifications"),
    wa_tree(
      "navigation_tree",
      selection = "multiple",
      wa_tree_item("Section A", id = "section_a"),
      wa_tree_item("Section B", id = "section_b"),
      wa_tree_item("Section C", id = "section_c")
    ),
    verbatimTextOutput("state")
  )
)

server <- function(input, output, session) {
  output$state <- renderPrint({
    list(
      favorite_letter = input$favorite_letter,
      notifications_enabled = input$notifications_enabled,
      navigation_tree = input$navigation_tree
    )
  })
}

shinyApp(ui, server)
