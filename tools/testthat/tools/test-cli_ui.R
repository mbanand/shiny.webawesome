source(file.path("..", "..", "cli_ui.R"))

testthat::test_that("plain CLI lines can include trailing comments", {
  testthat::expect_equal(
    .cli_plain_line(
      label = "Pruning Web Awesome",
      status = "Done",
      status_col = 40L,
      comment = "[report: reports/prune/3.3.1/summary.md]"
    ),
    paste0(
      "Pruning Web Awesome ",
      strrep(".", 16L),
      " Done    [report: reports/prune/3.3.1/summary.md]"
    )
  )
})
