# CatMapR End-to-End Workflow

## Overview

CatMapper is a platform for organizing and harmonizing category systems
across datasets. It currently includes two applications: **SocioMap**,
which focuses on social-science categories (for example ethnicities,
languages, religions, and administrative units), and **ArchaMap**, which
focuses on archaeological categories (for example artifact types and
cultural periods). CatMapR is an API wrapper for the CatMapper API, and
all package functions are also available through the CatMapper web
application at <https://catmapper.org>.

This vignette shows a standard CatMapR workflow:

1.  list available dataset metadata,
2.  inspect metadata helpers,
3.  search and inspect categories,
4.  translate external labels,
5.  run basic quality checks,
6.  join harmonized tables.

By default, chunks run in offline demo mode for reproducible rendering.

## Why Use CatMapper?

Researchers often work with datasets that describe the same category
systems in different and incompatible ways. CatMapper helps by:

- identifying likely matches across naming variants and coding systems,
- preserving context needed for disambiguation (for example place,
  domain, or period),
- reducing manual harmonization effort before analysis,
- making joins across independently structured datasets more
  reproducible.

CatMapR provides these capabilities in scriptable R workflows, so
translation, quality checks, and joins can be rerun consistently as data
updates.

## What CatMapR Returns

CatMapR wrappers return CatMapper API responses, including:

- dataset catalog metadata (for example CMID, CMName, citation fields,
  years),
- category/entity metadata and relationship details,
- translation and join outputs,
- metadata/property discovery tables.

CatMapR does **not** fetch raw dataset source files managed outside
CatMapper. User-owned/raw datasets are external inputs to your R
workflow.

## UI-to-R Function Mapping

- In routes like `/:database/explore`, `:database` means the app path
  segment, `sociomap` or `archamap` (for example `/sociomap/explore`).

| CatMapperJS route      | Typical UI step                                                          | CatMapR function(s)                                                                                                                                                                                                                                                                                        |
|------------------------|--------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/:database/explore`   | Search categories/entities and inspect details                           | [`searchDatabase()`](https://projectcatmapper.github.io/CatMapR/reference/searchDatabase.md), [`CMIDinfo()`](https://projectcatmapper.github.io/CatMapR/reference/CMIDinfo.md), [`getDomains()`](https://projectcatmapper.github.io/CatMapR/reference/getDomains.md)                                       |
| `/:database/translate` | Upload labels, run matching, review translated outputs                   | [`translate()`](https://projectcatmapper.github.io/CatMapR/reference/translate.md)                                                                                                                                                                                                                         |
| `/:database/merge`     | Propose merge keys and join aligned datasets                             | [`createLinkfile()`](https://projectcatmapper.github.io/CatMapR/reference/createLinkfile.md), [`joinDatasets()`](https://projectcatmapper.github.io/CatMapR/reference/joinDatasets.md)                                                                                                                     |
| `/:database/edit`      | Authenticated edit upload with automatic waiting-USES contextual refresh | [`getUploadProperties()`](https://projectcatmapper.github.io/CatMapR/reference/getUploadProperties.md), [`uploadInputNodes()`](https://projectcatmapper.github.io/CatMapR/reference/uploadInputNodes.md), [`submitEditUpload()`](https://projectcatmapper.github.io/CatMapR/reference/submitEditUpload.md) |

## UI Workflow Crosswalk (Detailed)

| User intent                      | CatMapper UI path                          | UI action                                                 | CatMapR call pattern                                                                |
|----------------------------------|--------------------------------------------|-----------------------------------------------------------|-------------------------------------------------------------------------------------|
| Browse available dataset records | `/:database` and `/:database/explore`      | Open database and review dataset catalog entries          | `listDatasetMetadata(database)` (legacy: `allDatasets(database)`)                   |
| Inspect one known dataset CMID   | `/:database/:cmid`                         | Open dataset info page                                    | `getDatasetMetadata(database, CMID, domain, children)` (legacy: `datasetInfo(...)`) |
| Browse metadata helpers          | `/:database/explore` and `/:database/edit` | Inspect available domains and property fields             | `getDomains(database)`, `getUploadProperties(database)`                             |
| Find entities/categories         | `/:database/explore`                       | Run search filters and inspect hits                       | `searchDatabase(...)`, then `CMIDinfo(...)`                                         |
| Harmonize labels                 | `/:database/translate`                     | Upload table and run translation                          | `translate(rows, database, term, ...)`                                              |
| Build merge candidates           | `/:database/merge`                         | Propose merge linkfile                                    | `createLinkfile(categoryLabel, datasetChoices, ...)`                                |
| Join aligned sources             | `/:database/merge`                         | Run join on matched keys                                  | `joinDatasets(database, joinLeft, joinRight, ...)`                                  |
| Submit metadata/category edits   | `/:database/edit`                          | Upload edit rows and auto-trigger contextual USES refresh | `submitEditUpload(...)` (preferred) or `uploadInputNodes(...)`                      |

## Setup

``` r
library(CatMapR)

