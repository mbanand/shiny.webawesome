# Return the path to the shipped bundled-Web-Awesome version file.
.wa_version_path <- function() {
  installed <- system.file(
    "SHINY.WEBAWESOME_VERSION",
    package = "shiny.webawesome"
  )

  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  file.path("inst", "SHINY.WEBAWESOME_VERSION")
}

# Read and validate the bundled Web Awesome version file.
.wa_read_version_file <- function(path) {
  if (!file.exists(path)) {
    stop(
      "Could not find the bundled Web Awesome version file.",
      call. = FALSE
    )
  }

  lines <- trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
  lines <- lines[nzchar(lines)]

  if (length(lines) != 1L) {
    stop(
      "The bundled Web Awesome version file must contain exactly one version.",
      call. = FALSE
    )
  }

  lines[[1]]
}

#' Return the bundled Web Awesome version
#'
#' Reports the Web Awesome version bundled with the current
#' `shiny.webawesome` installation.
#'
#' @return A length-1 character vector containing the bundled Web Awesome
#'   version string.
#'
#' @export
#'
#' @examples
#' wa_version()
wa_version <- function() {
  .wa_read_version_file(.wa_version_path())
}
