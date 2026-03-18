# CatMapR 0.1.2

- Normalized package metadata for CRAN submission (`Title`, `Version`, `License`,
  `URL`, and `BugReports`).
- Standardized top-level package files for CRAN checks (`README.md`) and added
  build ignore rules for local check artifacts.
- Made API examples CRAN-safe by wrapping network calls in `\\dontrun{}`.
- Added central input-validation helpers and wired them into exported API
  wrappers for clearer error messages and safer inputs.
- Added tests covering new validation behavior.
