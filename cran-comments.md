## Resubmission

This is a resubmission in response to CRAN review comments.

Changes made:

* Updated `DESCRIPTION` title and description formatting so software/package
  names are written in single quotes, including `'shiny'` and `'Web Awesome'`.
  I also rewrote the final description sentence to avoid the possessive form
  `Shiny's`.
* Did not add separate DESCRIPTION references. This package primarily provides
  generated `'R'`/`'shiny'` bindings to the `'Web Awesome'` component library
  rather than implementing a separate novel method, so there are no distinct
  methodological references to add here.
* Replaced `\\dontrun{}` with `\\donttest{}` in the examples for
  `wa_call_method()` and `wa_set_property()`, and expanded both examples into
  minimal copy-paste runnable `shinyApp()` examples.
* Added lightweight executable code chunks to each built package vignette so
  the vignette set now executes real package code during vignette builds while
  keeping the larger interactive app examples as non-executed illustrative
  examples.
* Excluded website-only vignette support directories from source-package builds:
  `vignettes/articles/` and `vignettes/shinylive-examples/`.

## Validation

I reran the relevant documentation and package checks after these changes:

* `devtools::document()`
* `R CMD build .`
* `R CMD check shiny.webawesome_1.0.0.tar.gz`

Current local `R CMD check` result:

* 0 errors | 0 warnings | 1 note
* The only note is: This is a resubmission of a new package.

## Additional notes

* WinBuilder previously reported a URL failure for
  `https://www.shiny-webawesome.org`. The site itself has been independently
  verified as reachable, and this appears to have been a local/path-specific
  WinBuilder issue rather than a package defect. I also discussed this on the
  `r-package-devel` mailing list:
  <https://www.mail-archive.com/r-package-devel@r-project.org/msg11404.html>.
