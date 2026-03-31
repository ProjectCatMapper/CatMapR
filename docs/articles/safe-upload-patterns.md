# CatMapR Safe Upload Patterns

## Why this vignette

CatMapR upload flows are usually asynchronous and can mutate production
metadata. This vignette focuses on safe defaults and repeatable
patterns.

## Upload mode matrix

- `so = "standard"` (recommended): provide fully formed `Key`
  expressions such as `Type == Adamana Brown`.
- `so = "simple"`: only valid with `ao = "add_uses"` and raw key values
  without `==`.

## Full `ao` to Edit GUI mapping

This crosswalk maps CatMapR `ao` values to the exact labels shown in the
CatMapper Edit page (**Advanced** upload options).

| CatMapR `ao` value | Edit page GUI value                                     | Typical purpose                                        |
|--------------------|---------------------------------------------------------|--------------------------------------------------------|
| `add_node`         | `Adding new node for every row`                         | Create new category or dataset nodes from upload rows. |
| `add_uses`         | `Adding new uses ties (with old or new nodes)`          | Create dataset-to-category `USES` ties.                |
| `update_add`       | `Updating existing USES only--add or add to properties` | Add one or more properties to existing `USES` ties.    |
| `update_replace`   | `Updating existing USES only--replace one property`     | Replace an existing property value on `USES` ties.     |

Notes:

- `so = "simple"` is supported only when `ao = "add_uses"`.
- For `so = "standard"`, required columns vary by `ao` and are validated
  before upload.

## Key helper patterns

``` r
build_key("Type", "Adamana Brown")
normalize_key("Key == Region == Flagstaff")
is_normalized_key("Region == Flagstaff")
```

## Add USES ties safely

``` r
payload <- data.frame(
  CMName = "Yoruba",
  Name = "Yoruba",
  CMID = "",
  Key = "Type == Adamana Brown",
  datasetID = "SD1",
  label = "ETHNICITY",
  stringsAsFactors = FALSE
)

result <- submitEditUpload(
  df = payload,
  database = "SocioMap",
  formData = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  so = "standard",
  ao = "add_uses",
  api_key = Sys.getenv("CATMAPR_API_KEY")
)

head(result)
```

## Update existing USES properties

``` r
update_add_payload <- data.frame(
  CMID = "SM123",
  Key = "Type == Adamana Brown",
  datasetID = "SD1",
  variable = "CeramicType",
  stringsAsFactors = FALSE
)

submitEditUpload(
  df = update_add_payload,
  database = "SocioMap",
  formData = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  so = "standard",
  ao = "update_add",
  optionalProperties = c("variable"),
  api_key = Sys.getenv("CATMAPR_API_KEY")
)
```

## Replace USES key values

``` r
update_replace_payload <- data.frame(
  CMID = "SM123",
  Key = "Type == Adamana Brown",
  NewKey = "Type == Tusayan Gray",
  datasetID = "SD1",
  stringsAsFactors = FALSE
)

submitEditUpload(
  df = update_replace_payload,
  database = "SocioMap",
  formData = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  so = "standard",
  ao = "update_replace",
  optionalProperties = c("NewKey"),
  api_key = Sys.getenv("CATMAPR_API_KEY")
)
```
