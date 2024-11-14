#' Retrieve Dataset Information by CMID
#'
#' This function retrieves detailed information about a dataset based on a given CMID (CatMapperID) from a specified database, with an optional domain filter.
#' It fetches relationships and properties of datasets associated with the specified CMID.
#'
#' @param database A string specifying the database to search in. Valid options are "SocioMap" or "ArchaMap".
#' @param CMID The CMID of the dataset to retrieve information for (e.g., "SD1" or "AD1").
#' @param domain (Optional) A category to filter dataset relationships. Defaults to "CATEGORY" if not specified.
#'
#' @return A list containing detailed information about the dataset, or an error message if the request fails.
#'
#' @export
#' @examples
#' datasetInfo(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
#' datasetInfo(database = "ArchaMap", CMID = "AD1")
datasetInfo <- function(database, CMID, domain = "CATEGORY") {

  # Define the endpoint and parameters
  endpoint <- "dataset"
  parameters <- list(database = database, cmid = CMID, domain = domain)

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = parameters, request = "GET")

  # Return the response
  return(response)
}
