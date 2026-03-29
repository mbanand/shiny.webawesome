library(htmltools)
library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)
source(file.path("..", "harness_helpers.R"))

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

sections <- list(
  list(
    title = "wa_checkbox",
    section_id = "wa_checkbox-section"
  ),
  list(
    title = "wa_color_picker",
    section_id = "wa_color_picker-section"
  ),
  list(
    title = "wa_input",
    section_id = "wa_input-section"
  ),
  list(
    title = "wa_number_input",
    section_id = "wa_number_input-section"
  ),
  list(
    title = "wa_rating",
    section_id = "wa_rating-section"
  ),
  list(
    title = "wa_radio_group",
    section_id = "wa_radio_group-section"
  ),
  list(
    title = "wa_select",
    section_id = "wa_select-section"
  ),
  list(
    title = "wa_slider",
    section_id = "wa_slider-section"
  ),
  list(
    title = "wa_switch",
    section_id = "wa_switch-section"
  ),
  list(
    title = "wa_textarea",
    section_id = "wa_textarea-section"
  )
)

ui <- wa_page(
  title = "Semantic Runtime Harness",
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

    .component-controls {
      margin-top: 1rem;
    }

    .component-controls .btn,
    .component-controls button {
      margin-right: 0.75rem;
    }
  ")),
  tags$main(
    id = "runtime-top",
    class = "runtime-shell",
    tags$h1(class = "runtime-title", "Semantic Runtime Harness"),
    tags$p(
      class = "runtime-intro",
      paste(
        "This harness supports both manual browser inspection and automated",
        "shinytest2 coverage for durable-value Web Awesome inputs."
      )
    ),
    component_index(sections),
    component_section(
      section_id = "wa_checkbox-section",
      title = "wa_checkbox",
      description = paste(
        "Toggle the checkbox and observe that the Shiny input tracks the",
        "durable boolean checked state."
      ),
      component_tag = wa_checkbox(
        "Accept terms",
        input_id = "checkbox",
        value = "accepted"
      ),
      observed_output = "checkbox_state"
    ),
    component_section(
      section_id = "wa_color_picker-section",
      title = "wa_color_picker",
      description = paste(
        "Change the selected color in the picker and observe that the durable",
        "Shiny input value updates to match the current browser state."
      ),
      component_tag = wa_color_picker(
        input_id = "color_picker",
        label = "Accent color",
        value = "#112233"
      ),
      observed_output = "color_picker_state"
    ),
    component_section(
      section_id = "wa_input-section",
      title = "wa_input",
      description = paste(
        "Type a new string into the input or use the update button to observe",
        "the bound Shiny value and the browser-side label and hint updates."
      ),
      component_tag = wa_input(
        input_id = "text_input",
        label = "Search term",
        hint = "Start typing",
        value = "alpha"
      ),
      observed_output = "text_input_state",
      controls = actionButton("update_text_input", "Update wa_input")
    ),
    component_section(
      section_id = "wa_number_input-section",
      title = "wa_number_input",
      description = paste(
        "Change the number value directly or use the update button to verify",
        "that numeric-looking input is transported as the component's durable",
        "Shiny value."
      ),
      component_tag = wa_number_input(
        input_id = "number_input",
        label = "Quantity",
        hint = "Choose a number",
        min = 0,
        max = 10,
        value = 2
      ),
      observed_output = "number_input_state",
      controls = actionButton("update_number_input", "Update wa_number_input")
    ),
    component_section(
      section_id = "wa_rating-section",
      title = "wa_rating",
      description = paste(
        "Change the rating value and observe that the Shiny input tracks the",
        "durable numeric rating state."
      ),
      component_tag = wa_rating(
        input_id = "rating",
        value = 2
      ),
      observed_output = "rating_state"
    ),
    component_section(
      section_id = "wa_radio_group-section",
      title = "wa_radio_group",
      description = paste(
        "Choose a radio option and observe that the Shiny input stores the",
        "currently selected durable value."
      ),
      component_tag = wa_radio_group(
        input_id = "radio_group",
        make_wa_radio("alpha", "Alpha"),
        make_wa_radio("beta", "Beta"),
        label = "Pick one"
      ),
      observed_output = "radio_group_state"
    ),
    component_section(
      section_id = "wa_select-section",
      title = "wa_select",
      description = paste(
        "Select a different option from the menu or use the update button to",
        "observe the selected durable value along with label and hint updates."
      ),
      component_tag = wa_select(
        make_wa_option("a", "Alpha"),
        make_wa_option("b", "Beta"),
        input_id = "select",
        label = "Pick one",
        hint = "Choose an option",
        value = "a"
      ),
      observed_output = "select_state",
      controls = actionButton("update_select", "Update wa_select")
    ),
    component_section(
      section_id = "wa_slider-section",
      title = "wa_slider",
      description = paste(
        "Move the slider thumb or use the update button to observe the durable",
        "Shiny value and the browser-side label and hint changes."
      ),
      component_tag = wa_slider(
        input_id = "slider",
        label = "Volume",
        hint = "Drag the thumb",
        min = 0,
        max = 10,
        value = 2
      ),
      observed_output = "slider_state",
      controls = actionButton("update_slider", "Update wa_slider")
    ),
    component_section(
      section_id = "wa_switch-section",
      title = "wa_switch",
      description = paste(
        "Toggle the switch and observe that the Shiny input tracks the",
        "durable boolean checked state."
      ),
      component_tag = wa_switch(
        input_id = "switch",
        "Enable notifications",
        value = "enabled"
      ),
      observed_output = "switch_state"
    ),
    component_section(
      section_id = "wa_textarea-section",
      title = "wa_textarea",
      description = paste(
        "Type new text or use the update button to observe the durable Shiny",
        "value and the browser-side label and hint updates."
      ),
      component_tag = wa_textarea(
        input_id = "text_area",
        label = "Textarea label",
        hint = "Start typing",
        value = "alpha"
      ),
      observed_output = "text_area_state",
      controls = actionButton("update_textarea", "Update wa_textarea")
    )
  )
)

