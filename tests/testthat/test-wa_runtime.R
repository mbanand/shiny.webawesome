test_that("webawesomePage attaches the package dependency once", {
  page <- shiny.webawesome::webawesomePage(
    shiny.webawesome:::.wa_component("wa-card", "Hello"),
    shiny.webawesome:::.wa_component("wa-checkbox")
  )

  deps <- htmltools::findDependencies(page)
  dep_names <- vapply(deps, `[[`, character(1), "name")

  expect_equal(sum(dep_names == "shiny.webawesome"), 1L)
})

test_that("webawesomePage attaches the Awesome theme stylesheet", {
  page <- shiny.webawesome::webawesomePage(
    class = "wa-theme-awesome wa-palette-bright wa-brand-blue",
    shiny.webawesome:::.wa_component("wa-card", "Hello")
  )

  deps <- htmltools::findDependencies(page)
  dep_names <- vapply(deps, `[[`, character(1), "name")
  dep_stylesheets <- vapply(
    deps,
    `[[`,
    character(1),
    "stylesheet"
  )

  expect_true("shiny.webawesome" %in% dep_names)
  expect_true("shiny.webawesome-theme-awesome" %in% dep_names)
  expect_true("www/wa/styles/themes/awesome.css" %in% dep_stylesheets)
})

test_that("webawesomePage attaches the Shoelace theme stylesheet", {
  page <- shiny.webawesome::webawesomePage(
    class = "wa-theme-shoelace wa-palette-shoelace wa-brand-blue",
    shiny.webawesome:::.wa_component("wa-card", "Hello")
  )

  deps <- htmltools::findDependencies(page)
  dep_names <- vapply(deps, `[[`, character(1), "name")
  dep_stylesheets <- vapply(
    deps,
    `[[`,
    character(1),
    "stylesheet"
  )

  expect_true("shiny.webawesome" %in% dep_names)
  expect_true("shiny.webawesome-theme-shoelace" %in% dep_names)
  expect_true("www/wa/styles/themes/shoelace.css" %in% dep_stylesheets)
})

test_that("webawesomePage rejects multiple recognized theme classes", {
  expect_error(
    shiny.webawesome::webawesomePage(
      class = "wa-theme-awesome wa-theme-shoelace",
      shiny.webawesome:::.wa_component("wa-card", "Hello")
    ),
    paste0(
      "`class` must not include more than one Web Awesome theme class. ",
      'Found: "wa-theme-awesome", "wa-theme-shoelace".'
    ),
    fixed = TRUE
  )
})

test_that("webawesomePage returns an html page scaffold", {
  page <- shiny.webawesome::webawesomePage(
    title = "Runtime test",
    lang = "en",
    class = "wa-theme-default wa-palette-default wa-brand-blue",
    body_class = "app-shell",
    shiny.webawesome:::.wa_component("wa-card", "Hello")
  )

  rendered <- htmltools::renderTags(page)

  expect_match(
    rendered$html,
    paste0(
      "<html[^>]*lang=\"en\"[^>]*class=\"",
      "wa-theme-default wa-palette-default wa-brand-blue\""
    ),
    perl = TRUE
  )
  expect_match(rendered$head, "<title>Runtime test</title>", perl = TRUE)
  expect_match(rendered$html, "<body[^>]*class=\"app-shell\"", perl = TRUE)
})

test_that(
  "internal component helper attaches the dependency in fluidPage usage",
  {
    ui <- shiny::fluidPage(
      shiny.webawesome:::.wa_component("wa-card", "Hello")
    )

    deps <- htmltools::findDependencies(ui)
    dep_names <- vapply(deps, `[[`, character(1), "name")

    expect_equal(sum(dep_names == "shiny.webawesome"), 1L)
  }
)

test_that("package dependency points at the shipped bootstrap assets", {
  binding_dir <- system.file("bindings", package = "shiny.webawesome")
  dep <- shiny.webawesome:::.wa_dependency()
  script_src <- vapply(dep$script, `[[`, character(1), "src")

  expect_equal(dep$name, "shiny.webawesome")
  expect_equal(dep$src$file, ".")
  expect_equal(dep$stylesheet, "www/wa/styles/webawesome.css")
  expect_equal(script_src[[1]], "www/webawesome-init.js")
  expect_equal(dep$script[[1]]$type, "module")
  expect_true("bindings/wa_button.js" %in% script_src)
  expect_true("bindings/wa_checkbox.js" %in% script_src)
  expect_true("bindings/wa_color_picker.js" %in% script_src)
  expect_true("bindings/wa_input.js" %in% script_src)
  expect_true("bindings/wa_number_input.js" %in% script_src)
  expect_true("bindings/wa_dropdown.js" %in% script_src)
  expect_true("bindings/wa_radio_group.js" %in% script_src)
  expect_true("bindings/wa_rating.js" %in% script_src)
  expect_true("bindings/wa_select.js" %in% script_src)
  expect_true("bindings/wa_slider.js" %in% script_src)
  expect_true("bindings/wa_switch.js" %in% script_src)
  expect_true("bindings/wa_textarea.js" %in% script_src)
  expect_true("bindings/wa_tree.js" %in% script_src)
  expect_match(
    as.character(dep$head),
    "window\\.shinyWebawesomeWarnings",
    perl = TRUE
  )
})

