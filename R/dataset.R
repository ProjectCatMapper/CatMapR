#' Retrieve Dataset Metadata by CMID
#'
#' This function retrieves dataset metadata based on a given CMID (CatMapperID)
#' from a specified database, with an optional domain filter.
#' It fetches dataset relationships and metadata properties associated with the
#' specified CMID.
#'
#' @param database A string specifying the database to search in. Valid options are "SocioMap" or "ArchaMap".
#' @param CMID The CMID of the dataset to retrieve information for (e.g., "SD1" or "AD1").
#' @param domain (Optional) A category to filter dataset relationships. Defaults to "CATEGORY" if not specified.
#' @param children (Optional) If TRUE, include child datasets in the query.
#'
#' @return A list containing dataset metadata details, or an error message if the
#' request fails. This function returns metadata records, not raw dataset files.
#'
#' @export
#' @examples
#' \dontrun{
#' datasetInfo(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
#' datasetInfo(database = "ArchaMap", CMID = "AD1")
#' }
datasetInfo <- function(database, CMID, domain = "CATEGORY", children = NULL) {
  database <- validate_database(database)
  CMID <- validate_scalar_character(CMID, "CMID")
  domain <- validate_scalar_character(domain, "domain")
  children <- validate_optional_scalar_logical(children, "children")

  # Define the endpoint and parameters
  endpoint <- "dataset"
  parameters <- list(database = database, cmid = CMID, domain = domain, children = children)

  # Call the API using the callAPI function
  response <- callAPI(endpoint = endpoint, parameters = parameters, request = "GET")

  # Return the response
  return(response)
}
