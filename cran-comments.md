## Test environments

* Local: Ubuntu 22.04, R 4.1.2
* GitHub Actions matrix enabled for ubuntu-latest, macOS-latest, windows-latest (R 4.4.1)

## R CMD check results

* `R CMD build .`
* `R CMD check --as-cran CatMapR_0.1.2.tar.gz`
* GitHub Actions `R-CMD-check` run (2026-03-18): https://github.com/ProjectCatMapper/CatMapR/actions/runs/23232486263
* Ubuntu check (R 4.4.1): https://github.com/ProjectCatMapper/CatMapR/actions/runs/23232486263/job/67528862563
* macOS check (R 4.4.1): https://github.com/ProjectCatMapper/CatMapR/actions/runs/23232486263/job/67528862575
* Windows check (R 4.4.1): https://github.com/ProjectCatMapper/CatMapR/actions/runs/23232486263/job/67528862577

Current expected NOTE at submission time:

* "New submission"

## Notes

CatMapR provides an R interface to CatMapper API endpoints for dataset metadata discovery,
search, translation, and controlled upload/update workflows.

Win-builder:

* `CatMapR_0.1.2.tar.gz` was submitted to the `R-devel` form on 2026-03-18.
* A follow-up submission attempt returned:
  `ERROR: Access to the path 'C:\Inetpub\ftproot\R-devel\CatMapR_0.1.2.tar.gz' is denied.`
  which indicates the same tarball name is already present in the queue/processing area.
