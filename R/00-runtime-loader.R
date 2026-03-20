# Source handwritten runtime helpers from R/core during package load.
sys.source(file.path("R", "core", "wa_dependency.R"), envir = environment())
sys.source(file.path("R", "core", "wa_page.R"), envir = environment())
