source(file.path("..", "..", "check_interactive.R"))

testthat::test_that("check_interactive prints help", {
  result <- paste(capture.output(run_check_interactive("--help")), collapse = "\n")

  testthat::expect_match(result, "Usage: ./tools/check_interactive.R")
  testthat::expect_match(result, "--host")
  testthat::expect_match(result, "--port")
})

testthat::test_that("check_interactive rejects invalid port values", {
  testthat::expect_error(
    .parse_check_interactive_args(c("--port", "abc")),
    "`--port` must be a positive integer"
  )
})
