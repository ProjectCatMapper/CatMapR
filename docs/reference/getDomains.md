# Retrieve Domain Metadata from a Specified Database

This function retrieves CatMapper domain and subdomain metadata from a
specified database. By default, it returns a simplified data frame with
the domain, subdomain, and description columns. When `advanced = TRUE`,
it returns all metadata fields exposed by the API when available.

## Usage

``` r
getDomains(database = "SocioMap", advanced = FALSE)
```

## Arguments

- database:

  A string specifying the database from which to retrieve domains. Valid
  options are "SocioMap" or "ArchaMap".

- advanced:

  Logical; if `TRUE`, return richer metadata fields when available.
  Defaults to `FALSE`.

## Value

A data frame of domain metadata. By default, the result contains the
columns `domain`, `subdomain`, and `description`. When
`advanced = TRUE`, additional metadata columns returned by the API are
preserved.

## Examples

``` r
if (FALSE) { # \dontrun{
getDomains(database = "SocioMap")
getDomains(database = "ArchaMap", advanced = TRUE)
} # }
```
