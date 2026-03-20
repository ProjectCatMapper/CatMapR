#' Retrieve Dataset Catalog Metadata from a Specified Database
#'
#' This function retrieves dataset catalog metadata from a specified database.
#' It returns information such as dataset identifiers, names, applicable years,
#' project details, and related metadata fields.
#'
#' @param database A string specifying the database from which to retrieve datasets. Valid options are "SocioMap" or "ArchaMap".
#'
#' @return A list containing metadata records for each dataset, or an error message if the request fails.
#' The list typically includes fields such as nodeID, CMName, CMID, shortName,
#' project, Unit, parent, ApplicableYears, and more. This function returns
#' metadata records, not raw dataset files.
#'
#' @export
#' @examples
#' \dontrun{
#' allDatasets(database = "SocioMap")
#' allDatasets(database = "ArchaMap")
#' }
allDatasets <- function(database) {
  database <- validate_database(database)

  # Define the endpoint and parameters
  endpoint <- "allDatasets"
  parameters <- list(database = database)

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = parameters, request = "GET")

  # Return the response
  return(response)
}
