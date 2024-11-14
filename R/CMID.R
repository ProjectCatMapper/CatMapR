#' Retrieve Details for a Specific CMID (CatMapperID)
#'
#' This function retrieves detailed information about a specified CatMapperID (CMID) from a specified database.
#' It fetches both node properties and their relationships associated with the given CMID.
#'
#' @param database A string specifying the database to search in. Valid options are "SocioMap" or "ArchaMap".
#' @param cmid The CatMapperID for which details are to be retrieved (e.g., "SM1" or "AM1").
#'
#' @return A list containing node properties and relationships associated with the specified CMID, or an error message if the request fails.
#'
#' @export
#' @examples
#' CMIDinfo(database = "SocioMap", cmid = "SM1")
#' CMIDinfo(database = "ArchaMap", cmid = "AM1")
CMIDinfo <- function(database, cmid) {

  # Define the endpoint and parameters
  endpoint <- "CMID"
  parameters <- list(database = database, cmid = cmid)

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = parameters, request = "GET")

  # Return the response
  return(response)
}