# Optional API override:
# Sys.setenv(CATMAPR_API_URL = "https://api.catmapper.org")

run_live
#> [1] FALSE
```

## Candidate Dataset Pairings

Suggested pairings for a worked example:

- SocioMap ADM0: `SD1` (GADM 3.6) + `SD2` (GeoNames 202005)
- SocioMap ETHNICITY: `SD2176` (GeoEPR 2021) + `SD461930` (LEDA)
- SocioMap LANGUAGE: `SD3` (Glottolog 4.2.1) + `SD2196` (Wikidata)
- ArchaMap artifact/period: `AD37767` (Andrefsky 2005) + `AD37770`
  (DAI_FeatureTypes)

Dataset IDs above were confirmed on 2026-03-18 and may change as
catalogs update.

## 1) List Datasets

``` r
if (run_live) {
  datasets <- listDatasetMetadata(database = "SocioMap")
} else {
  datasets <- data.frame(
    CMID = c("SD1", "SD2", "SD2176", "SD461930"),
    CMName = c("GADM 3.6", "GeoNames Version 202005", "GeoEPR 2021", "LEDA"),
    ApplicableYears = c("2018", "2020", "1946-2021", NA),
    stringsAsFactors = FALSE
  )
}

head(datasets)
#>       CMID                  CMName ApplicableYears
#> 1      SD1                GADM 3.6            2018
#> 2      SD2 GeoNames Version 202005            2020
#> 3   SD2176             GeoEPR 2021       1946-2021
#> 4 SD461930                    LEDA            <NA>
```

## 2) Inspect Metadata Helpers

``` r
if (run_live) {
  domains <- getDomains(database = "SocioMap")
  upload_props <- getUploadProperties(database = "SocioMap")
} else {
  domains <- data.frame(
    domain = c("DISTRICT", "DISTRICT", "ETHNICITY"),
    subdomain = c("ADM0", "ADM1", "ETHNICITY"),
    description = c("Administrative district", "Administrative district", "Ethnicity category"),
    stringsAsFactors = FALSE
  )
  upload_props <- list(
    database = "SocioMap",
    nodeProperties = data.frame(property = "DatasetCitation", description = "Dataset citation", stringsAsFactors = FALSE),
    usesProperties = data.frame(property = "yearStart", description = "Starting date", stringsAsFactors = FALSE)
  )
}

head(domains)
#>      domain subdomain             description
#> 1  DISTRICT      ADM0 Administrative district
#> 2  DISTRICT      ADM1 Administrative district
#> 3 ETHNICITY ETHNICITY      Ethnicity category
head(upload_props$nodeProperties)
#>          property      description
#> 1 DatasetCitation Dataset citation
head(upload_props$usesProperties)
#>    property   description
#> 1 yearStart Starting date
```

[`getProperties()`](https://projectcatmapper.github.io/CatMapR/reference/getProperties.md)
is also available for deployments that expose
`/metadata/properties/<database>`, but rollout timing may vary by API
deployment.

## 3) Search and Inspect a Category

``` r
if (run_live) {
  hits <- searchDatabase(
    database = "SocioMap",
    domain = "ADM0",
    term = "Ghana",
    property = "Name"
  )
  details <- CMIDinfo(database = "SocioMap", cmid = "SM1")
} else {
  hits <- list(
    count = 1,
    data = data.frame(
      CMID = "SM1",
      CMName = "Ghana",
      domain = "ADM0",
      stringsAsFactors = FALSE
    )
  )
  details <- list(node = list(CMID = "SM1", CMName = "Ghana", domain = "ADM0"))
}

