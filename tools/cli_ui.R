# Shared CLI status helpers for the shiny.webawesome tool scripts.
#
# This file is sourced by CLI entry points under tools/ and tools/runners/. It
# is not package runtime code.

`_cli_ui_new` <- function() {
  mode <- Sys.getenv("SHINY_WEBAWESOME_CLI_MODE", "")
  has_isatty <- exists("isatty", envir = baseenv(), inherits = FALSE)
  tty_ready <- if (has_isatty) {
    isatty(stdout()) && isatty(stderr())
  } else {
    FALSE
  }
  fancy <- identical(mode, "fancy") || (
    identical(mode, "") &&
      isTRUE(tty_ready) &&
      identical(Sys.getenv("CI"), "") &&
      sink.number() == 0L
  )

  ui <- new.env(parent = emptyenv())
  ui$quiet <- identical(mode, "quiet")
  ui$fancy <- fancy
  ui$has_substep <- FALSE
  ui$current_step <- NULL
  ui$plain_substep_status_col <- 54L
  ui$plain_step_status_col <- 65L
  ui$fancy_step_status_col <- 60L
  ui
}

`_cli_plain_line` <- function(label, status, status_col) {
  base <- paste0(label, " ")
  dots_needed <- max(
    2L,
    status_col - nchar(base, type = "width") - nchar(status, type = "width")
  )
  paste0(base, strrep(".", dots_needed), " ", status)
}

`_cli_step_line` <- function(ui, label, status) {
  status_col <- if (isTRUE(ui$fancy)) {
    ui$fancy_step_status_col
  } else {
    ui$plain_step_status_col
  }

  `_cli_plain_line`(label, status, status_col)
}

`_cli_step_start` <- function(ui, label) {
  if (isTRUE(ui$quiet)) {
    return(invisible(NULL))
  }

  ui$current_step <- label
  ui$has_substep <- FALSE

  if (isTRUE(ui$fancy)) {
    cat(label, "...\n", sep = "")
    flush.console()
  } else {
    message("\n", label)
  }
}

`_cli_step_update` <- function(ui, label, index = NULL, total = NULL) {
  if (isTRUE(ui$quiet)) {
    return(invisible(NULL))
  }

  suffix <- if (!is.null(index) && !is.null(total)) {
    paste0(" (", index, "/", total, ")")
  } else {
    ""
  }
  text <- paste0("-- ", label, suffix, "...")

  if (isTRUE(ui$fancy)) {
    cat("\r\033[2K", text, sep = "")
    flush.console()
    ui$has_substep <- TRUE
  }
}

`_cli_step_finish` <- function(ui, status = "Done") {
  if (isTRUE(ui$quiet)) {
    ui$has_substep <- FALSE
    ui$current_step <- NULL
    return(invisible(NULL))
  }

  label <- ui$current_step %||% "Step"

  if (isTRUE(ui$fancy)) {
    if (isTRUE(ui$has_substep)) {
      cat("\r\033[2K", sep = "")
    }
    cat("\033[1A\r\033[2K", `_cli_step_line`(ui, label, status), "\n", sep = "")
    flush.console()
  } else {
    message(`_cli_step_line`(ui, label, status))
  }

  ui$has_substep <- FALSE
  ui$current_step <- NULL
}

`_cli_step_fail` <- function(ui, details = character()) {
  if (isTRUE(ui$quiet)) {
    if (length(details) > 0L) {
      cat(paste(details, collapse = "\n"), "\n", sep = "")
    }
    ui$has_substep <- FALSE
    ui$current_step <- NULL
    return(invisible(NULL))
  }

  label <- ui$current_step %||% "Step"

  if (isTRUE(ui$fancy)) {
    if (isTRUE(ui$has_substep)) {
      cat("\r\033[2K", sep = "")
    }
    cat("\033[1A\r\033[2K", `_cli_step_line`(ui, label, "Fail"), "\n", sep = "")
    flush.console()
  } else {
    message(`_cli_step_line`(ui, label, "Fail"))
  }

  if (length(details) > 0L) {
    cat(paste(details, collapse = "\n"), "\n", sep = "")
  }

  ui$has_substep <- FALSE
  ui$current_step <- NULL
}

`_cli_substep_pass` <- function(ui, label, index = NULL, total = NULL, status = "pass") {
  if (isTRUE(ui$quiet)) {
    return(invisible(NULL))
  }

  suffix <- if (!is.null(index) && !is.null(total)) {
    paste0(" (", index, "/", total, ")")
  } else {
    ""
  }
  text <- paste0("  ", label, suffix)

  if (isTRUE(ui$fancy)) {
    return(invisible(NULL))
  }

  message(`_cli_plain_line`(text, status, ui$plain_substep_status_col))
}

`_cli_spinner_frames` <- function() {
  c("[   ]", "[.  ]", "[.. ]", "[...]", "[ ..]", "[  .]")
}

`_cli_run_command` <- function(ui,
                               label,
                               command,
                               args = character(),
                               wd = ".",
                               env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop("The `processx` package is required for CLI orchestration.", call. = FALSE)
  }

  if (!isTRUE(ui$fancy)) {
    return(
      processx::run(
        command = command,
        args = args,
        wd = wd,
        echo = FALSE,
        error_on_status = FALSE,
        env = env
      )
    )
  }

  proc <- processx::process$new(
    command = command,
    args = args,
    wd = wd,
    stdout = "|",
    stderr = "|",
    cleanup_tree = TRUE,
    env = env
  )

  stdout_lines <- character()
  stderr_lines <- character()
  frames <- `_cli_spinner_frames`()
  tick <- 1L

  while (proc$is_alive()) {
    proc$poll_io(100)
    stdout_lines <- c(stdout_lines, proc$read_output_lines())
    stderr_lines <- c(stderr_lines, proc$read_error_lines())
    cat("\r\033[2K", label, " ", frames[[tick]], sep = "")
    flush.console()
    tick <- if (tick == length(frames)) 1L else tick + 1L
  }

  stdout_lines <- c(stdout_lines, proc$read_all_output_lines())
  stderr_lines <- c(stderr_lines, proc$read_all_error_lines())

  list(
    status = proc$get_exit_status(),
    stdout = paste(stdout_lines, collapse = "\n"),
    stderr = paste(stderr_lines, collapse = "\n")
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}
