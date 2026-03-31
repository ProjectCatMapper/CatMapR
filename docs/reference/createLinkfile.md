# Create Linkfile from Dataset CMIDs

This function propose a merge based on a category domain and selected
datasets. It then processes the response and returns a list of
dictionaries containing proposed merge information.

## Usage

``` r
createLinkfile(
  categoryLabel,
  datasetChoices,
  database = "SocioMap",
  intersection = FALSE,
  equivalence = "standard",
  mergelevel = 2,
  resultFormat = "key-to-key",
  selectedKeyvariable = list()
)
```

## Arguments

- categoryLabel:

  Character string specifying the category domain for the merge.

- datasetChoices:

  Character vector or comma-separated string of dataset CMIDs.

- database:

  Character string specifying the database to use. (default: "SocioMap"
  – "ArchaMap" is the other option)

- intersection:

  Boolean value specifying whether to return the intersection of the
  datasets or all categories. (default: FALSE)

- equivalence:

  Merge mode, either "standard" or "extended".

- mergelevel:

  Number of CONTAINS hops to use when `equivalence = "extended"`.

- resultFormat:

  Output format expected by the API ("key-to-key", "key-to-category", or
  "category-to-category").

- selectedKeyvariable:

  Named list of key prefixes used for filtering in extended mode.

## Value

Dataframe containing proposed merge information.

- datasetID: Character string representing the dataset ID.

- Key: Character string representing a unique identifier for the merge.

- CMName: Character string representing the category name.

- CMID: Character string representing the category ID.

- Name: Character string representing a semicolon-separated list of
  dataset names.

## Examples

``` r
if (FALSE) { # \dontrun{
categoryLabel <- c("ETHNICITY")
datasetChoices <- c("SD5", "SD6")
merged_data <- createLinkfile(categoryLabel, datasetChoices, equivalence = "standard")
} # }
```
