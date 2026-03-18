## Test environments

* Local: Ubuntu 22.04, R 4.1.2
* GitHub Actions matrix enabled for ubuntu-latest, macOS-latest, windows-latest (R 4.4.1)

## R CMD check results

* `R CMD build .`
* `R CMD check --as-cran CatMapR_0.1.2.tar.gz`

Current expected NOTE at submission time:

* "New submission"

## Notes

CatMapR provides an R interface to CatMapper API endpoints for dataset discovery,
search, translation, and controlled upload/update workflows.
