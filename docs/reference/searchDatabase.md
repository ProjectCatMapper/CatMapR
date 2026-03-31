# Search

Search for a term in a database and retrieve the CMID (CatMapperID),
CMName (CatMapper Name), and other information about the matches.

## Usage

``` r
searchDatabase(
  database,
  domain = NULL,
  term = NULL,
  property = "Name",
  yearStart = NULL,
  yearEnd = NULL,
  country = NULL,
  context = NULL,
  dataset = NULL,
  query = "false",
  limit = 1000
)
```

## Arguments

- database:

  name of database (SocioMap or ArchaMap)

- domain:

  name of category domain to search for (DISTRICT, ETHNICITY, etc.)

- term:

  search term ("Afghanistan")

- property:

  property to search by (Name, CMID, or Key)

- yearStart:

  year to search by start

- yearEnd:

  year to search by end

- country:

  country to search by (must be a CMID)

- context:

  context to search by (e.g., hierarchical category as in the state for
  a county–must be a CMID)

- dataset:

  dataset to search by (must be a dataset CMID)

- query:

  return query instead of results ('true' or 'false')

- limit:

  limit number of results (currently ignored by API and capped at 10,000
  server-side)

## Value

A list with `data` and `count` elements.

## Examples

``` r
if (FALSE) { # \dontrun{
searchDatabase(database = "SocioMap", domain = "ETHNICITY", term = "Dan", property = "Name")
} # }
```
