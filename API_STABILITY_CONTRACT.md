# CatMapR Public API Contract (Pre-release)

Updated: 2026-11-13 (0.1.19)

## Purpose
This document records the current public CatMapR interface and the backend
endpoint contracts it relies on while the package is pre-release.

## Current Public R Interface

### Dataset metadata
- `list_datasets()`
- `get_dataset_metadata()`

### Search and translation
- `get_cmid_info()`
- `search_database()`
- `translate_rows()`

### Merge and join
- `get_merge_template()`
- `get_merge_template_summary()`
- `build_merge_syntax()`
- `propose_merge_links()`
- `join_datasets()`

### Edit/upload
- `upload_rows()`
- `prepare_upload_rows()`
- `build_key()`
- `build_key_from_columns()`
- `normalize_key()`
- `is_normalized_key()`

### Metadata introspection
- `get_domains()`
- `get_upload_properties()`
- `get_properties()`

### Geometry, policy, and polygon uploads
- `get_geometry()`
- `explore_geometry()`
- `get_contextual_policy()`
- `validate_contextual_rows()` (read-only)
- `preflight_polygon_upload()` (no graph writes)
- `apply_polygon_upload()` (explicit write submission)
- `discard_polygon_upload()` (unused token/file cleanup)
- `cancel_upload_task()` (cooperative cancellation request)

### Compatibility surface
Existing camelCase wrappers remain exported, including `uploadInputNodes()`,
`uploadInputNodesStatus()`, `waitForUploadTask()`, `updateWaitingUSES()`, and
`submitEditUpload()`. Snake_case names are preferred for new workflows.

### Structured failures
HTTP and failed/canceled upload-task errors inherit from `catmapr_api_error`,
`error`, and `condition`. Conditions retain the server `response` and
`error_details`; `status_code` is populated for HTTP failures and `task_id` for
task failures. Existing `tryCatch(error = ...)` handling remains valid.

## Rollout-dependent Interface
The function `get_properties()` depends on deployments exposing:

- `GET /metadata/properties/<database>`

During rollout, some deployments may support
`get_upload_properties()` before `get_properties()`.

## Backend Endpoint Compatibility Requirement
CatMapR currently calls these API endpoints:

- `GET /CMID/{database}/{cmid}`
- `GET /allDatasets`
- `GET /dataset`
- `GET /search`
- `GET /getTranslatedomains`
- `GET /metadata/uploadProperties/<database>`
- `GET /metadata/properties/<database>`
- `POST /translate`
- `POST /joinDatasets`
- `POST /proposeMergeSubmit`
- `POST /uploadInputNodes`
- `POST /uploadInputNodesStatus`
- `POST /updateWaitingUSES` (triggered internally by `upload_rows()`)
- `POST /api/uploads/geojson/polygons/preflight` (multipart file upload)
- `POST /api/uploads/geojson/polygons/{token}/apply`
- `DELETE /api/uploads/geojson/polygons/{token}`
- `POST /api/uploads/input-nodes/cancel`
- `GET /api/geometry`
- `GET /api/databases/{database}/nodes/{cmid}/explore-geometry`
- `GET /api/databases/{database}/metadata/contextual-policy`
- `POST /api/databases/{database}/metadata/contextual-policy/validate`

Polygon endpoints require administrator credentials and existing USES targets.
New wrappers require deployments exposing the listed endpoints. Policy preflight
checks contextual rules only; server-side edit validation remains authoritative.

## Change Management (Pre-release)
- Since CatMapR has not been officially released, backward compatibility is
  not guaranteed.
- Any public rename or signature change must update wrappers, tests, vignettes,
  README, and pkgdown references in the same change set.
