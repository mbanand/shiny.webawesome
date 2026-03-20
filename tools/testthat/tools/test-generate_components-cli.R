# nolint start: object_usage_linter,line_length_linter.
.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.write_json <- function(path, object) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    object,
    path = path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
}

.create_fake_vendor_metadata <- function(root, version = "3.3.1") {
  .write_json(
    file.path(root, "vendor", "webawesome", version, "dist", "custom-elements.json"),
    .fake_custom_elements()
  )
}

.fake_custom_elements <- function() {
  list(
    schemaVersion = "1.0.0",
    package = list(name = "@awesome.me/webawesome"),
    modules = list(
      list(
        path = "components/card/card.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaCard",
            tagName = "wa-card",
            attributes = list(
              list(name = "appearance", fieldName = "appearance", type = list(text = "'filled' | 'outlined'"))
            ),
            members = list(
              list(name = "appearance", kind = "field", type = list(text = "'filled' | 'outlined'"))
            )
          )
        )
      ),
      list(
        path = "components/form/checkbox.js",
        declarations = list(
          list(
            kind = "class",
            name = "WaCheckbox",
            tagName = "wa-checkbox",
            attributes = list(
              list(name = "checked", fieldName = "defaultChecked", type = list(text = "boolean"))
            ),
            members = list(
              list(name = "checked", kind = "field", type = list(text = "boolean"))
            )
          )
        )
      )
    )
  )
}

.create_fake_repo <- function(root, version = "3.3.1") {
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools", "generate"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "inst", "extdata", "webawesome", "VERSION"), version)
  .write_json(
    file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"),
    .fake_custom_elements()
  )

  file.copy(
    normalizePath(file.path("..", "..", "generate_components.R"), mustWork = TRUE),
    file.path(root, "tools", "generate_components.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  helper_files <- c(
    "utils.R",
    "metadata.R",
    "schema.R",
    "render_utils.R",
    "render_wrappers.R",
    "render_updates.R",
    "render_bindings.R",
    "write_outputs.R"
  )
  for (helper in helper_files) {
    file.copy(
      normalizePath(
        file.path("..", "..", "generate", helper),
        mustWork = TRUE
      ),
      file.path(root, "tools", "generate", helper)
    )
  }
  dir.create(
    file.path(root, "tools", "templates"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  template_files <- c("wrapper.R.tmpl", "update.R.tmpl", "binding.js.tmpl")
  for (template in template_files) {
    file.copy(
      normalizePath(
        file.path("..", "..", "templates", template),
        mustWork = TRUE
      ),
      file.path(root, "tools", "templates", template)
    )
  }

  Sys.chmod(file.path(root, "tools", "generate_components.R"), mode = "0755")
}

.run_generate_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/generate_components.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

.run_generate_script_absolute <- function(root,
                                          args = character(),
                                          wd = tempdir()) {
  processx::run(
    command = normalizePath(
      file.path(root, "tools", "generate_components.R"),
      mustWork = TRUE
    ),
    args = args,
    wd = wd,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("generate tool prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_generate_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/generate_components.R")
  testthat::expect_match(result$stdout, "--filter")
  testthat::expect_match(result$stdout, "--exclude")
  testthat::expect_match(result$stdout, "--debug")
})

testthat::test_that("generate tool builds filtered schema and reports success", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_generate_script(
    root,
    c("--filter", "wa-card", "--debug")
  )

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    "Building component schema \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    paste0(
      "Generate schema complete: components=1, metadata=",
      "inst/extdata/webawesome/custom-elements.json, debug=.*wrappers=1, bindings=0, updates=0"
    )
  )
})

testthat::test_that("generate tool supports absolute-path CLI invocation", {
  root <- withr::local_tempdir()
  run_dir <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_generate_script_absolute(root, c("--root", root), wd = run_dir)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    paste0(
      "Generate schema complete: components=2, metadata=",
      "inst/extdata/webawesome/custom-elements.json, wrappers=2, bindings=1, updates=0"
    )
  )
})

testthat::test_that("generate tool supports schema-only mode", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_generate_script(root, c("--schema-only", "--filter", "wa-card"))

  testthat::expect_equal(result$status, 0)
  testthat::expect_false(file.exists(file.path(root, "R", "generated", "wa_card.R")))
  testthat::expect_match(
    result$stderr,
    "Generate schema complete: components=1, metadata=inst/extdata/webawesome/custom-elements.json"
  )
})

testthat::test_that("generate tool fails cleanly when metadata is missing", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_vendor_metadata(root)
  unlink(file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"))

  result <- .run_generate_script(root)

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Building component schema \\.{2,} Fail")
  testthat::expect_match(result$stderr, "Run prune_webawesome\\(\\) first")
  testthat::expect_no_match(result$stderr, "^Error:", perl = TRUE)
})

testthat::test_that("generate tool asks for fetch and prune when nothing is fetched", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  unlink(file.path(root, "inst", "extdata", "webawesome", "custom-elements.json"))

  result <- .run_generate_script(root)

  testthat::expect_true(result$status != 0)
  testthat::expect_match(
    result$stderr,
    "No fetched Web Awesome dist was found under vendor/webawesome/."
  )
  testthat::expect_match(
    result$stderr,
    "Run fetch_webawesome\\(\\) and then prune_webawesome\\(\\) first"
  )
})
# nolint end
