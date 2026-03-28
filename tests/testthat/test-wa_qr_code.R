test_that("wa_qr_code defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_qr_code()),
    c("<wa-qr-code></wa-qr-code>")
  )
})

test_that("wa_qr_code override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_qr_code(
        id = "qr",
        value = "https://example.com",
        label = "QR",
        background = "white",
        error_correction = "M",
        fill = "black",
        radius = 0.25,
        size = 256
      )
    ),
    c(
      paste0(
        '<wa-qr-code id="qr" value="https://example.com" label="QR" ',
        'background="white" error-correction="M" fill="black" ',
        'radius="0.25" size="256"></wa-qr-code>'
      )
    )
  )
})

test_that("wa_qr_code error correction validates exactly", {
  expect_error(
    shiny.webawesome:::wa_qr_code(error_correction = "X"),
    "`error_correction` must be one of ",
    fixed = TRUE
  )
})
