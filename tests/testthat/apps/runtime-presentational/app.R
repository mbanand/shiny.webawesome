library(htmltools)
library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)
source(file.path("..", "harness_helpers.R"))

sections <- list(
  list(title = "wa_avatar", section_id = "wa_avatar-section"),
  list(title = "wa_badge", section_id = "wa_badge-section"),
  list(title = "wa_button", section_id = "wa_button-section"),
  list(title = "wa_callout", section_id = "wa_callout-section"),
  list(title = "wa_card", section_id = "wa_card-section"),
  list(title = "wa_copy_button", section_id = "wa_copy_button-section"),
  list(title = "wa_divider", section_id = "wa_divider-section"),
  list(title = "wa_popover", section_id = "wa_popover-section"),
  list(title = "wa_popup", section_id = "wa_popup-section"),
  list(title = "wa_tag", section_id = "wa_tag-section"),
  list(title = "wa_tooltip", section_id = "wa_tooltip-section"),
  list(title = "wa_tree_item", section_id = "wa_tree_item-section")
)

ui <- wa_page(
  title = "Presentational Runtime Harness",
  tags$style(HTML("
    .runtime-shell {
      margin: 0 auto;
      max-width: 1100px;
      padding: 2rem 1.25rem 3rem;
    }

    .runtime-title {
      margin-bottom: 0.5rem;
      text-align: center;
    }

    .runtime-intro {
      margin: 0 auto 1.75rem;
      max-width: 48rem;
      text-align: center;
    }

    .component-index-nav {
      background: #f8fafc;
      border: 1px solid #d7dee7;
      border-radius: 1rem;
      margin-bottom: 2rem;
      padding: 1.25rem;
    }

    .component-index-grid {
      display: grid;
      gap: 0.75rem;
      grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr));
    }

    .component-index-link {
      background: white;
      border: 1px solid #d7dee7;
      border-radius: 0.75rem;
      color: #0f172a;
      display: block;
      font-weight: 600;
      padding: 0.75rem 0.9rem;
      text-decoration: none;
    }

    .component-index-link:hover {
      border-color: #94a3b8;
      text-decoration: underline;
    }

    .component-section {
      border-top: 1px solid #d7dee7;
      padding: 2rem 0;
      scroll-margin-top: 1.5rem;
    }

    .component-section-heading {
      align-items: baseline;
      display: flex;
      gap: 1rem;
      justify-content: space-between;
    }

    .back-to-top {
      font-size: 0.95rem;
      white-space: nowrap;
    }

    .component-description,
    .component-notes {
      max-width: 56rem;
    }

    .component-body {
      display: grid;
      gap: 1rem;
      grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
    }

    .component-demo-panel,
    .component-state-panel {
      background: #ffffff;
      border: 1px solid #d7dee7;
      border-radius: 1rem;
      padding: 1rem;
    }
  ")),
  tags$main(
    id = "runtime-top",
    class = "runtime-shell",
    tags$h1(class = "runtime-title", "Presentational Runtime Harness"),
    tags$p(
      class = "runtime-intro",
      paste(
        "This harness supports both manual browser inspection and automated",
        "shinytest2 coverage for presentational Web Awesome components that",
        "do not expose default Shiny input bindings."
      )
    ),
    component_index(sections),
    component_section(
      section_id = "wa_avatar-section",
      title = "wa_avatar",
      description = paste(
        "Inspect the rendered avatar markup and upgraded custom element."
      ),
      component_tag = wa_avatar(
        id = "avatar",
        initials = "AV",
        label = "Avatar"
      ),
      observed_output = "avatar_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_badge-section",
      title = "wa_badge",
      description = paste(
        "Inspect the rendered badge content and upgraded custom element."
      ),
      component_tag = wa_badge("Beta", id = "badge", variant = "brand"),
      observed_output = "badge_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_button-section",
      title = "wa_button",
      description = paste(
        "Inspect the rendered button content and upgraded custom element."
      ),
      component_tag = wa_button("button", "Run", variant = "brand"),
      observed_output = "button_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_callout-section",
      title = "wa_callout",
      description = paste(
        "Inspect the rendered callout content and upgraded custom element."
      ),
      component_tag = wa_callout(
        "Heads up",
        id = "callout",
        appearance = "outlined"
      ),
      observed_output = "callout_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_card-section",
      title = "wa_card",
      description = paste(
        "Inspect the rendered card slots and upgraded custom element."
      ),
      component_tag = tagAppendAttributes(
        wa_card("Card body", header = "Card header"),
        id = "card"
      ),
      observed_output = "card_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_copy_button-section",
      title = "wa_copy_button",
      description = paste(
        "Inspect the rendered copy button and upgraded custom element."
      ),
      component_tag = wa_copy_button(
        "Copy",
        id = "copy_button",
        value = "Copy me"
      ),
      observed_output = "copy_button_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_divider-section",
      title = "wa_divider",
      description = "Inspect the rendered divider and upgraded custom element.",
      component_tag = wa_divider(id = "divider"),
      observed_output = "divider_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_popover-section",
      title = "wa_popover",
      description = paste(
        "Inspect the rendered popover body and attached target relationship."
      ),
      component_tag = htmltools::tagList(
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
      observed_output = "popover_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_popup-section",
      title = "wa_popup",
      description = paste(
        "Inspect the rendered popup body and upgraded custom element."
      ),
      component_tag = wa_popup("Popup body", id = "popup"),
      observed_output = "popup_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_tag-section",
      title = "wa_tag",
      description = paste(
        "Inspect the rendered tag content and upgraded custom element."
      ),
      component_tag = wa_tag("Tag", id = "tag", variant = "brand"),
      observed_output = "tag_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_tooltip-section",
      title = "wa_tooltip",
      description = paste(
        "Inspect the rendered tooltip body and attached target relationship."
      ),
      component_tag = htmltools::tagList(
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
      observed_output = "tooltip_state",
      notes = "No default Shiny input contract."
    ),
    component_section(
      section_id = "wa_tree_item-section",
      title = "wa_tree_item",
      description = paste(
        "Inspect the rendered tree item markup and upgraded custom element."
      ),
      component_tag = wa_tree_item("Standalone item", id = "tree_item"),
      observed_output = "tree_item_state",
      notes = "No default Shiny input contract."
    )
  )
)

server <- function(input, output, session) {
  # These helpers are sourced from ../harness_helpers.R for reuse across
  # runtime harness apps, so static linting cannot resolve them here.
  # nolint start: object_usage_linter
  bind_presentational_state <- function(output_id, component_label, element_id) {
    output[[output_id]] <- renderText({
      format_runtime_state(component_label, paste0("#", element_id))
    })
  }

  bind_presentational_state("avatar_state", "component", "avatar")
  bind_presentational_state("badge_state", "component", "badge")
  bind_presentational_state("button_state", "component", "button")
  bind_presentational_state("callout_state", "component", "callout")
  bind_presentational_state("card_state", "component", "card")
  bind_presentational_state("copy_button_state", "component", "copy_button")
  bind_presentational_state("divider_state", "component", "divider")
  bind_presentational_state("popover_state", "component", "popover")
  bind_presentational_state("popup_state", "component", "popup")
  bind_presentational_state("tag_state", "component", "tag")
  bind_presentational_state("tooltip_state", "component", "tooltip")
  bind_presentational_state("tree_item_state", "component", "tree_item")
  # nolint end
}

shinyApp(ui, server)
