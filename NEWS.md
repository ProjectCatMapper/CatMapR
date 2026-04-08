# CatMapR 0.1.2.9000 (unreleased; noted 2026-03-27)

- Renamed exported functions to a clearer snake_case user API:
  `get_cmid_info()`, `list_datasets()`, `get_dataset_metadata()`,
  `search_database()`, `translate_rows()`, `propose_merge_links()`,
  `join_datasets()`, `get_domains()`, `get_properties()`,
  `get_upload_properties()`, `get_merge_template()`,
  `get_merge_template_summary()`, `build_merge_syntax()`, `upload_rows()`,
  and `prepare_upload_rows()`.
- Removed legacy alias exports and deprecated upload wrappers.
- Merged upload flows into `upload_rows()`; it now always triggers
  `updateWaitingUSES` in the background and no separate refresh wrapper is
  exported.
- Added `build_key_from_columns()` to build CatMapper `FIELD == VALUE`
  expressions from one or more columns.
- Upload wrappers now always send standard key mode and no longer expose
  simple-mode toggles.
- Added tests for metadata/property wrapper behavior, endpoint construction, and API error handling.
- Declared `R (>= 4.1.0)` explicitly to match use of the native pipe operator.
- Removed the SSL peer-verification override from `callAPI()`.
- Refreshed README, vignette, pkgdown reference structure, and stability notes to better reflect the current exported API.
- Cleaned packaging hygiene by excluding generated vignette outputs from builds and removing stale tracked build artifacts from the repo.
- Note: `get_properties()` depends on API deployments that expose `/metadata/properties/<database>`. During rollout, some deployments may support `get_upload_properties()` before `get_properties()`.

# CatMapR 0.1.2 (2026-03-18)

- Normalized package metadata for CRAN submission (`Title`, `Version`, `License`,
  `URL`, and `BugReports`).
- Standardized top-level package files for CRAN checks (`README.md`) and added
  build ignore rules for local check artifacts.
- Made API examples CRAN-safe by wrapping network calls in `\\dontrun{}`.
- Added central input-validation helpers and wired them into exported API
  wrappers for clearer error messages and safer inputs.
- Added tests covering new validation behavior.
- Added an API stability contract to freeze the `0.1.x` public interface.
- Added CRAN submission comments draft (`cran-comments.md`).
