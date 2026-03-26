![R-CMD-check](https://github.com/ProjectCatMapper/CatMapR/actions/workflows/R-CMD-check.yaml/badge.svg)

# CatMapR

## Package Documentation

Project page (package docs): https://projectcatmapper.github.io/CatMapR/

This site contains the CatMapR package documentation, including function reference pages, articles, and usage guidance.

<p>
  <img src="man/figures/catmapper-logo.webp" alt="CatMapper logo" height="15" />
  <img src="man/figures/sociomap-logo.webp" alt="SocioMap logo" height="17" />
  <img src="man/figures/archamap-logo.webp" alt="ArchaMap logo" height="17" />
</p>

**CatMapR** is an R package that provides an interface to the [CatMapper API](https://catmapper.org), facilitating access to dataset catalog metadata, categories, and entities managed within CatMapper's systems, including `SocioMap` and `ArchaMap`. CatMapper organizes complex category systems—such as ethnicities, languages, religions, political districts, and artifacts—frequently used in social science and archaeological research.

This package allows users to:

* Retrieve dataset catalog metadata from CatMapper databases.
* Search for specific categories or entities and obtain detailed information.
* Translate terms within datasets based on domain-specific categories, enabling data consistency and integration across diverse datasets.
* Discover domain and property metadata used by CatMapper deployments.
* Create and join datasets across different domains for integrated analysis.
* Submit authenticated edit/upload operations using API-key-based write access.

## Installation

Currently, **CatMapR** is only available on GitHub. To install it, use the following commands in R:

```r
# Install remotes if not already installed
install.packages("remotes")

# Install CatMapR from GitHub
remotes::install_github("projectCatMapper/CatMapR")
```

## Package Overview

### Preferred public functions

- **`listDatasetMetadata()`**: List dataset catalog metadata for `SocioMap` or `ArchaMap`.
- **`getDatasetMetadata()`**: Retrieve metadata for a specific dataset CMID.
- **`CMIDinfo()`**: Fetch details about a specific entity by CatMapper ID (CMID).
- **`searchDatabase()`**: Search for terms within a database, optionally filtering by domain, property, year, and context.
- **`translate()`**: Translate terms within data frames by matching specified properties and domains.
- **`createLinkfile()`**: Propose merge keys for selected datasets within a category domain.
- **`joinDatasets()`**: Join two aligned datasets through CatMapper matching infrastructure.
- **`getDomains()`**: Retrieve CatMapper domain/subdomain metadata.
- **`getUploadProperties()`**: Retrieve upload-oriented property metadata grouped into node and USES relationship fields.
- **`getProperties()`**: Retrieve flattened property metadata from API deployments that expose `/metadata/properties/<database>`.
- **`build_key()`**: Build upload-ready key expressions in `FIELD == VALUE` format.
- **`normalize_key()`**: Normalize stored-form keys for reuse in upload workflows.
- **`is_normalized_key()`**: Check whether key values are upload-ready expressions.
- **`prepare_edit_upload()`**: Validate upload payload shape and mode before write calls.
- **`uploadInputNodes()`**: Upload edit-page rows to CatMapper's `/uploadInputNodes` endpoint (write operation; API key required).
- **`submitEditUpload()`**: Run the edit upload flow and automatically trigger waiting-USES contextual relationship refresh in the background.

### Legacy-compatible aliases

- **`allDatasets()`**: Legacy-compatible alias for `listDatasetMetadata()`.
- **`datasetInfo()`**: Legacy-compatible alias for `getDatasetMetadata()`.

### Internal helper

- **`callAPI()`**: Internal helper used by exported wrappers. This is not part of the preferred user-facing API.

### Metadata helper notes

- `getUploadProperties()` targets the canonical production API and is intended for upload/edit introspection.
- `getProperties()` depends on deployments that expose `GET /metadata/properties/<database>`. During rollout, some deployments may support `getUploadProperties()` before `getProperties()`.

### What CatMapR Returns

- **Returns metadata and API responses**, including dataset catalog fields (for example CMID, CMName, citations, relationships), category matches, translation/join outputs, and metadata/property tables.
- **Does not download dataset source files** managed outside CatMapper. User-owned raw datasets remain external inputs to your R workflow.

### UI-to-R Function Mapping

* In routes like `/:database/explore`, `:database` means the app path segment, `sociomap` or `archamap` (for example `/sociomap/explore`).

| CatMapperJS route | UI workflow | CatMapR functions |
| --- | --- | --- |
| `/:database/explore` | Search and inspect entities/categories | `searchDatabase()`, `CMIDinfo()`, `getDomains()` |
| `/:database/translate` | Translate labels and review proposed matches | `translate()` |
| `/:database/merge` | Propose key mappings and join aligned tables | `createLinkfile()`, `joinDatasets()` |
| `/:database/edit` | Authenticated edit upload with automatic waiting-USES contextual refresh | `getUploadProperties()`, `uploadInputNodes()`, `submitEditUpload()` |

## Usage

Here are examples of how to use the primary functions in **CatMapR**.

### Configure API URL (Optional)

Set `CATMAPR_API_URL` to point to a different CatMapper API deployment:

```r
Sys.setenv(CATMAPR_API_URL = "https://api.catmapper.org")
```

### Write Access and Authentication

Write endpoints (for example uploads) require a valid API key from a registered CatMapper account:

```r
Sys.setenv(CATMAPR_API_KEY = "cmk_your_api_key")
```

CatMapR reads `CATMAPR_API_KEY` first, and falls back to `CATMAPPER_API_KEY` when needed.

- How to get an API key: https://catmapper.org/help/API.html#api-key-access
- For write upload calls, CatMapper identifies the acting user from the API key on the server side.
- Server-side permissions determine whether that user can run the requested write action.
- CatMapR does not implement username/password login flows; it sends API-key-authenticated requests for write uploads.

### Retrieve Dataset Catalog Metadata

```r
# Preferred metadata-focused alias
dataset_catalog <- listDatasetMetadata(database = "SocioMap")
print(dataset_catalog)

# Legacy equivalent
# all_datasets <- allDatasets(database = "SocioMap")
# print(all_datasets)
```

### Retrieve Metadata for a Dataset CMID

```r
# Preferred metadata-focused alias
dataset_meta <- getDatasetMetadata(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
print(dataset_meta)

# Legacy equivalent
# dataset_meta <- datasetInfo(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
# print(dataset_meta)
```

Returned metadata keys can be stored-form values (for example `Key == Region == Flagstaff`).
Use `normalize_key()` before reusing keys in upload payloads.

### Retrieve Domain Metadata

```r
domains <- getDomains(database = "ArchaMap")
head(domains)
```

### Retrieve Upload-Oriented Property Metadata

```r
upload_props <- getUploadProperties(database = "ArchaMap")
head(upload_props$nodeProperties)
head(upload_props$usesProperties)
```

### Retrieve Flattened Property Metadata

```r
# This wrapper depends on API deployments exposing /metadata/properties/<database>
# properties <- getProperties(database = "ArchaMap")
# head(properties)
```

### Retrieve Details for a Specific CMID

```r
# Retrieve information for a specific CatMapper ID (e.g., "SM1") in SocioMap
cmid_info <- CMIDinfo(database = "SocioMap", cmid = "SM1")
print(cmid_info)
```

### Create Linkfile for Dataset Merges

```r
# Create a linkfile to merge datasets based on the ETHNICITY domain
merged_data <- createLinkfile(
  categoryLabel = "ETHNICITY",
  datasetChoices = c("SD5", "SD6"),
  database = "SocioMap",
  equivalence = "standard"
)
print(merged_data)
```

### Join Datasets by Key

```r
# Join two datasets by matching keys in the SocioMap database
joinLeft <- data.frame(datasetID = "SD1", country = "Afghanistan", GID = "AFG", val0 = 1)
joinRight <- data.frame(datasetID = "SD2", country = "Afghanistan", geonameid = "1149361", val1 = 2)
joined_data <- joinDatasets(
  database = "SocioMap",
  joinLeft = joinLeft,
  joinRight = joinRight,
  domain = "CATEGORY"
)
print(joined_data)
```

### Search the Database

```r
# Search for the term "Afghanistan" in the ETHNICITY domain of SocioMap
search_results <- searchDatabase(
  database = "SocioMap",
  domain = "ETHNICITY",
  term = "Afghanistan",
  property = "Name"
)
print(search_results$data)
```

### Translate Terms within a Dataset

```r
# Translate a dataframe containing a "country" column, matching with SocioMap's ADM0 domain
df <- data.frame(country = "Afghanistan")
translated_df <- translate(
  rows = df,
  database = "SocioMap",
  domain = "ADM0",
  term = "country",
  property = "Name"
)
print(translated_df$file)
```

### Upload Edit-Page Data (Write API)

Key format depends on upload mode:

- `so = "standard"` (recommended): `Key` values must already be full expressions like `VARIABLE == VALUE` (and may include `&&`).
- `so = "simple"`: only supported with `ao = "add_uses"` and key values must be raw values only (for example `eth:yoruba`) with no `==`.

If `so = "simple"` receives preformatted keys (contains `==`), CatMapR raises an error and requires `so = "standard"`.

After upload submission, CatMapR automatically triggers contextual USES relationship refresh in the graph database based on USES properties that connect to other CMIDs. This refresh is fire-and-forget and is not polled for completion.

For metadata reuse, normalize stored-form keys before upload:

```r
normalize_key("Key == Region == Flagstaff")
# "Region == Flagstaff"
```

#### Add USES ties (`ao = "add_uses"`, standard mode)

```r
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

#### Update existing USES properties (`ao = "update_add"`)

```r
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

#### Replace existing USES properties (`ao = "update_replace"`)

```r
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

### Merge Template Endpoints (No API Key Required)

The merge-template endpoints used by CatMapperJS are available without an API
key. CatMapR exposes wrappers for the main read and generate flows:

```r
# Fetch merge-template rows for a dataset
template_rows <- getMergingTemplate(
  database = "ArchaMap",
  datasetID = "AD947"
)

# Fetch the MERGING/STACK summary payload used by the node page
template_summary <- getMergingTemplateSummary(
  database = "ArchaMap",
  cmid = "AMM1"
)

# Generate merge syntax files from a template data frame
syntax_result <- createMergeSyntax(
  template = template_rows,
  database = "ArchaMap"
)

print(syntax_result$download)
```

## Dependencies

CatMapR relies on the following R packages:
- `httr`: For making HTTP requests to the CatMapper API.
- `jsonlite`: For handling JSON responses.
- `tictoc`: For timing API calls.

## License

CatMapR is licensed under the GNU General Public License (GPL).
