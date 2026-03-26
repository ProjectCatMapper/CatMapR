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
- **`uploadInputNodes()`**: Upload edit-page rows to CatMapper's `/uploadInputNodes` endpoint (write operation; API key required).
- **`updateWaitingUSES()`**: Trigger `/updateWaitingUSES` after uploads (write operation; API key required).
- **`submitEditUpload()`**: Run the same two-step flow as the CatMapperJS edit page: upload, then waiting-USES refresh.

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
| `/:database/edit` | Authenticated edit upload and waiting-USES refresh | `getUploadProperties()`, `uploadInputNodes()`, `updateWaitingUSES()`, `submitEditUpload()` |

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

- How to get an API key: https://catmapper.org/help/API.html#api-key-access
- For write calls, CatMapper identifies the acting user from the API key on the server side.
- Server-side permissions determine whether that user can run the requested write action.
- CatMapR does not implement username/password login flows; it sends API-key-authenticated requests to the API.

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

- `so = "standard"`: `Key` values must already be full expressions like `VARIABLE == VALUE` (and may include `&&`).
- `so = "simple"`: `Key` values must be raw values only (for example `eth:yoruba`) and should not include `==`.

If `so = "simple"` receives `VARIABLE == VALUE`, CatMapR warns and strips the left-hand side before sending the payload.

```r
upload_payload <- data.frame(
  CMName = "Yoruba",
  Name = "Yoruba",
  Key = "eth:yoruba",
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
  so = "simple",
  ao = "add_uses",
  api_key = Sys.getenv("CATMAPR_API_KEY")
)

print(result$upload)
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
