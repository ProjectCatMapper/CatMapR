# Retrieve Dataset Metadata by CMID

This function retrieves dataset metadata based on a given CMID
(CatMapperID) from a specified database, with an optional domain filter.
It fetches dataset relationships and metadata properties associated with
the specified CMID.

## Usage

``` r
datasetInfo(database, CMID, domain = "CATEGORY", children = NULL)
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
request fails. This function returns metadata records, not raw dataset
files.

## Examples

``` r
if (FALSE) { # \dontrun{
datasetInfo(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
datasetInfo(database = "ArchaMap", CMID = "AD1")
} # }
```
