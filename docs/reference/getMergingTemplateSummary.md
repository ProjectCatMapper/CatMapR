# Retrieve a Merge-Template Summary for a MERGING or STACK Node

Fetch the summary payload used by the CatMapperJS *Merging Template* tab
on node pages for `MERGING` and `STACK` nodes. The response includes
summary tables plus downloadable `mergingTies` and `equivalenceTies`
arrays.

## Usage

``` r
getMergingTemplateSummary(database, cmid, url = NULL)
```

## Arguments

- database:

  Target database, typically `"SocioMap"` or `"ArchaMap"`.

- cmid:

  CMID of the `MERGING` or `STACK` node.

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set.

## Value

Parsed API response, typically a list with fields such as `nodeType`,
`stackSummary`, `datasetSummary`, `mergingTies`, and `equivalenceTies`.

## Examples

``` r
if (FALSE) { # \dontrun{
summary <- getMergingTemplateSummary(database = "ArchaMap", cmid = "AMM1")
summary$nodeType
summary$mergingTies
} # }
```
