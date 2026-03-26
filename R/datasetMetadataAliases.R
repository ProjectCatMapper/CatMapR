#' List Dataset Catalog Metadata
#'
#' Preferred metadata-focused alias for [allDatasets()].
#' This function returns dataset catalog metadata records, not raw dataset files.
#'
#' @inheritParams allDatasets
#'
#' @return A list containing metadata records for each dataset, or an error
#'   message if the request fails.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' listDatasetMetadata(database = "SocioMap")
#' listDatasetMetadata(database = "ArchaMap")
#' }
listDatasetMetadata <- function(database) {
  allDatasets(database = database)
}

#' Get Dataset Metadata by CMID
#'
#' Preferred metadata-focused alias for [datasetInfo()].
#' This function returns dataset metadata records, not raw dataset files.
#' Returned `Key` values can be stored-form keys (for example prefixed with
#' `Key == `) and may need normalization before reuse in upload workflows.
#'
#' @inheritParams datasetInfo
#'
#' @return A list containing dataset metadata details, or an error message if
#'   the request fails.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' getDatasetMetadata(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
#' getDatasetMetadata(database = "ArchaMap", CMID = "AD1")
#' }
getDatasetMetadata <- function(database, CMID, domain = "CATEGORY", children = NULL) {
  datasetInfo(
    database = database,
    CMID = CMID,
    domain = domain,
    children = children
  )
}
