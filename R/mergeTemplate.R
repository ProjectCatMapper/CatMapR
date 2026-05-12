#' Retrieve a Merging Template for a Dataset
#'
#' Fetch the merge-template rows associated with a dataset. This mirrors the
#' unauthenticated CatMapper API route used by the CatMapperJS merge-template
#' UI.
#'
#' @param database Target database, typically \code{"SocioMap"} or
#'   \code{"ArchaMap"}.
#' @param dataset_id Dataset CMID whose merge template should be retrieved.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used
#'   when set.
#'
#' @return Parsed API response, typically a data frame of merge-template rows.
#' @export
#'
#' @examples
#' \dontrun{
#' tmpl <- get_merge_template(database = "ArchaMap", dataset_id = "AD947")
#' head(tmpl)
#' }
get_merge_template <- function(database, dataset_id, url = NULL) {
  database <- validate_database(database)
  dataset_id <- validate_scalar_character(dataset_id, "dataset_id")

  endpoint <- paste("merge", "template", database, dataset_id, sep = "/")
  callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)
}

#' Retrieve a Merge-Template Summary for a MERGING or STACK Node
#'
#' Fetch the summary payload used by the CatMapperJS \emph{Merging Template} tab
#' on node pages for \code{MERGING} and \code{STACK} nodes. The response
#' includes summary tables plus downloadable \code{mergingTies} and
#' \code{categoryMergingTies} arrays.
#'
#' @param database Target database, typically \code{"SocioMap"} or
#'   \code{"ArchaMap"}.
#' @param cmid CMID of the \code{MERGING} or \code{STACK} node.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used
#'   when set.
#'
#' @return Parsed API response, typically a list with fields such as
#'   \code{nodeType}, \code{stackSummary}, \code{datasetSummary},
#'   \code{mergingTies}, and \code{categoryMergingTies}.
#' @export
#'
#' @examples
#' \dontrun{
#' summary <- get_merge_template_summary(database = "ArchaMap", cmid = "AMM1")
#' summary$nodeType
#' summary$mergingTies
#' }
get_merge_template_summary <- function(database, cmid, url = NULL) {
  database <- validate_database(database)
  cmid <- validate_scalar_character(cmid, "cmid")

  endpoint <- paste("merge", "template", "summary", database, cmid, sep = "/")
  callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)
}

#' Generate Merge Syntax Files from a Merging Template
#'
#' Submit a merge template to the unauthenticated merge-syntax endpoint. This
#' mirrors the CatMapperJS \emph{Generate Merge Files} action on the merge
#' template page and does not require an API key.
#'
#' @param template Merge-template rows as a data frame or list of row objects.
#' @param database Target database, typically \code{"SocioMap"} or
#'   \code{"ArchaMap"}.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used
#'   when set.
#'
#' @return Parsed API response. On success this typically contains a message and
#'   a \code{download} object with a downloadable hash.
#' @export
#'
#' @examples
#' \dontrun{
#' template <- data.frame(
#'   mergingID = "AMM1",
#'   datasetID = "AD1",
#'   filePath = "/mnt/storage/app/example.csv",
#'   stringsAsFactors = FALSE
#' )
#'
#' result <- build_merge_syntax(template = template, database = "ArchaMap")
#' result$download
#' }
build_merge_syntax <- function(template, database, url = NULL) {
  database <- validate_database(database)
  if (!is.data.frame(template) && !is.list(template)) {
    stop("`template` must be a data frame or a list of row objects.", call. = FALSE)
  }

  template_rows <- if (is.data.frame(template)) {
    coerce_upload_rows(template)
  } else {
    template
  }

  endpoint <- paste("merge", "syntax", database, sep = "/")
  callAPI(
    endpoint = endpoint,
    parameters = list(template = template_rows),
    request = "POST",
    url = url
  )
}
