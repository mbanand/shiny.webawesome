test_that("wa_tree_item defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_tree_item("Node")),
    c("<wa-tree-item>Node</wa-tree-item>")
  )
})

test_that("wa_tree_item override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tree_item(
        "Node",
        id = "node",
        disabled = TRUE,
        dir = "rtl",
        expanded = TRUE,
        lang = "en",
        lazy = TRUE,
        selected = TRUE,
        collapse_icon = "Minus",
        expand_icon = "Plus"
      )
    ),
    c(
      paste0(
        '<wa-tree-item id="node" disabled dir="rtl" expanded ',
        'lang="en" lazy selected>'
      ),
      "  Node",
      '  <span slot="collapse-icon">Minus</span>',
      '  <span slot="expand-icon">Plus</span>',
      "</wa-tree-item>"
    )
  )
})

test_that("wa_tree_item boolean args validate and render correctly", {
  default_html <- render_html(shiny.webawesome:::wa_tree_item("Node"))

  for (arg_name in c("disabled", "expanded", "lazy", "selected")) {
    tag <- do.call(
      shiny.webawesome:::wa_tree_item,
      c(list("Node"), stats::setNames(list(TRUE), arg_name))
    )

    expect_exact_html(
      render_html(tag),
      c(sprintf("<wa-tree-item %s>Node</wa-tree-item>", arg_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_tree_item,
      c(list("Node"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_tree_item,
      c(list("Node"), stats::setNames(list(NULL), arg_name))
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_tree_item,
        c(list("Node"), stats::setNames(list("yes"), arg_name))
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})
