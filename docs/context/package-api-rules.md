# Package API Rules

This document describes rules governing the public API of the
`shiny.webawesome` package.

---

# Export Rules

User-facing functions must be explicitly exported and documented.

Internal helper functions should not be exported.

Agents should follow these rules:

- Public functions must include `@export` in their roxygen2 documentation.
- Internal helpers should not include `@export`.
- Internal helper functions should typically use a leading dot prefix.

Example:

wa_button()      # exported  
.parse_metadata() # internal

---

# Documentation

Handwritten R functions that are part of the package API must include
roxygen2 documentation.

Agents should run:

devtools::document()

after modifying exported functions.

---

# Code Style

Handwritten R code should follow the tidyverse style guide.

Generated code should be formatted using `styler`.

---

# Public API Philosophy

The public package API should remain minimal and stable.

Most functions should remain internal unless they are clearly intended
for users of the package.
