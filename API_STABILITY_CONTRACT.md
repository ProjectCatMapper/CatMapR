# CatMapR API Stability Contract

Effective date: 2026-03-18

## Purpose
This document defines the stability commitments for CatMapR's first CRAN-oriented release line.

## Public R Interface Freeze (CatMapR 0.1.x)
The following exported functions are considered stable and must not receive breaking signature changes in the `0.1.x` line:

- `CMIDinfo()`
- `allDatasets()`
- `createLinkfile()`
- `datasetInfo()`
- `joinDatasets()`
- `searchDatabase()`
- `translate()`
- `uploadInputNodes()`
- `updateWaitingUSES()`
- `submitEditUpload()`

### Freeze Rules
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
