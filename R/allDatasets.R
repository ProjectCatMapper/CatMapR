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
#' list_datasets(database = "SocioMap")
#' list_datasets(database = "ArchaMap")
#' }
list_datasets <- function(database) {
  database <- validate_database(database)

  # Define the endpoint and parameters
  endpoint <- "allDatasets"
  parameters <- list(database = database)

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = parameters, request = "GET")

  # Return the response
  return(response)
}

allDatasets <- function(database) {
  list_datasets(database = database)
}
