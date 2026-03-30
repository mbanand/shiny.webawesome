# nolint start: object_usage_linter.
source(file.path("..", "..", "prune_webawesome.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root, version = "3.3.1") {
  dir.create(file.path(root, "dev"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "dev", "webawesome-version.txt"), version)
}

.create_fake_dist <- function(root,
                              version = "3.3.1",
                              loader_import = "./chunks/chunk.loader.js") {
  dist_root <- file.path(root, "vendor", "webawesome", version, "dist-cdn")
  version_root <- file.path(root, "vendor", "webawesome", version)

  .write_file(file.path(version_root, "VERSION"), version)
  .write_file(file.path(dist_root, "custom-elements.json"), "{}")
  .write_file(
    file.path(dist_root, "webawesome.loader.js"),
    c(
      sprintf("import \"%s\";", loader_import),
      "export const loader = true;"
    )
  )
  .write_file(
    file.path(dist_root, "chunks", "chunk.loader.js"),
    c(
      "import \"./chunk.shared.js\";",
      "export const loaderChunk = true;"
    )
  )
  .write_file(
    file.path(dist_root, "chunks", "chunk.shared.js"),
    "export const shared = true;"
  )
  .write_file(
    file.path(dist_root, "chunks", "chunk.unused.js"),
    "export const unused = true;"
  )
  .write_file(
    file.path(dist_root, "components", "wa-button.js"),
    c(
      "import \"../chunks/chunk.shared.js\";",
      "export const button = true;"
    )
  )
  .write_file(
    file.path(dist_root, "events", "events.js"),
    "export const events = true;"
  )
  .write_file(
    file.path(dist_root, "styles", "webawesome.css"),
    "@import \"./theme.css\";"
  )
  .write_file(file.path(dist_root, "styles", "theme.css"), "body {}")
  .write_file(
    file.path(dist_root, "translations", "en.js"),
    "export const lang = \"en\";"
  )
  .write_file(
    file.path(dist_root, "utilities", "set-base-path.js"),
    c(
      "import \"../internal/helper.js\";",
      "export const setBasePath = true;"
    )
  )
  .write_file(
    file.path(dist_root, "internal", "helper.js"),
    "export const internal = true;"
  )
  .write_file(
    file.path(dist_root, "internal", "orphan.js"),
    "export const orphan = true;"
  )
  .write_file(
    file.path(dist_root, "react", "index.js"),
    "export const react = true;"
  )
  .write_file(
    file.path(dist_root, "types", "index.js"),
    "export const types = true;"
  )
  .write_file(
    file.path(dist_root, "webawesome.js"),
    "export const monolith = true;"
  )
  .write_file(
    file.path(dist_root, "webawesome.ssr-loader.js"),
    "export const ssr = true;"
  )
  .write_file(file.path(dist_root, "custom-elements-jsx.d.ts"), "export {};")
  .write_file(
    file.path(dist_root, "components", "wa-button.d.ts"),
    "export {};"
  )
}

testthat::test_that("prune uses the pinned version by default", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)

  result <- prune_webawesome(root = root, verbose = FALSE)

  testthat::expect_equal(result$version, "3.3.1")
  testthat::expect_true(
    file.exists(
      file.path(root, "inst", "www", "wa", "webawesome.loader.js")
    )
  )
  testthat::expect_true(
    file.exists(
      file.path(root, "inst", "extdata", "webawesome", "custom-elements.json")
    )
  )
  testthat::expect_true(
    file.exists(file.path(root, "report", "prune", "3.3.1", "summary.md"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "report", "prune", "3.3.1", "reachability.md"))
  )
  testthat::expect_equal(
    result$integrity$path,
    file.path("manifests", "integrity", "prune-output.yaml")
  )
  testthat::expect_true(file.exists(file.path(root, result$integrity$path)))
})

testthat::test_that("prune copies reached runtime files and metadata only", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)

  result <- prune_webawesome(root = root, verbose = FALSE)

  runtime_root <- file.path(root, "inst", "www", "wa")
  extdata_root <- file.path(root, "inst", "extdata", "webawesome")

  testthat::expect_true(
    file.exists(file.path(runtime_root, "webawesome.loader.js"))
  )
  testthat::expect_true(
    file.exists(file.path(runtime_root, "components", "wa-button.js"))
  )
  testthat::expect_true(
    file.exists(file.path(runtime_root, "chunks", "chunk.shared.js"))
  )
  testthat::expect_true(
    file.exists(file.path(runtime_root, "internal", "helper.js"))
  )
  testthat::expect_false(
    file.exists(file.path(runtime_root, "chunks", "chunk.unused.js"))
  )
  testthat::expect_false(
    file.exists(file.path(runtime_root, "react", "index.js"))
  )
  testthat::expect_true(
    file.exists(file.path(extdata_root, "custom-elements.json"))
  )
  testthat::expect_true(file.exists(file.path(extdata_root, "VERSION")))
  testthat::expect_equal(
    sort(result$metadata_files),
    c("VERSION", "custom-elements.json")
  )
})

testthat::test_that("prune reports unreached files without failing", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)

  result <- prune_webawesome(root = root, verbose = FALSE)
  report_lines <- readLines(
    file.path(root, result$reachability_report),
    warn = FALSE
  )

  testthat::expect_true(
    "chunks/chunk.unused.js" %in% result$reachability$unreached
  )
  testthat::expect_true("internal/orphan.js" %in% result$reachability$unreached)
  testthat::expect_true(
    any(grepl("chunk.unused.js", report_lines, fixed = TRUE))
  )
  testthat::expect_true(
    any(grepl("internal/orphan.js", report_lines, fixed = TRUE))
  )
})

testthat::test_that("prune rejects missing fetched versions", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    prune_webawesome(root = root, verbose = FALSE),
    "Fetched upstream version does not exist"
  )
})

testthat::test_that("prune rejects incomplete fetched artifacts", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)
  unlink(
    file.path(
      root,
      "vendor",
      "webawesome",
      "3.3.1",
      "dist-cdn",
      "custom-elements.json"
    )
  )

  testthat::expect_error(
    prune_webawesome(root = root, verbose = FALSE),
    "missing required prune inputs"
  )
})

testthat::test_that("prune rejects non-empty prune outputs", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)
  .write_file(file.path(root, "inst", "www", "wa", "stale.js"), "stale")

  testthat::expect_error(
    prune_webawesome(root = root, verbose = FALSE),
    "Prune output directories already contain content"
  )
})

testthat::test_that("prune fails when reachability finds missing imports", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root, loader_import = "./chunks/missing.js")

  testthat::expect_error(
    prune_webawesome(root = root, verbose = FALSE),
    "Prune reachability analysis found missing imported files"
  )
})

testthat::test_that("prune ignores bare package imports during reachability", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)
  .write_file(
    file.path(
      root,
      "vendor",
      "webawesome",
      "3.3.1",
      "dist-cdn",
      "utilities",
      "set-base-path.js"
    ),
    c(
      "import \"lit\";",
      "import \"../internal/helper.js\";",
      "export const setBasePath = true;"
    )
  )

  result <- prune_webawesome(root = root, verbose = FALSE)

  testthat::expect_true(
    "utilities/set-base-path.js" %in% result$reachability$reached
  )
  testthat::expect_length(result$reachability$missing_imports, 0L)
})

testthat::test_that("prune rejects non-repository roots", {
  root <- withr::local_tempdir()

  testthat::expect_error(
    prune_webawesome(root = root, verbose = FALSE),
    "`root` does not appear to be the repository root."
  )
})
# nolint end
