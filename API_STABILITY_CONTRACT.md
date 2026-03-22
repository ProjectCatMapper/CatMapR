# CatMapR API Stability Contract

Effective date: 2026-03-22

## Purpose
This document defines the stability commitments for CatMapR's current public interface.

## Stable Public R Interface
The following exported functions are considered stable and should not receive breaking signature changes within the current minor release line without a migration path:

### Dataset metadata
- `listDatasetMetadata()`
- `allDatasets()`
- `getDatasetMetadata()`
- `datasetInfo()`

### Search and translation
- `CMIDinfo()`
- `searchDatabase()`
- `translate()`

### Merge and join
- `createLinkfile()`
- `joinDatasets()`

### Edit/upload
- `uploadInputNodes()`
- `updateWaitingUSES()`
- `submitEditUpload()`

### Metadata introspection
- `getDomains()`
- `getUploadProperties()`

## Experimental / rollout-dependent interface
The following exported function is public but depends on deployment support that may lag behind package releases:

- `getProperties()`

Current expectation:
- `getProperties()` should target API deployments exposing `GET /metadata/properties/<database>`.
- Until all production deployments expose that route, callers may need to point `CATMAPR_API_URL` (or `url`) at a deployment that has it.

## Freeze Rules
- Do not remove or rename exported functions.
- Do not rename existing arguments.
- Do not change argument semantics in a way that breaks valid existing calls.
- Do not remove fields from successful return payloads that downstream scripts may depend on.
- Bug fixes and stricter validation are allowed if successful existing usage is preserved.

## Backend Endpoint Compatibility Requirement
CatMapR currently calls these API endpoints. Breaking changes to these endpoints should be avoided unless a compatibility path is provided:

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
- `POST /updateWaitingUSES`

### Endpoint Compatibility Rules
- Do not remove these endpoints without introducing versioned replacements.
- Do not change required parameter names or types without backward compatibility.
- Do not remove response fields that are already consumed by CatMapR wrappers.
- If behavior must change, ship additive changes first and announce deprecation before removal.

## Change Management
- Any proposed breaking change must include:
  - a migration plan,
  - deprecation timeline,
  - and corresponding CatMapR release notes.
- Breaking changes should be deferred to a major version transition.
