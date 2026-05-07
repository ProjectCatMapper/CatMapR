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

- Retrieve dataset catalog metadata from CatMapper databases.
- Search for specific categories or entities and obtain detailed information.
- Translate terms within datasets based on domain-specific categories, enabling data consistency and integration across diverse datasets.
- Discover domain and property metadata used by CatMapper deployments.
- Create and join datasets across different domains for integrated analysis.
- Submit authenticated edit/upload operations using API-key-based write access. See the [Standard Upload/Edit Options Table](#standard-uploadedit-options) below for a summary of available upload/edit actions.

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

- **`list_datasets()`**: List dataset catalog metadata for `SocioMap` or `ArchaMap`.
- **`get_dataset_metadata()`**: Retrieve metadata for a specific dataset CMID.
- **`get_cmid_info()`**: Fetch details about a specific entity by CatMapper ID (CMID).
- **`search_database()`**: Search for terms within a database, optionally filtering by domain, property, year, and context.
- **`translate_rows()`**: Translate terms within data frames by matching specified properties and domains.
- **`propose_merge_links()`**: Propose merge keys for selected datasets within a category domain.
- **`join_datasets()`**: Join two aligned datasets through CatMapper matching infrastructure.
- **`get_domains()`**: Retrieve CatMapper domain/subdomain metadata.
- **`get_upload_properties()`**: Retrieve upload-oriented property metadata grouped into node and USES relationship fields.
- **`get_properties()`**: Retrieve flattened property metadata from API deployments that expose `/metadata/properties/<database>`.
- **`build_key()`**: Build upload-ready key expressions in `FIELD == VALUE` format.
- **`normalize_key()`**: Normalize stored-form keys for reuse in upload workflows.
- **`is_normalized_key()`**: Check whether key values are upload-ready expressions.
- **`prepare_upload_rows()`**: Validate upload payload shape before write calls.
- **`upload_rows()`**: Upload edit-page rows to CatMapper's `/uploadInputNodes` endpoint (write operation; API key required), then automatically trigger waiting-USES contextual refresh in the background.

### Internal helper

- **`callAPI()`**: Internal helper used by exported wrappers. This is not part of the preferred user-facing API.

### Metadata helper notes

- `get_upload_properties()` targets the canonical production API and is intended for upload/edit introspection.
- `get_properties()` depends on deployments that expose `GET /metadata/properties/<database>`. During rollout, some deployments may support `get_upload_properties()` before `get_properties()`.

### What CatMapR Returns

- **Returns metadata and API responses**, including dataset catalog fields (for example CMID, CMName, citations, relationships), category matches, translation/join outputs, and metadata/property tables.
- **Does not download dataset source files** managed outside CatMapper. User-owned raw datasets remain external inputs to your R workflow.

### UI-to-R Function Mapping

- In routes like `/:database/explore`, `:database` means the app path segment, `sociomap` or `archamap` (for example `/sociomap/explore`).

| CatMapperJS route      | UI workflow                                                              | CatMapR functions                                       |
| ---------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------- |
| `/:database/explore`   | Search and inspect entities/categories                                   | `search_database()`, `get_cmid_info()`, `get_domains()` |
| `/:database/translate` | Translate labels and review proposed matches                             | `translate_rows()`                                      |
| `/:database/merge`     | Propose key mappings and join aligned tables                             | `propose_merge_links()`, `join_datasets()`              |
| `/:database/edit`      | Authenticated edit upload with automatic waiting-USES contextual refresh | `get_upload_properties()`, `upload_rows()`              |

## Usage

Here are examples of how to use the primary functions in **CatMapR**.

### Standard Upload/Edit Options

The following table summarizes the available upload/edit actions and their meanings. Refer to this table when preparing data for upload or when using the `upload_rows()` function:

| Option Key      | Label                                                              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| --------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| add_node        | Adding new node for every row                                      | Create a new node for each row. Use when each row represents a distinct new node.                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| node_add        | Updating existing Node properties--add or add to properties        | Update existing node properties by adding values without replacing current values.                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| node_replace    | Updating existing Node properties--replace one property            | Update one existing node property by replacing its value. Replace mode supports one property column.                                                                                                                                                                                                                                                                                                                                                                                                                             |
| add_uses        | Adding new uses ties (with old or new nodes)                       | Create USES ties for rows and include new or existing nodes. Rows can be aggregated by datasetID, CMID, and Key.                                                                                                                                                                                                                                                                                                                                                                                                                 |
| update_add      | Updating existing USES only--add or add to properties              | Update existing USES ties by adding values without removing current values.                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| update_replace  | Updating existing USES only--replace one property                  | Replace one property on existing USES ties. Replace mode supports one property column.                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| add_merging     | Adding new merging ties for every row                              | Create merging ties for rows in the upload file. Requires mergingID and datasetID. Variable-merging uploads also require Key so the DATASET-to-VARIABLE MERGING tie can be scoped to a specific dataset key without changing the dataset itself. If a stackID column is also provided, no new STACK node is created — the existing STACK node is used and MERGING ties are created from the MERGING node to that STACK and from that STACK to the DATASET. If stackID is omitted, a new STACK node is auto-created for each row. |
| merging_add     | Updating existing Merging tie properties--add or add to properties | Update existing merging tie properties by adding values without replacing current values.                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| merging_replace | Updating existing Merging tie properties--replace one property     | Replace one property on an existing merging tie. Replace mode supports one property column.                                                                                                                                                                                                                                                                                                                                                                                                                                      |

When using edit/upload workflows, select the appropriate option key from this table to control the upload behavior.

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
dataset_catalog <- list_datasets(database = "SocioMap")
print(dataset_catalog)

```

### Retrieve Metadata for a Dataset CMID

```r
# Preferred metadata-focused alias
dataset_meta <- get_dataset_metadata(database = "SocioMap", cmid = "SD1", domain = "CATEGORY")
print(dataset_meta)
```

Returned metadata keys can be stored-form values (for example `Region == Flagstaff`).
Use `normalize_key()` before reusing keys in upload payloads.

### Retrieve Domain Metadata

```r
domains <- get_domains(database = "ArchaMap")
head(domains)
```

### Retrieve Upload-Oriented Property Metadata

```r
upload_props <- get_upload_properties(database = "ArchaMap")
head(upload_props$nodeProperties)
head(upload_props$usesProperties)
```

### Retrieve Flattened Property Metadata

```r
# This wrapper depends on API deployments exposing /metadata/properties/<database>
# properties <- get_properties(database = "ArchaMap")
# head(properties)
```

### Retrieve Details for a Specific CMID

```r
# Retrieve information for a specific CatMapper ID (e.g., "SM1") in SocioMap
cmid_info <- get_cmid_info(database = "SocioMap", cmid = "SM1")
print(cmid_info)
```

### Create Linkfile for Dataset Merges

```r
# Create a linkfile to merge datasets based on the ETHNICITY domain
merged_data <- propose_merge_links(
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
joined_data <- join_datasets(
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
search_results <- search_database(
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
translated_df <- translate_rows(
  rows = df,
  database = "SocioMap",
  domain = "ADM0",
  term = "country",
  property = "Name"
)
print(translated_df$file)
```

### Upload Edit-Page Data (Write API)

CatMapR upload calls always use standard key expressions. `Key` values must
already be full expressions like `VARIABLE == VALUE` (and may include `&&`).

`upload_rows()` automatically triggers contextual USES relationship refresh in
the graph database after upload submission. This refresh is fire-and-forget
and is not polled for completion.

#### Full edit upload action crosswalk

This table maps CatMapR upload action values to the exact CatMapperJS Edit-page
advanced option labels.

| CatMapR `action` value | Edit page GUI value | Typical purpose |
| --- | --- | --- |
| `add_node` | `Adding new node for every row` | Create new category or dataset nodes from upload rows. |
| `node_add` | `Updating existing Node properties--add or add to properties` | Add one or more properties to existing nodes without replacing current values. |
| `node_replace` | `Updating existing Node properties--replace one property` | Replace one property value on existing nodes. |
| `add_uses` | `Adding new uses ties (with old or new nodes)` | Create dataset-to-category `USES` ties. |
| `update_add` | `Updating existing USES only--add or add to properties` | Add one or more properties to existing `USES` ties. |
| `update_replace` | `Updating existing USES only--replace one property` | Replace one property value on existing `USES` ties. |
| `add_merging` | `Adding new merging ties for every row` | Create new merging ties from upload rows. |
| `merging_add` | `Updating existing Merging tie properties--add or add to properties` | Add one or more properties to existing merging ties. |
| `merging_replace` | `Updating existing Merging tie properties--replace one property` | Replace one property value on existing merging ties. |

For metadata reuse, normalize stored-form keys before upload:

```r
normalize_key("Region == Flagstaff")
# "Region == Flagstaff"
```

To build upload keys from one or more columns:

```r
rows <- data.frame(
  Type = "Adamana Brown",
  Region = "Flagstaff",
  stringsAsFactors = FALSE
)

build_key_from_columns(rows, c("Type", "Region"))
# Key: "Type == Adamana Brown && Region == Flagstaff"
```

#### Add USES ties (`action = "add_uses"`)

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

result <- upload_rows(
  df = upload_payload,
  database = "SocioMap",
  form_data = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    alternateCategoryNamesColumns = character(0),
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  action = "add_uses",
  api_key = Sys.getenv("CATMAPR_API_KEY"),
  poll_interval_seconds = 1,
  timeout_seconds = 600
)

head(result)
```

#### Update existing USES properties (`action = "update_add"`)

```r
update_add_payload <- data.frame(
  CMID = "SM123",
  Key = "Type == Adamana Brown",
  datasetID = "SD1",
  variable = "CeramicType",
  stringsAsFactors = FALSE
)

upload_rows(
  df = update_add_payload,
  database = "SocioMap",
  form_data = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  action = "update_add",
  properties = c("variable"),
  api_key = Sys.getenv("CATMAPR_API_KEY")
)
```

#### Replace existing USES properties (`action = "update_replace"`)

```r
update_replace_payload <- data.frame(
  CMID = "SM123",
  Key = "Type == Adamana Brown",
  NewKey = "Type == Tusayan Gray",
  datasetID = "SD1",
  stringsAsFactors = FALSE
)

upload_rows(
  df = update_replace_payload,
  database = "SocioMap",
  form_data = list(
    domain = "ETHNICITY",
    subdomain = "ETHNICITY",
    datasetID = "SD1",
    cmNameColumn = "CMName",
    categoryNamesColumn = "Name",
    cmidColumn = "CMID",
    keyColumn = "Key"
  ),
  action = "update_replace",
  properties = c("NewKey"),
  api_key = Sys.getenv("CATMAPR_API_KEY")
)
```

### Merge Template Endpoints (No API Key Required)

The merge-template endpoints used by CatMapperJS are available without an API
key. CatMapR exposes wrappers for the main read and generate flows:

```r
# Fetch merge-template rows for a dataset
template_rows <- get_merge_template(
  database = "ArchaMap",
  dataset_id = "AD947"
)

# Fetch the MERGING/STACK summary payload used by the node page
template_summary <- get_merge_template_summary(
  database = "ArchaMap",
  cmid = "AMM1"
)

# Generate merge syntax files from a template data frame
syntax_result <- build_merge_syntax(
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
