test_that("wa_carousel_item defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_carousel_item("Slide")),
    c("<wa-carousel-item>Slide</wa-carousel-item>")
  )
})

test_that("wa_carousel_item override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_carousel_item(
        "Slide",
        id = "slide-1",
        dir = "rtl",
        lang = "en"
      )
    ),
    c(
      paste0(
        '<wa-carousel-item id="slide-1" dir="rtl" lang="en">',
        "Slide</wa-carousel-item>"
      )
    )
  )
})
