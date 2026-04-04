#' Send one generic shiny.webawesome browser command
#'
#' Sends a one-way command from the Shiny server to a browser element targeted
#' by DOM `id`. This is an internal transport helper used by package-level
#' command helpers such as `wa_set_property()` and `wa_call_method()`.
#'
#' @param id DOM `id` of the target browser element.
#' @param command Scalar command name.
#' @param payload Optional command payload list.
#' @param session Shiny session object. Defaults to the current reactive domain.
#'
#' @return Invisibly returns `NULL`.
#' @keywords internal
.wa_send_command <- function(id,
                             command,
                             payload = list(),
                             session = shiny::getDefaultReactiveDomain()) {
  if (!is.character(id) || length(id) != 1L || is.na(id) || !nzchar(id)) {
    stop("`id` must be one non-missing string.", call. = FALSE)
  }

  valid_command <- is.character(command) &&
    length(command) == 1L &&
    !is.na(command) &&
    nzchar(command)
  if (!valid_command) {
    stop("`command` must be one non-missing string.", call. = FALSE)
  }

  if (!is.list(payload)) {
    stop("`payload` must be a list.", call. = FALSE)
  }

  if (is.null(session) || !is.function(session$sendCustomMessage)) {
    stop(
      paste(
        "`session` must be an active Shiny session that supports",
        "`sendCustomMessage()`."
      ),
      call. = FALSE
    )
  }

  session$sendCustomMessage(
    "shiny.webawesome.command",
    list(
      id = id,
      command = command,
      payload = payload
    )
  )

  invisible(NULL)
}

#' Set one live property on a browser-side element
#'
#' Sends a one-way command from the Shiny server that sets a live browser-side
#' property on the element identified by DOM `id`.
#'
#' `wa_set_property()` is a narrow package-level escape hatch for advanced
#' cases where a Web Awesome component property needs to be updated from server
#' logic but is not covered by a generated update helper. It does not validate
#' whether the requested property exists for the targeted component.
#'
#' This helper is complementary to generated component bindings and update
#' helpers. It is not part of upstream component coverage and does not expand
#' the generated per-component API surface.
#'
#' @details
#' On the server side, `wa_set_property()` validates only its R helper inputs,
#' such as the target `id`, property name, and session. It does not validate
#' whether the requested property exists on the browser-side element.
#'
#' In the browser runtime, the command layer validates that the target DOM
#' `id` resolves to an element and that a property name was supplied, then
#' assigns the value directly. Command-layer warnings are controlled by the
#' package warning registry, especially the `command_layer` key. For option
#' details, see the Package Options article.
#'
#' @param id DOM `id` of the target browser element.
#' @param property Scalar property name to assign on the target element.
#' @param value Value to assign. This should be serializable through Shiny's
#'   custom-message transport. In practice, prefer JSON-like values such as
#'   strings, numbers, logicals, `NULL`, vectors/lists of scalars, and named
#'   lists that map cleanly to browser objects. Do not expect R functions,
#'   language objects, or HTML tags to serialize into useful browser-side
#'   values.
#' @param session Shiny session object. Defaults to the current reactive domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   observeEvent(input$open_dialog, {
#'     wa_set_property("dialog", "open", TRUE, session = session)
#'   })
#' }
#' }
wa_set_property <- function(id,
                            property,
                            value,
                            session = shiny::getDefaultReactiveDomain()) {
  valid_property <- is.character(property) &&
    length(property) == 1L &&
    !is.na(property) &&
    nzchar(property)
  if (!valid_property) {
    stop("`property` must be one non-missing string.", call. = FALSE)
  }

  .wa_send_command(
    id = id,
    command = "set_property",
    payload = list(name = property, value = value),
    session = session
  )
}

#' Call one browser-side method on a target element
#'
#' Sends a one-way command from the Shiny server that invokes a browser-side
#' method on the element identified by DOM `id`.
#'
#' `wa_call_method()` is a narrow package-level escape hatch for advanced
#' cases where a Web Awesome component method needs to be triggered from server
#' logic but is not covered by a generated helper. It does not validate whether
#' the requested method exists for the targeted component.
#'
#' This helper is complementary to generated component bindings and update
#' helpers. It is not part of upstream component coverage and does not expand
#' the generated per-component API surface.
#'
#' @details
#' On the server side, `wa_call_method()` validates only its R helper inputs,
#' such as the target `id`, method name, argument list, and session. It does
#' not validate whether the requested method exists on the browser-side
#' element.
#'
#' In the browser runtime, the command layer validates that the target DOM
#' `id` resolves to an element, that a method name was supplied, and that the
#' named member is callable on the target element before invoking it.
#' Command-layer warnings are controlled by the package warning registry,
#' especially the `command_layer` key. For option details, see the Package
#' Options article.
#'
#' @param id DOM `id` of the target browser element.
#' @param method Scalar method name to invoke on the target element.
#' @param args Optional list of positional arguments to pass to the method.
#'   These should be serializable through Shiny's custom-message transport.
#'   In practice, prefer JSON-like scalar values or nested lists that map
#'   cleanly to browser values. Do not expect R functions, language objects,
#'   or HTML tags to serialize into useful method arguments.
#' @param session Shiny session object. Defaults to the current reactive domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   observeEvent(input$show_dialog, {
#'     wa_call_method("dialog", "show", session = session)
#'   })
#' }
#' }
wa_call_method <- function(id,
                           method,
                           args = list(),
                           session = shiny::getDefaultReactiveDomain()) {
  valid_method <- is.character(method) &&
    length(method) == 1L &&
    !is.na(method) &&
    nzchar(method)
  if (!valid_method) {
    stop("`method` must be one non-missing string.", call. = FALSE)
  }

  if (!is.list(args)) {
    stop("`args` must be a list.", call. = FALSE)
  }

  .wa_send_command(
    id = id,
    command = "call_method",
    payload = list(name = method, args = args),
    session = session
  )
}