server <- function(input, output, session) {
  # These helpers are sourced from ../harness_helpers.R for reuse across
  # runtime harness apps, so static linting cannot resolve them here.
  # nolint start: object_usage_linter
  bind_runtime_state <- function(output_id, input_id) {
    output[[output_id]] <- renderText({
      format_runtime_state(
        sprintf("input$%s", input_id),
        input[[input_id]]
      )
    })

    observeEvent(input[[input_id]], ignoreInit = FALSE, {
      log_runtime_state(
        input_id,
        format_runtime_state(
          sprintf("input$%s", input_id),
          input[[input_id]]
        )
      )
    })
  }

  bind_runtime_state("color_picker_state", "color_picker")
  bind_runtime_state("checkbox_state", "checkbox")
  bind_runtime_state("text_input_state", "text_input")
  bind_runtime_state("number_input_state", "number_input")
  bind_runtime_state("rating_state", "rating")
  bind_runtime_state("radio_group_state", "radio_group")
  bind_runtime_state("select_state", "select")
  bind_runtime_state("slider_state", "slider")
  bind_runtime_state("switch_state", "switch")
  bind_runtime_state("text_area_state", "text_area")
  # nolint end

  observeEvent(input$update_text_input, {
    shiny.webawesome::update_wa_input(
      session = session,
      input_id = "text_input",
      value = "beta",
      label = "Updated search term",
      hint = "Updated input hint"
    )
  })

  observeEvent(input$update_number_input, {
    shiny.webawesome::update_wa_number_input(
      session = session,
      input_id = "number_input",
      value = 6,
      label = "Updated quantity",
      hint = "Updated number hint"
    )
  })

  observeEvent(input$update_select, {
    shiny.webawesome::update_wa_select(
      session = session,
      input_id = "select",
      value = "b",
      label = "Updated picker",
      hint = "Updated select hint"
    )
  })

  observeEvent(input$update_slider, {
    shiny.webawesome::update_wa_slider(
      session = session,
      input_id = "slider",
      value = 7,
      label = "Updated volume",
      hint = "Updated slider hint"
    )
  })

  observeEvent(input$update_textarea, {
    shiny.webawesome::update_wa_textarea(
      session = session,
      input_id = "text_area",
      value = "gamma",
      label = "Updated textarea label",
      hint = "Updated textarea hint"
    )
  })
}

shinyApp(ui, server)
