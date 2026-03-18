#' Join Datasets by Key
#'
#' This function calls the CatMapper API to join two datasets based on specified parameters.
#' It retrieves translated keys from the database and returns the joined data with the CMID and CMName.
#' The function requires a column named 'datasetID' in both datasets that has the CMID of the translated dataset. It also requires the columns used to create the 'Key' used in translation. For example, if the Key for the GADM dataset 'SD1' is 'GID: AFG', then the 'Key' column should be 'GID' in the dataset.
#'
#' @param database A string specifying the database to use, either "SocioMap" or "ArchaMap".
#' @param joinLeft A data frame representing the left dataset with a "datasetID" column and other relevant columns.
#' @param joinRight A data frame representing the right dataset with a "datasetID" column and other relevant columns.
#' @param domain Category domain label to use for joining keys (default: "CATEGORY").
#'
#' @return A data frame containing the joined datasets or an error message if the request fails.
#' @export
#'
#' @examples
#' \dontrun{
#' joinLeft = data.frame(datasetID = "SD1", country = "Afghanistan", GID = "AFG", val0 = 1)
#' joinRight = data.frame(datasetID = "SD2", country = "Afghanistan", geonameid = "1149361", val1 = 2)
#' joinDatasets("SocioMap", joinLeft, joinRight, domain = "CATEGORY")
#' }
joinDatasets <- function(database, joinLeft, joinRight, domain = "CATEGORY") {
  database <- validate_database(database)
  domain <- validate_scalar_character(domain, "domain")
  if (!is.data.frame(joinLeft)) {
    stop("`joinLeft` must be a data frame.", call. = FALSE)
  }
  if (!is.data.frame(joinRight)) {
    stop("`joinRight` must be a data frame.", call. = FALSE)
  }

  # Set up parameters for the API request
  parameters <- list(
    database = database,
    joinLeft = joinLeft,
    joinRight = joinRight,
    domain = domain
  )

  # Call the API using callAPI function
  response <- callAPI(endpoint = "joinDatasets", parameters = parameters, request = "POST")

  return(response)
}
