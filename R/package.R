#' shiny.webawesome: Shiny Bindings for Web Awesome Components
#'
#' Provides an R and Shiny interface to the Web Awesome component library.
#'
#' `shiny.webawesome` is a generator-driven package that exposes Web Awesome
#' components as R functions for use in Shiny applications. Most component
#' wrappers are generated from the upstream Web Awesome metadata file
#' `custom-elements.json`, which the package treats as its primary component
#' source of truth.
#'
#' The package aims to stay close to upstream Web Awesome names, conventions,
#' and component APIs while adopting normal R conventions such as snake_case
#' argument names. Because Web Awesome lives in the browser and Shiny spans
#' both server and client, the package also includes a curated Shiny binding
#' layer plus a small set of package-level helpers for layout, browser
#' commands, and app-local JavaScript.
#'
#' ## Main package surfaces
#'
#' The package exposes several complementary surfaces:
#'
#' - generated component wrappers such as `wa_button()` and `wa_select()`
#' - layout helpers such as `wa_page()` and `wa_container()`
#' - generated Shiny bindings and update helpers for selected interactive
#'   components
#' - command-layer helpers such as `wa_set_property()` and `wa_call_method()`
#' - the narrow browser-glue helper `wa_js()`
#'
#' ## Package options
#'
#' The package currently uses the option `shiny.webawesome.warnings` to control
#' selected runtime warnings and diagnostics.
#'
#' This option should be a named list. Known keys currently include:
#'
#' - `missing_tree_item_id`
#' - `command_layer`
#' - `command_layer_debug`
#'
#' Example:
#'
#' `options(shiny.webawesome.warnings = list(command_layer_debug = TRUE))`
#'
#' ## Learn more
#'
#' For an introductory guide, see
#' `vignette("get-started", package = "shiny.webawesome")`. For
#' function-specific details, use the package help pages such as `?wa_page`,
#' `?wa_set_property`, `?wa_call_method`, and `?wa_js`.
#'
#' @keywords internal
"_PACKAGE"
