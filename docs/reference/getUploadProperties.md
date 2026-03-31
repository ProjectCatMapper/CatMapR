# Retrieve Upload Property Metadata from a Specified Database

This function retrieves upload-oriented CatMapper property metadata for
a specified database. The API groups results into node properties and
USES relationship properties.

## Usage

``` r
getUploadProperties(database = "SocioMap", url = NULL)
```

## Arguments

- database:

  A string specifying the database from which to retrieve upload
  property metadata. Valid options are `"SocioMap"` or `"ArchaMap"`.

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
  otherwise `"https://api.catmapper.org"`.

## Value

A list with three elements:

- database:

  Database name returned by the API.

- nodeProperties:

  A data frame of node property metadata.

- usesProperties:

  A data frame of USES relationship property metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
getUploadProperties(database = "SocioMap")
getUploadProperties(database = "ArchaMap")
} # }
```
