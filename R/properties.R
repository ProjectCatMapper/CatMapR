#' Retrieve Property Metadata from a Specified Database
#'
#' This function retrieves flattened CatMapper property metadata from the
#' canonical CatMapper API endpoint for a specified database. The result is a
#' data frame with one row per property-field/value pair from `PROPERTY` nodes.
#'
#' @param database A string specifying the database from which to retrieve property metadata. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set, otherwise `"https://api.catmapper.org"`.
#'
#' @return A data frame containing flattened property metadata. Typical columns
#' include `nodeID`, `CMName`, `property`, and `value`.
#'
#' @export
#' @examples
#' \dontrun{
#' getProperties(database = "SocioMap")
#' getProperties(database = "ArchaMap")
#' }
getProperties <- function(database = "SocioMap", url = NULL) {
  database <- validate_database(database)

  endpoint <- paste0("metadata/properties/", tolower(database))
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  normalize_property_table_response(response)
}

#' Retrieve Upload Property Metadata from a Specified Database
#'
#' This function retrieves upload-oriented CatMapper property metadata for a
#' specified database. The API groups results into node properties and USES
#' relationship properties.
#'
#' @param database A string specifying the database from which to retrieve upload property metadata. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set, otherwise `"https://api.catmapper.org"`.
#'
#' @return A list with three elements:
#' \describe{
#'   \item{database}{Database name returned by the API.}
#'   \item{nodeProperties}{A data frame of node property metadata.}
#'   \item{usesProperties}{A data frame of USES relationship property metadata.}
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' getUploadProperties(database = "SocioMap")
#' getUploadProperties(database = "ArchaMap")
#' }
getUploadProperties <- function(database = "SocioMap", url = NULL) {
  database <- validate_database(database)

  endpoint <- paste0("metadata/uploadProperties/", tolower(database))
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  database_value <- response$database
  if (is.null(database_value) || length(database_value) == 0 || is.na(database_value[[1]])) {
    database_value <- database
  }

  list(
    database = as.character(database_value[[1]]),
    nodeProperties = normalize_property_collection(response$nodeProperties),
    usesProperties = normalize_property_collection(response$usesProperties)
  )
}

normalize_property_table_response <- function(response) {
  empty_table <- data.frame(
    nodeID = character(0),
    CMName = character(0),
    property = character(0),
    value = character(0),
    stringsAsFactors = FALSE
  )

  if (is.null(response)) {
    return(empty_table)
  }

  rows <- response
  if (is.list(response) && !is.data.frame(response) && !is.null(response$table)) {
    rows <- response$table
  }

  if (is.null(rows) || (is.list(rows) && length(rows) == 0)) {
    return(empty_table)
  }

  if (is.data.frame(rows)) {
    out <- rows
  } else if (is.list(rows) && length(rows) > 0 && all(vapply(rows, is.list, logical(1)))) {
    row_names <- unique(unlist(lapply(rows, names), use.names = FALSE))
    out_cols <- lapply(row_names, function(name) {
      values <- lapply(rows, function(row) row[[name]])
      values[sapply(values, is.null)] <- NA
      unlist(values, use.names = FALSE)
    })
    names(out_cols) <- row_names
    out <- as.data.frame(out_cols, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (is.list(rows) && !is.null(names(rows))) {
    out <- as.data.frame(rows, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    out <- as.data.frame(rows, stringsAsFactors = FALSE, check.names = FALSE)
  }

  required_cols <- c("nodeID", "CMName", "property", "value")
  missing_cols <- setdiff(required_cols, names(out))
  for (col in missing_cols) {
    out[[col]] <- NA_character_
  }

  out[, c(required_cols, setdiff(names(out), required_cols)), drop = FALSE]
}

normalize_property_collection <- function(x) {
  if (is.null(x)) {
    return(data.frame(
      property = character(0),
      description = character(0),
      stringsAsFactors = FALSE
    ))
  }

  if (is.data.frame(x)) {
    out <- x
  } else if (is.list(x) && length(x) == 0) {
    out <- data.frame(
      property = character(0),
      description = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    out <- as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
  }

  required_cols <- c("property", "description")
  missing_cols <- setdiff(required_cols, names(out))
  for (col in missing_cols) {
    out[[col]] <- NA_character_
  }

  out[, c(required_cols, setdiff(names(out), required_cols)), drop = FALSE]
}
