#' Create Linkfile from Dataset CMIDs
#'
#' This function propose a merge based on a category domain and selected datasets.
#' It then processes the response and returns a list of dictionaries containing proposed merge information.
#'
#' @param categoryLabel Character vector specifying the category domain for the merge.
#' @param datasetChoices Character vector of CMIDs representing the selected datasets.
#' @param database Character string specifying the database to use. (default: "SocioMap" -- "ArchaMap" is the other option)
#' @param intersection Boolean value specifying whether to return the intersection of the datasets or all categories. (default: FALSE)
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
#' categoryLabel <- c("ETHNICITY")
#' datasetChoices <- c("SD5", "SD6")
#' merged_data <- createLinkfile(categoryLabel, datasetChoices)
#'
createLinkfile <- function(categoryLabel, datasetChoices, database = "SocioMap", intersection = FALSE) {
  # Prepare parameters for the API call
  params <- list(
    database = database,
    datasetChoices = datasetChoices,
    categoryLabel = categoryLabel,
    intersection = intersection
  )

  # Call the API using the callAPI function
  response <- callAPI(endpoint = "proposeMergeSubmit", parameters = params, request = "POST")

  return(response)
}
