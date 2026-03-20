# Resolve the directory containing the current loader file.
.wa_loader_dir <- function() {
  ofiles <- vapply(
    sys.frames(),
    function(frame) if (is.null(frame$ofile)) "" else frame$ofile,
    character(1)
  )
  source_file <- tail(ofiles[nzchar(ofiles)], 1)

  if (length(source_file) == 0L || !nzchar(source_file)) {
    return("R")
  }

  dirname(normalizePath(source_file, winslash = "/", mustWork = FALSE))
}

# Source generated wrappers and update helpers during package load.
.wa_source_generated_dir <- function(relative_dir) {
  dir_path <- file.path(.wa_loader_dir(), relative_dir)

  if (!dir.exists(dir_path)) {
    return(invisible(NULL))
  }

  paths <- sort(list.files(dir_path, pattern = "\\.[Rr]$", full.names = TRUE))
  for (path in paths) {
    sys.source(path, envir = parent.frame())
  }

  invisible(NULL)
}

.wa_source_generated_dir("generated")
.wa_source_generated_dir("generated_updates")

rm(.wa_loader_dir, .wa_source_generated_dir)
