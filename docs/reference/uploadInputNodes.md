# Upload Edit-Page Rows to CatMapper

Mirrors the CatMapperJS edit-page upload call to `/uploadInputNodes`.
This wrapper is intended for write operations and requires a valid API
key tied to a registered CatMapper account. Server-side permissions
determine whether the authenticated user can perform the requested write
action.

## Usage

``` r
uploadInputNodes(
  df,
  database,
  formData = list(),
  so = "standard",
  ao = "add_node",
  addoptions = list(district = FALSE, recordyear = FALSE),
  allContext = list(),
  optionalProperties = NULL,
  mergingType = "0",
  api_key = NULL,
  poll_interval_seconds = 1,
  timeout_seconds = 600,
  url = NULL
)
```

## Arguments

- df:

  Data frame or list of row objects to upload.

- database:

  Target database, typically `"SocioMap"` or `"ArchaMap"`.

- formData:

  Named list matching the edit-page `formData` payload.

- so:

  Upload mode, usually `"standard"` or `"simple"`. Use `"standard"` when
  the upload key values are already full key expressions (for example
  `VARIABLE == VALUE`). Use `"simple"` when key values are raw terms
  only (for example `eth:yoruba`) without the `==` expression.

- ao:

  Advanced upload option. Supported values map directly to CatMapper
  Edit-page Advanced options:

  - `"add_node"` = "Adding new node for every row"

  - `"add_uses"` = "Adding new uses ties (with old or new nodes)"

  - `"update_add"` = "Updating existing USES only–add or add to
    properties"

  - `"update_replace"` = "Updating existing USES only–replace one
    property"

- addoptions:

  Named list with `district` and `recordyear` booleans.

- allContext:

  Optional vector/list of contextual columns.

- optionalProperties:

  Optional vector/list alias for `allContext`. When provided, this value
  is used as the upload property list.

- mergingType:

  Optional merging mode used by merge upload workflows.

- api_key:

  API key used for authenticated write actions. If `NULL`,
  `CATMAPR_API_KEY` is used.

- poll_interval_seconds:

  Polling interval in seconds while waiting for queued upload tasks.

- timeout_seconds:

  Maximum seconds to wait for upload completion.

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set.

## Value

A data frame built from the upload task result rows returned by the API.

## Details

CatMapR does not manage username/password login flows. It sends
API-key-authenticated requests and the CatMapper API identifies the
acting user on the server side. For `so = "simple"`, only
`ao = "add_uses"` is supported and key values in the selected key column
must be raw values without `==`. For the full `ao` crosswalk and
examples, see
[`vignette("safe-upload-patterns", package = "CatMapR")`](https://projectcatmapper.github.io/CatMapR/articles/safe-upload-patterns.md).

## Examples

``` r
if (FALSE) { # \dontrun{
upload_result <- uploadInputNodes(
  df = data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    CMID = "",
    Key = "Type == Adamana Brown",
    datasetID = "SD1",
    label = "ETHNICITY",
    stringsAsFactors = FALSE
  ),
  database = "SocioMap",
  formData = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    alternateCategoryNamesColumns = character(0),
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  so = "standard",
  ao = "add_uses",
  poll_interval_seconds = 1,
  timeout_seconds = 600,
  api_key = Sys.getenv("CATMAPR_API_KEY")
)
head(upload_result)
} # }
```
