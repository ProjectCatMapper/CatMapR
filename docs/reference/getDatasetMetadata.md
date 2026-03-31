# Get Dataset Metadata by CMID

Preferred metadata-focused alias for
[`datasetInfo()`](https://projectcatmapper.github.io/CatMapR/reference/datasetInfo.md).
This function returns dataset metadata records, not raw dataset files.
Returned `Key` values can be stored-form keys (for example prefixed with
`Key == `) and may need normalization before reuse in upload workflows.

## Usage

``` r
getDatasetMetadata(database, CMID, domain = "CATEGORY", children = NULL)
```

## Arguments

- database:

  A string specifying the database to search in. Valid options are
  "SocioMap" or "ArchaMap".

- CMID:

  The CMID of the dataset to retrieve information for (e.g., "SD1" or
  "AD1").

- domain:

  (Optional) A category to filter dataset relationships. Defaults to
  "CATEGORY" if not specified.

- children:

  (Optional) If TRUE, include child datasets in the query.

## Value

A list containing dataset metadata details, or an error message if the
request fails.

## Examples

``` r
if (FALSE) { # \dontrun{
getDatasetMetadata(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
getDatasetMetadata(database = "ArchaMap", CMID = "AD1")
} # }
```
