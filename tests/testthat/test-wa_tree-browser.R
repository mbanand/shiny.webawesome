test_that(
  "wa_tree keeps selected ids and warning behavior aligned in the tree harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-tree")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, c("wa-tree", "wa-tree-item"))

    testthat::expect_match(
      app$get_text("#wa_tree-section h2"),
      "wa_tree"
    )

    app$run_js(
      paste(
        "const el = document.getElementById('tree');",
        "const itemA = document.getElementById('tree_item_a');",
        "const itemB = document.getElementById('tree_item_b');",
        "el.dispatchEvent(new CustomEvent('wa-selection-change', {",
        "  bubbles: true,",
        "  detail: { selection: [itemA, itemB] }",
        "}));"
      )
    )

    wait_for_shiny_input(
      app,
      input = "tree",
      expected = c("tree_item_a", "tree_item_b")
    )

    testthat::expect_equal(
      app$get_value(input = "tree"),
      c("tree_item_a", "tree_item_b")
    )
    testthat::expect_match(
      app$get_text("#tree_contract_state"),
      'input\\$tree = c\\("tree_item_a", "tree_item_b"\\)'
    )

    app$run_js(
      paste(
        "const el = document.getElementById('tree_warning');",
        "const missing = el.querySelector('wa-tree-item:not([id])');",
        "const present = document.getElementById('tree_warning_present');",
        "el.dispatchEvent(new CustomEvent('wa-selection-change', {",
        "  bubbles: true,",
        "  detail: { selection: [missing, present] }",
        "}));"
      )
    )

    wait_for_shiny_input(
      app,
      input = "tree_warning",
      expected = "tree_warning_present"
    )
    wait_for_shiny_input(app, input = "tree_warning_count", expected = 1)
    app$wait_for_value(input = "tree_warning_log", ignore = list(NULL, ""))

    testthat::expect_equal(
      app$get_value(input = "tree_warning"),
      "tree_warning_present"
    )
    testthat::expect_equal(app$get_value(input = "tree_warning_count"), 1)
    testthat::expect_match(
      app$get_value(input = "tree_warning_log"),
      "omitted selected items without DOM ids"
    )
    testthat::expect_match(
      app$get_value(input = "tree_warning_log"),
      "`tree_warning`"
    )
    testthat::expect_match(
      app$get_text("#tree_contract_state"),
      'input\\$tree_warning = "tree_warning_present"'
    )

    app$run_js(
      paste(
        "const el = document.getElementById('tree_warning');",
        "const missing = el.querySelector('wa-tree-item:not([id])');",
        "el.dispatchEvent(new CustomEvent('wa-selection-change', {",
        "  bubbles: true,",
        "  detail: { selection: [missing] }",
        "}));"
      )
    )

    wait_for_shiny_input(app, input = "tree_warning", expected = NULL)

    testthat::expect_null(app$get_value(input = "tree_warning"))
    testthat::expect_equal(app$get_value(input = "tree_warning_count"), 1)
  }
)
