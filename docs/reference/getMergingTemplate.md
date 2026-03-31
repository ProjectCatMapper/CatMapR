# Retrieve a Merging Template for a Dataset

Fetch the merge-template rows associated with a dataset. This mirrors
the unauthenticated CatMapper API route used by the CatMapperJS
merge-template UI.

## Usage

``` r
getMergingTemplate(database, datasetID, url = NULL)
```

## Arguments

- database:

  Target database, typically `"SocioMap"` or `"ArchaMap"`.

- datasetID:

  Dataset CMID whose merge template should be retrieved.

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set.

## Value

Parsed API response, typically a data frame of merge-template rows.

## Examples

``` r
if (FALSE) { # \dontrun{
tmpl <- getMergingTemplate(database = "ArchaMap", datasetID = "AD947")
head(tmpl)
} # }
```