test_that("warning registry defaults to enabled known warnings", {
  warnings <- shiny.webawesome:::.wa_warning_registry()

  expect_true(isTRUE(warnings$missing_tree_item_id))
  expect_true(isTRUE(warnings$command_layer))
  expect_false(isTRUE(warnings$command_layer_debug))
})

test_that("warning registry respects explicit option overrides", {
  withr::local_options(shiny.webawesome.warnings = list(
    missing_tree_item_id = FALSE,
    command_layer = FALSE,
    command_layer_debug = TRUE
  ))

  warnings <- shiny.webawesome:::.wa_warning_registry()

  expect_false(isTRUE(warnings$missing_tree_item_id))
  expect_false(isTRUE(warnings$command_layer))
  expect_true(isTRUE(warnings$command_layer_debug))
})

test_that("warning registry falls back to defaults on invalid option values", {
  withr::local_options(shiny.webawesome.warnings = list(
    missing_tree_item_id = NA,
    command_layer = "yes",
    command_layer_debug = TRUE
  ))

  warnings <- shiny.webawesome:::.wa_warning_registry()

  expect_true(isTRUE(warnings$missing_tree_item_id))
  expect_true(isTRUE(warnings$command_layer))
  expect_true(isTRUE(warnings$command_layer_debug))
})

test_that("binding script helper returns sorted installed binding scripts", {
  scripts <- shiny.webawesome:::.wa_binding_scripts()

  expect_true(length(scripts) > 0L)
  expect_identical(scripts, sort(scripts))
  expect_true("bindings/wa_button.js" %in% scripts)
  expect_true("bindings/wa_tree.js" %in% scripts)
})

test_that("constructor attribute helper validates and serializes values", {
  expect_null(
    shiny.webawesome:::.wa_match_constructor_attr(
      NULL,
      "appearance",
      true_value = "solid",
      false_value = "ghost",
      string_map = c(outline = "outline")
    )
  )

  expect_identical(
    shiny.webawesome:::.wa_match_constructor_attr(
      TRUE,
      "appearance",
      true_value = "solid",
      false_value = "ghost"
    ),
    "solid"
  )

  expect_identical(
    shiny.webawesome:::.wa_match_constructor_attr(
      FALSE,
      "appearance",
      true_value = "solid",
      false_value = "ghost"
    ),
    "ghost"
  )

  expect_identical(
    shiny.webawesome:::.wa_match_constructor_attr(
      "outline",
      "appearance",
      string_map = c(outline = "outline")
    ),
    "outline"
  )

  expect_error(
    shiny.webawesome:::.wa_match_constructor_attr(
      "invalid",
      "appearance",
      true_value = "solid",
      false_value = "ghost",
      string_map = c(outline = "outline")
    ),
    '`appearance` must be one of "TRUE", "FALSE", "outline".',
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome:::.wa_match_constructor_attr(
      1,
      "appearance",
      true_value = "solid",
      false_value = "ghost"
    ),
    '`appearance` must be TRUE, FALSE, NULL, or one of "TRUE", "FALSE".',
    fixed = TRUE
  )
})

test_that("tree-item warning helper counts nested missing ids", {
  tree_children <- list(
    shiny.webawesome:::wa_tree_item(
      "Parent",
      id = "parent",
      shiny.webawesome:::wa_tree_item("Child missing"),
      shiny.webawesome:::wa_tree_item("Child present", id = "child_present")
    ),
    shiny.webawesome:::wa_tree_item("Sibling missing")
  )

  expect_equal(
    shiny.webawesome:::.wa_count_tree_missing_ids(tree_children),
    2L
  )
})

test_that("tree-item warning helper warns once with the missing-id count", {
  tree_children <- list(
    shiny.webawesome:::wa_tree_item("Node A"),
    shiny.webawesome:::wa_tree_item("Node B")
  )

  expect_warning(
    shiny.webawesome:::.wa_warn_missing_tree_item_ids(
      tree_children,
      input_id = "tree"
    ),
    regexp = "found 2 descendant `wa-tree-item` elements"
  )
})

test_that("tree-item warning helper respects warning suppression", {
  withr::local_options(shiny.webawesome.warnings = list(
    missing_tree_item_id = FALSE
  ))

  tree_children <- list(
    shiny.webawesome:::wa_tree_item("Node A")
  )

  expect_no_warning(
    shiny.webawesome:::.wa_warn_missing_tree_item_ids(
      tree_children,
      input_id = "tree"
    )
  )
})
