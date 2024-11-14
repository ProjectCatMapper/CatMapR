
# CatMapR

**CatMapR** is an R package that provides an interface to the [CatMapper API](https://catmapper.org), facilitating access to datasets, categories, and entities managed within CatMapper's systems, including `SocioMap` and `ArchaMap`. CatMapper organizes complex category systems—such as ethnicities, languages, religions, political districts, and artifacts—frequently used in social science and archaeological research. 

This package allows users to:
- Retrieve datasets and associated metadata from CatMapper databases.
- Search for specific categories or entities and obtain detailed information.
- Translate terms within datasets based on domain-specific categories, enabling data consistency and integration across diverse datasets.

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
- **`CMIDinfo`**: Fetches details about a specific entity by CatMapper ID (CMID).
- **`datasetInfo`**: Retrieves information about a dataset based on a given CMID, with optional filtering by domain.
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

### Retrieve Dataset Information by CMID with Domain Filtering

```r
# Retrieve dataset information for CMID "SD1" in SocioMap, filtering by the "CATEGORY" domain
dataset_details <- datasetInfo(database = "SocioMap", cmid = "SD1", domain = "CATEGORY")
print(dataset_details)
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
