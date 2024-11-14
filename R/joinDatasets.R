#' Join Datasets by Key
#'
#' This function calls the CatMapper API to join two datasets based on specified parameters.
#' It retrieves translated keys from the database and returns the joined data with the CMID and CMName.
#' The function requires a column named 'datasetID' in both datasets that has the CMID of the translated dataset. It also requires the columns used to create the 'Key' used in translation. For example, if the Key for the GADM dataset 'SD1' is 'GID: AFG', then the 'Key' column should be 'GID' in the dataset.
#'
#' @param database A string specifying the database to use, either "SocioMap" or "ArchaMap".
#' @param autoLeft A data frame representing the left dataset with a "datasetID" column and other relevant columns.
#' @param autoRight A data frame representing the right dataset with a "datasetID" column and other relevant columns.
#'
#' @return A data frame containing the joined datasets or an error message if the request fails.
#' @export
#'
#' @examples
#' autoLeft = data.frame(datasetID = "SD1", country = "Afghanistan", GID = "AFG", val0 = 1)
#' autoRight = data.frame(datasetID = "SD2", country = "Afghanistan", geonameid = "1149361", val1 = 2)
#' joinDatasets("SocioMap", autoLeft, autoRight)
joinDatasets <- function(database, autoLeft, autoRight) {

  # Set up parameters for the API request
  parameters <- list(
    database = database,
    autoLeft = autoLeft,
    autoRight = autoRight
  )

  # Call the API using callAPI function
  response <- callAPI(endpoint = "joinDatasets", parameters = parameters, request = "POST")

  return(response)
}
