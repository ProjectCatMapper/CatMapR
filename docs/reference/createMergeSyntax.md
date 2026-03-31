# Generate Merge Syntax Files from a Merging Template

Submit a merge template to the unauthenticated merge-syntax endpoint.
This mirrors the CatMapperJS *Generate Merge Files* action on the merge
template page and does not require an API key.

## Usage

``` r
createMergeSyntax(template, database, url = NULL)
```

## Arguments

- template:

  Merge-template rows as a data frame or list of row objects.

- database:

  Target database, typically `"SocioMap"` or `"ArchaMap"`.

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set.

## Value

Parsed API response. On success this typically contains a message and a
`download` object with a downloadable hash.

## Examples

``` r
if (FALSE) { # \dontrun{
template <- data.frame(
  mergingID = "AMM1",
  datasetID = "AD1",
  filePath = "/mnt/storage/app/example.csv",
  stringsAsFactors = FALSE
)

result <- createMergeSyntax(template = template, database = "ArchaMap")
result$download
} # }
```
