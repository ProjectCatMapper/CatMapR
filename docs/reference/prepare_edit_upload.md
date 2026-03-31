# Prepare Edit Upload Payload Components

Validates upload mode, operation, formData mappings, and key safety
before sending write requests.

## Usage

``` r
prepare_edit_upload(
  df,
  formData = list(),
  so = "standard",
  ao = "add_node",
  allContext = list(),
  optionalProperties = NULL,
  mergingType = "0",
  database = "SocioMap",
  fail_on_simple_mismatch = TRUE
)
```

## Arguments

- df:

  Data frame or list of row objects to upload.

- formData:

  Named list matching the edit-page `formData` payload.

- so:

  Upload mode, usually `"standard"` or `"simple"`.

- ao:

  Advanced upload option. Supported values map directly to CatMapper
  Edit-page Advanced options:

  - `"add_node"` = "Adding new node for every row"

  - `"add_uses"` = "Adding new uses ties (with old or new nodes)"

  - `"update_add"` = "Updating existing USES only–add or add to
    properties"

  - `"update_replace"` = "Updating existing USES only–replace one
    property"

- allContext:

  Optional vector/list of contextual columns.

- optionalProperties:

  Optional vector/list alias for `allContext`.

- mergingType:

  Optional merging mode used by merge upload workflows.

- database:

  Target database, typically `"SocioMap"` or `"ArchaMap"`.

- fail_on_simple_mismatch:

  Internal guard; when `TRUE`, simple-mode restrictions are strictly
  enforced.

## Value

A named list with validated upload components.
