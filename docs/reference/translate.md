# Translate

This function translate a dataframe by matching the specified term with
the property in the database.

## Usage

``` r
translate(
  rows,
  database,
  term,
  property = "Name",
  domain = "CATEGORY",
  context = NULL,
  country = NULL,
  dataset = NULL,
  yearStart = NULL,
  yearEnd = NULL,
  key = "false",
  query = "false",
  countsamename = FALSE,
  uniqueRows = TRUE
)
```

## Arguments

- rows:

  data frame to translate

- database:

  database to use (SocioMap or ArchaMap)

- term:

  column name to translate

- property:

  property to search by (Name, CMID, or Key)

- domain:

  name of category domain to search for (DISTRICT, ETHNICITY, etc.)

- context:

  column name of context to search by (CMID)

- country:

  column name of country to search by (CMID)

- dataset:

  column name of dataset to search by (dataset CMID)

- yearStart:

  year to search by start

- yearEnd:

  year to search by end

- key:

  include Key values in results ('true' or 'false')

- query:

  return query instead of results

- countsamename:

  count duplicate matching names in scoring logic

- uniqueRows:

  deduplicate identical input rows before matching

## Value

A list with `file` and `order` from the API.

## Examples

``` r
if (FALSE) { # \dontrun{
df = data.frame(country = "Afghanistan")
translate(
  rows = df,
  database = "SocioMap",
  domain = "ADM0",
  term = "country",
  property = "Name",
  yearStart = NULL,
  yearEnd = NULL,
  country = NULL,
  context = NULL,
  query = "false"
)
} # }
```
