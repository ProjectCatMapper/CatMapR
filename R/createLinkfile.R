#' Create Linkfile from Dataset CMIDs
#'
#' This function propose a merge based on a category domain and selected datasets.
#' It then processes the response and returns a list of dictionaries containing proposed merge information.
#'
#' @param categoryLabel Character string specifying the category domain for the merge.
#' @param datasetChoices Character vector or comma-separated string of dataset CMIDs.
#' @param database Character string specifying the database to use. (default: "SocioMap" -- "ArchaMap" is the other option)
#' @param intersection Boolean value specifying whether to return the intersection of the datasets or all categories. (default: FALSE)
#' @param equivalence Merge mode, either "standard" or "extended".
#' @param mergelevel Number of CONTAINS hops to use when \code{equivalence = "extended"}.
#' @param resultFormat Output format expected by the API ("key-to-key", "key-to-category", or "category-to-category").
#' @param selectedKeyvariable Named list of key prefixes used for filtering in extended mode.
#'
#' @return Dataframe containing proposed merge information.
#'   - datasetID: Character string representing the dataset ID.
#'   - Key: Character string representing a unique identifier for the merge.
#'   - CMName: Character string representing the category name.
#'   - CMID: Character string representing the category ID.
#'   - Name: Character string representing a semicolon-separated list of dataset names.
#'
#' @export
#'
#' @examples
#'
#' \dontrun{
#' categoryLabel <- c("ETHNICITY")
#' datasetChoices <- c("SD5", "SD6")
#' merged_data <- createLinkfile(categoryLabel, datasetChoices, equivalence = "standard")
#' }
#'
createLinkfile <- function(categoryLabel,
                           datasetChoices,
                           database = "SocioMap",
                           intersection = FALSE,
                           equivalence = "standard",
                           mergelevel = 2,
                           resultFormat = "key-to-key",
                           selectedKeyvariable = list()) {
  database <- validate_database(database)
  equivalence <- validate_choice(equivalence, c("standard", "extended"), "equivalence")
  resultFormat <- validate_choice(
    resultFormat,
    c("key-to-key", "key-to-category", "category-to-category"),
    "resultFormat"
  )
  mergelevel <- validate_positive_integer(mergelevel, "mergelevel")
  intersection <- validate_scalar_logical(intersection, "intersection")

  if (length(datasetChoices) > 1) {
    datasetChoices <- paste(datasetChoices, collapse = ",")
  }
  datasetChoices <- validate_scalar_character(datasetChoices, "datasetChoices")

  if (length(categoryLabel) > 1) {
    categoryLabel <- categoryLabel[1]
  }
  categoryLabel <- validate_scalar_character(categoryLabel, "categoryLabel")

  # Prepare parameters for the API call
  params <- list(
    database = database,
    datasetChoices = datasetChoices,
    categoryLabel = categoryLabel,
    intersection = intersection,
    mergelevel = mergelevel,
    equivalence = equivalence,
    resultFormat = resultFormat,
    selectedKeyvariable = selectedKeyvariable
  )

  # Call the API using the callAPI function
  response <- callAPI(endpoint = "proposeMergeSubmit", parameters = params, request = "POST")

  return(response)
}
