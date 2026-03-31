# Retrieve Property Metadata from a Specified Database

This function retrieves flattened CatMapper property metadata from API
deployments that expose `/metadata/properties/<database>`. The result is
a data frame with one row per property-field/value pair from `PROPERTY`
nodes.

## Usage

``` r
getProperties(database = "SocioMap", url = NULL)
```

## Arguments

- database:

  A string specifying the database from which to retrieve property
  metadata. Valid options are `"SocioMap"` or `"ArchaMap"`.

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
  otherwise `"https://api.catmapper.org"`.

## Value

A data frame containing flattened property metadata. Typical columns
include `nodeID`, `CMName`, `property`, and `value`.

## Examples

``` r
if (FALSE) { # \dontrun{
getProperties(database = "SocioMap")
getProperties(database = "ArchaMap")
} # }
```