hits
#> $count
#> [1] 1
#> 
#> $data
#>   CMID CMName domain
#> 1  SM1  Ghana   ADM0
str(details)
#> List of 1
#>  $ node:List of 3
#>   ..$ CMID  : chr "SM1"
#>   ..$ CMName: chr "Ghana"
#>   ..$ domain: chr "ADM0"
```

## 4) Prepare External Input

``` r
raw_df <- data.frame(
  country_label = c("Ghana", "Cote dIvoire", "Tanzania"),
  year = c(2019, 2019, 2019),
  indicator_value = c(10.2, 9.7, 8.4),
  stringsAsFactors = FALSE
)

raw_df
#>   country_label year indicator_value
#> 1         Ghana 2019            10.2
#> 2  Cote dIvoire 2019             9.7
#> 3      Tanzania 2019             8.4
```

## 5) Translate Labels

``` r
if (run_live) {
  translated <- translate(
    rows = raw_df,
    database = "SocioMap",
    domain = "ADM0",
    term = "country_label",
    property = "Name",
    query = "false"
  )
} else {
  translated <- list(
    file = data.frame(
      country_label = c("Ghana", "Cote dIvoire", "Tanzania"),
      generated_CMID = c("SM1", "SM2", "SM3"),
      generated_CMName = c("Ghana", "Cote d'Ivoire", "Tanzania"),
      score = c(1, 1, 1),
      stringsAsFactors = FALSE
    )
  )
}

translated$file
#>   country_label generated_CMID generated_CMName score
#> 1         Ghana            SM1            Ghana     1
#> 2  Cote dIvoire            SM2    Cote d'Ivoire     1
#> 3      Tanzania            SM3         Tanzania     1
```

## 6) Post-Translation Checks

``` r
translated_df <- translated$file

if (!is.data.frame(translated_df) || !"generated_CMID" %in% names(translated_df)) {
  message("No `generated_CMID` column found in translation output; verify API output shape before QA checks.")
} else {
  # Rows without a CMID assignment
  translated_df[is.na(translated_df$generated_CMID), , drop = FALSE]

  # Simple duplicate check by assigned CMID
  sort(table(translated_df$generated_CMID), decreasing = TRUE)
}
#> 
#> SM1 SM2 SM3 
#>   1   1   1
```

## 7) Join Harmonized Tables

``` r
if (run_live) {
  left_df <- data.frame(
    datasetID = "SD1",
    country = c("Ghana", "Tanzania"),
    GID = c("GHA", "TZA"),
    metric_left = c(10, 20),
    stringsAsFactors = FALSE
  )

  right_df <- data.frame(
    datasetID = "SD2",
    country = c("Ghana", "Tanzania"),
    geonameid = c("2300660", "149590"),
    metric_right = c(2, 5),
    stringsAsFactors = FALSE
  )

  joined <- joinDatasets(
    database = "SocioMap",
    joinLeft = left_df,
    joinRight = right_df,
    domain = "CATEGORY"
  )
} else {
  joined <- data.frame(
    generated_CMID = c("SM1", "SM3"),
    left_metric = c(10, 20),
    right_metric = c(2, 5),
    stringsAsFactors = FALSE
  )
}

joined
#>   generated_CMID left_metric right_metric
#> 1            SM1          10            2
#> 2            SM3          20            5
```

## Optional: Authenticated Upload Flow

Write operations require a valid API key tied to a registered CatMapper
account and are shown as a template only. The server identifies the
acting user from the API key and enforces permissions for write
endpoints. CatMapR does not manage username/password login flows.

Key format depends on upload mode:

- `so = "standard"` (recommended) expects full key expressions in the
  selected key column (for example `VARIABLE == VALUE`).
- `so = "simple"` is only supported with `ao = "add_uses"` and expects
  raw values only (for example `eth:yoruba`) without `==`.

If preformatted key expressions are provided in `so = "simple"`, CatMapR
raises an error and requires `so = "standard"`.

After upload submission, CatMapR automatically triggers contextual USES
relationship refresh in the graph database based on USES properties that
connect to other CMIDs. This trigger is fire-and-forget and is not
polled for completion.

``` r
upload_payload <- data.frame(
  CMName = "Yoruba",
  Name = "Yoruba",
  CMID = "",
  Key = "Type == Adamana Brown",
  datasetID = "SD1",
  label = "ETHNICITY",
  stringsAsFactors = FALSE
)

result <- submitEditUpload(
  df = upload_payload,
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
  api_key = Sys.getenv("CATMAPR_API_KEY"),
  poll_interval_seconds = 1,
  timeout_seconds = 600
)

head(result)
```

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
