#' Retrieve All Datasets from a Specified Database
#'
#' This function retrieves detailed information about all datasets from a specified database.
#' It returns information such as dataset identifiers, names, applicable years, project details, and other relevant metadata.
#'
#' @param database A string specifying the database from which to retrieve datasets. Valid options are "SocioMap" or "ArchaMap".
#'
#' @return A list containing detailed information about each dataset, or an error message if the request fails.
#' The list includes fields such as nodeID, CMName, CMID, shortName, project, Unit, parent, ApplicableYears, and more.
#'
#' @export
#' @examples
#' allDatasets(database = "SocioMap")
#' allDatasets(database = "ArchaMap")
allDatasets <- function(database) {

  # Define the endpoint and parameters
  endpoint <- "allDatasets"
  parameters <- list(database = database)

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = parameters, request = "GET")

  # Return the response
  return(response)
}
