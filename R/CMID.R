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
#' \dontrun{
#' CMIDinfo(database = "SocioMap", cmid = "SM1")
#' CMIDinfo(database = "ArchaMap", cmid = "AM1")
#' }
CMIDinfo <- function(database, cmid) {
  database <- validate_database(database)
  cmid <- validate_scalar_character(cmid, "cmid")

  # New REST format: /CMID/<database>/<cmid>
  endpoint <- paste("CMID", database, cmid, sep = "/")

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET")

  # Return the response
  return(response)
}
