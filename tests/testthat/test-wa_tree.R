test_that("wa_tree requires input_id", {
  expect_error(
    shiny.webawesome:::wa_tree(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_tree defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tree(
        input_id = "tree",
        shiny.webawesome:::wa_tree_item("Node A", id = "tree_item_a"),
        shiny.webawesome:::wa_tree_item("Node B", id = "tree_item_b")
      )
    ),
    c(
      '<wa-tree id="tree">',
      '  <wa-tree-item id="tree_item_a">Node A</wa-tree-item>',
      '  <wa-tree-item id="tree_item_b">Node B</wa-tree-item>',
      "</wa-tree>"
    )
  )
})

test_that("wa_tree override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tree(
        input_id = "tree",
        shiny.webawesome:::wa_tree_item("Node A", id = "tree_item_a"),
        dir = "rtl",
        lang = "en",
        selection = "multiple",
        collapse_icon = "Collapse",
        expand_icon = "Expand"
      )
    ),
    c(
      '<wa-tree id="tree" dir="rtl" lang="en" selection="multiple">',
      '  <wa-tree-item id="tree_item_a">Node A</wa-tree-item>',
      '  <span slot="collapse-icon">Collapse</span>',
      '  <span slot="expand-icon">Expand</span>',
      "</wa-tree>"
    )
  )
})

test_that("wa_tree selection enum validates exactly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tree(
        input_id = "tree",
        shiny.webawesome:::wa_tree_item("Node A", id = "tree_item_a"),
        selection = "leaf"
      )
    ),
    c(
      '<wa-tree id="tree" selection="leaf">',
      '  <wa-tree-item id="tree_item_a">Node A</wa-tree-item>',
      "</wa-tree>"
    )
  )

  expect_error(
    shiny.webawesome:::wa_tree(
      input_id = "tree",
      shiny.webawesome:::wa_tree_item("Node A", id = "tree_item_a"),
      selection = "all"
    ),
    "`selection` must be one of ",
    fixed = TRUE
  )
})

test_that("wa_tree warns once when descendant items lack ids", {
  expect_warning(
    shiny.webawesome:::wa_tree(
      input_id = "tree",
      shiny.webawesome:::wa_tree_item(
        "Parent",
        id = "parent",
        shiny.webawesome:::wa_tree_item("Child missing")
      ),
      shiny.webawesome:::wa_tree_item("Sibling missing")
    ),
    regexp = "selected items without ids will be omitted from the Shiny value"
  )
})

test_that("wa_tree does not warn when descendant items all have ids", {
  expect_no_warning(
    shiny.webawesome:::wa_tree(
      input_id = "tree",
      shiny.webawesome:::wa_tree_item(
        "Parent",
        id = "parent",
        shiny.webawesome:::wa_tree_item("Child", id = "child")
      ),
      shiny.webawesome:::wa_tree_item("Sibling", id = "sibling")
    )
  )
})
