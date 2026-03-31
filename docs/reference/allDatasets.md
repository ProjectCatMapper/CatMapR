# Retrieve Dataset Catalog Metadata from a Specified Database

This function retrieves dataset catalog metadata from a specified
database. It returns information such as dataset identifiers, names,
applicable years, project details, and related metadata fields.

## Usage

``` r
allDatasets(database)
```

## Arguments

- database:

  A string specifying the database from which to retrieve datasets.
  Valid options are "SocioMap" or "ArchaMap".

## Value

A list containing metadata records for each dataset, or an error message
if the request fails. The list typically includes fields such as nodeID,
CMName, CMID, shortName, project, Unit, parent, ApplicableYears, and
more. This function returns metadata records, not raw dataset files.

## Examples

``` r
if (FALSE) { # \dontrun{
allDatasets(database = "SocioMap")
allDatasets(database = "ArchaMap")
} # }
```
