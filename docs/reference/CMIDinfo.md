# Retrieve Details for a Specific CMID (CatMapperID)

This function retrieves detailed information about a specified
CatMapperID (CMID) from a specified database. It fetches both node
properties and their relationships associated with the given CMID.

## Usage

``` r
CMIDinfo(database, cmid)
```

## Arguments

- database:

  A string specifying the database to search in. Valid options are
  "SocioMap" or "ArchaMap".

- cmid:

  The CatMapperID for which details are to be retrieved (e.g., "SM1" or
  "AM1").

## Value

A list containing node properties and relationships associated with the
specified CMID, or an error message if the request fails.

## Examples

``` r
if (FALSE) { # \dontrun{
CMIDinfo(database = "SocioMap", cmid = "SM1")
CMIDinfo(database = "ArchaMap", cmid = "AM1")
} # }
```
