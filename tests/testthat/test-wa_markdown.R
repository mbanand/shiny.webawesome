test_that("wa_markdown defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_markdown()),
    c("<wa-markdown></wa-markdown>")
  )
})

test_that("wa_markdown renders child content and attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_markdown(
        "# Heading",
        id = "markdown",
        class = "prose",
        style = "max-width: 60ch;",
        dir = "ltr",
        lang = "en",
        tab_size = 2
      )
    ),
    c(
      paste0(
        '<wa-markdown id="markdown" class="prose" ',
        'style="max-width: 60ch;" dir="ltr" lang="en" ',
        'tab-size="2"># Heading</wa-markdown>'
      )
    )
  )
})
