## Test environments

* Local: Ubuntu 24.04.4 LTS, R 4.3.3
* GitHub Actions matrix enabled for ubuntu-latest, macOS-latest, windows-latest

## R CMD check results

* `R CMD build CatMapR`
* `R CMD check --as-cran CatMapR_0.1.15.tar.gz`

Current expected NOTE at submission time:

* "New submission"

Local environment notes:

* Local `R CMD check --as-cran CatMapR_0.1.15.tar.gz` completed with 3 NOTEs:
  "New submission", "unable to verify current time", and skipped HTML
  validation because `tidy` is not installed.

## Notes

CatMapR provides an R interface to CatMapper API endpoints for dataset metadata discovery,
search, translation, and controlled upload/update workflows.

Win-builder:

* `CatMapR_0.1.2.tar.gz` was submitted to the `R-devel` form on 2026-03-18.
* A follow-up submission attempt returned:
  `ERROR: Access to the path 'C:\Inetpub\ftproot\R-devel\CatMapR_0.1.2.tar.gz' is denied.`
  which indicates the same tarball name is already present in the queue/processing area.
