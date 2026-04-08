# CatMapR Public API Contract (Pre-release)

Effective date: 2026-04-08

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

## Removed Legacy Surface
Legacy pre-rename wrappers and aliases were removed from exports; only the
current snake_case public API in this document is supported.

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

## Change Management (Pre-release)
- Since CatMapR has not been officially released, backward compatibility is
  not guaranteed.
- Any public rename or signature change must update wrappers, tests, vignettes,
  README, and pkgdown references in the same change set.
