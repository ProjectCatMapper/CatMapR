# CatMapR 0.1.2.9000

- Added metadata-introspection wrappers `getDomains()`, `getProperties()`, and `getUploadProperties()`.
- Added tests for metadata/property wrapper behavior, endpoint construction, and API error handling.
- Declared `R (>= 4.1.0)` explicitly to match use of the native pipe operator.
- Removed the SSL peer-verification override from `callAPI()`.
- Refreshed README, vignette, pkgdown reference structure, and stability notes to better reflect the current exported API.
- Cleaned packaging hygiene by excluding generated vignette outputs from builds and removing stale tracked build artifacts from the repo.
- Note: `getProperties()` depends on API deployments that expose `/metadata/properties/<database>`. During rollout, some deployments may support `getUploadProperties()` before `getProperties()`.

# CatMapR 0.1.2

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
