# List Dataset Catalog Metadata

Preferred metadata-focused alias for
[`allDatasets()`](https://projectcatmapper.github.io/CatMapR/reference/allDatasets.md).
This function returns dataset catalog metadata records, not raw dataset
files.

## Usage

``` r
listDatasetMetadata(database)
```

## Arguments

- database:

  A string specifying the database from which to retrieve datasets.
  Valid options are "SocioMap" or "ArchaMap".

## Value

A list containing metadata records for each dataset, or an error message
if the request fails.

## Examples

``` r
if (FALSE) { # \dontrun{
listDatasetMetadata(database = "SocioMap")
listDatasetMetadata(database = "ArchaMap")
} # }
```
