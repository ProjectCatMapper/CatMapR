
# CatMapR

**CatMapR** is an R package that provides an interface to the [CatMapper API](https://catmapper.org), facilitating access to datasets, categories, and entities managed within CatMapper's systems, including `SocioMap` and `ArchaMap`. CatMapper organizes complex category systems—such as ethnicities, languages, religions, political districts, and artifacts—frequently used in social science and archaeological research.

This package allows users to:
- Retrieve datasets and associated metadata from CatMapper databases.
- Search for specific categories or entities and obtain detailed information.
- Translate terms within datasets based on domain-specific categories, enabling data consistency and integration across diverse datasets.
- Create and join datasets across different domains for integrated analysis.

## Installation

Currently, **CatMapR** is only available on GitHub. To install it, use the following commands in R:

```r
# Install remotes if not already installed
install.packages("remotes")

# Install CatMapR from GitHub
remotes::install_github("projectCatMapper/CatMapR")
```

## Package Overview

The **CatMapR** package includes the following main functions:

- **`allDatasets`**: Retrieves all datasets from a specified database (`SocioMap` or `ArchaMap`).
- **`callAPI`**: Helper function for calling the CatMapper API with specified parameters.
- **`CMIDinfo`**: Fetches details about a specific entity by CatMapper ID (CMID).
- **`createLinkfile`**: Proposes and returns a merge of datasets based on a category domain and specified datasets.
- **`datasetInfo`**: Retrieves information about a dataset based on a given CMID, with optional filtering by domain.
- **`joinDatasets`**: Joins two datasets based on specified parameters, returning the joined data with translated keys.
- **`searchDatabase`**: Searches for terms within a database, allowing filtering by domain, property, year, and context.
- **`translate`**: Translates terms within datasets by matching specified properties and domains, facilitating category consistency across data sources.

## Usage

Here are examples of how to use the primary functions in **CatMapR**.

### Retrieve All Datasets

```r
# Retrieve all datasets from the SocioMap database
all_datasets <- allDatasets(database = "SocioMap")
print(all_datasets)
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
  categoryLabel = c("ETHNICITY"),
  datasetChoices = c("SD5", "SD6"),
  database = "SocioMap"
)
print(merged_data)
```

### Join Datasets by Key

```r
# Join two datasets by matching keys in the SocioMap database
autoLeft <- data.frame(datasetID = "SD1", country = "Afghanistan", GID = "AFG", val0 = 1)
autoRight <- data.frame(datasetID = "SD2", country = "Afghanistan", geonameid = "1149361", val1 = 2)
joined_data <- joinDatasets(database = "SocioMap", autoLeft = autoLeft, autoRight = autoRight)
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
print(search_results)
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
print(translated_df)
```

## Dependencies

CatMapR relies on the following R packages:
- `httr`: For making HTTP requests to the CatMapper API.
- `jsonlite`: For handling JSON responses.
- `tictoc`: For timing API calls.
- `xml2`: For parsing XML content when applicable.

## License

CatMapR is licensed under the GNU General Public License (GPL).
