test_that("wa_mutation_observer defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_mutation_observer("Tracked")),
    c("<wa-mutation-observer>Tracked</wa-mutation-observer>")
  )
})

test_that("wa_mutation_observer override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_mutation_observer(
        "Tracked",
        id = "observer",
        disabled = TRUE,
        attr = "class id",
        attr_old_value = TRUE,
        char_data = TRUE,
        char_data_old_value = TRUE,
        child_list = TRUE,
        dir = "rtl",
        lang = "en"
      )
    ),
    c(
      paste0(
        '<wa-mutation-observer id="observer" disabled attr="class id" ',
        "attr-old-value char-data char-data-old-value child-list ",
        'dir="rtl" lang="en">Tracked</wa-mutation-observer>'
      )
    )
  )
})

test_that("wa_mutation_observer boolean args validate and render correctly", {
  default_html <- render_html(
    shiny.webawesome:::wa_mutation_observer("Tracked")
  )
  boolean_args <- c(
    disabled = "disabled",
    attr_old_value = "attr-old-value",
    char_data = "char-data",
    char_data_old_value = "char-data-old-value",
    child_list = "child-list"
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    tag <- do.call(
      shiny.webawesome:::wa_mutation_observer,
      c(list("Tracked"), stats::setNames(list(TRUE), arg_name))
    )

    expect_exact_html(
      render_html(tag),
      c(
        sprintf(
          "<wa-mutation-observer %s>Tracked</wa-mutation-observer>",
          attr_name
        )
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_mutation_observer,
      c(list("Tracked"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_mutation_observer,
      c(list("Tracked"), stats::setNames(list(NULL), arg_name))
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_mutation_observer,
        c(list("Tracked"), stats::setNames(list("yes"), arg_name))
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})
