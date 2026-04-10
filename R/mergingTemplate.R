#' Retrieve a Downloadable Merging Template
#'
#' This function retrieves the downloadable merging template rows for a
#' CatMapper merging template or related CMID.
#'
#' @param cmid A merging-template-related CMID accepted by the API route.
#' @param database A string specifying the database from which to retrieve the
#'   template. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
#'   otherwise `"https://api.catmapper.org"`.
#'
#' @return A data frame with one row per template entry, including the
#'   instructional working-directory row.
#'
#' @export
#' @examples
#' \dontrun{
#' getMergingTemplate(cmid = "AD354277", database = "ArchaMap")
#' }
getMergingTemplate <- function(cmid, database = "SocioMap", url = NULL) {
  database <- validate_database(database)
  cmid <- validate_scalar_character(cmid, "cmid")

  endpoint <- paste0("merge/template/", tolower(database), "/", cmid)
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  normalize_merging_template_response(response)
}

#' Retrieve a Merging Template Summary
#'
#' This function retrieves a structured summary for a MERGING or STACK node,
#' including stack summaries, dataset summaries, merge ties, and equivalence
#' ties.
#'
#' @param cmid A MERGING or STACK CMID.
#' @param database A string specifying the database from which to retrieve the
#'   summary. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
#'   otherwise `"https://api.catmapper.org"`.
#'
#' @return A list with normalized `stackSummary`, `datasetSummary`,
#'   `mergingTies`, and `equivalenceTies` data frames plus scalar summary
#'   fields returned by the API.
#'
#' @export
#' @examples
#' \dontrun{
#' getMergingTemplateSummary(cmid = "AD354277", database = "ArchaMap")
#' }
getMergingTemplateSummary <- function(cmid, database = "SocioMap", url = NULL) {
  database <- validate_database(database)
  cmid <- validate_scalar_character(cmid, "cmid")

  endpoint <- paste0("merge/template/summary/", tolower(database), "/", cmid)
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  normalize_merging_template_summary_response(response)
}

normalize_merging_template_response <- function(response) {
  required_cols <- c(
    "mergingID",
    "mergingCMName",
    "mergingShortName",
    "mergingCitation",
    "stackID",
    "datasetID",
    "datasetName",
    "filePath"
  )

  normalize_section_df(response, required_cols)
}

normalize_merging_template_summary_response <- function(response) {
  if (is.null(response)) {
    response <- list()
  }

  list(
    nodeType = if (!is.null(response$nodeType)) as.character(response$nodeType[[1]]) else NA_character_,
    stackSummary = normalize_section_df(
      response$stackSummary,
      c("stackID", "stackCMName", "datasetCount", "equivalenceTieCount", "keyReassignmentCount", "variableCount")
    ),
    stackSummaryTotals = normalize_named_list(
      response$stackSummaryTotals,
      c("datasetCount", "equivalenceTieCount", "keyReassignmentCount", "variableCount")
    ),
    datasetSummary = normalize_section_df(
      response$datasetSummary,
      c("datasetID", "datasetCMName", "equivalenceTieCount", "keyReassignmentCount", "variableCount")
    ),
    mergingTemplateCount = if (!is.null(response$mergingTemplateCount)) response$mergingTemplateCount[[1]] else 0,
    mergingTies = normalize_section_df(
      response$mergingTies,
      c(
        "mergingID",
        "mergingCMName",
        "stackID",
        "stackCMName",
        "relationship",
        "targetLabels",
        "targetCMID",
        "targetCMName",
        "tieStackID",
        "varName",
        "stackTransform",
        "datasetTransform",
        "variableFilter",
        "summaryStatistic",
        "summaryFilter",
        "summaryWeight"
      )
    ),
    equivalenceTies = normalize_section_df(
      response$equivalenceTies,
      c("stackID", "datasetID", "Key", "originalCMID", "originalCMName", "equivalentCMID", "equivalentCMName", "selfReference")
    )
  )
}

normalize_section_df <- function(x, required_cols) {
  if (is.null(x)) {
    out <- data.frame(stringsAsFactors = FALSE)
  } else if (is.data.frame(x)) {
    out <- x
  } else if (is.list(x) && length(x) == 0) {
    out <- data.frame(stringsAsFactors = FALSE)
  } else if (is.list(x) && length(x) > 0 && all(vapply(x, is.list, logical(1)))) {
    row_names <- unique(unlist(lapply(x, names), use.names = FALSE))
    out_cols <- lapply(row_names, function(name) {
      values <- lapply(x, function(row) row[[name]])
      values[sapply(values, is.null)] <- NA
      unlist(values, use.names = FALSE)
    })
    names(out_cols) <- row_names
    out <- as.data.frame(out_cols, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (is.list(x) && !is.null(names(x))) {
    out <- as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    out <- as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
  }

  missing_cols <- setdiff(required_cols, names(out))
  for (col in missing_cols) {
    out[[col]] <- rep(NA_character_, nrow(out))
  }

  out[, c(required_cols, setdiff(names(out), required_cols)), drop = FALSE]
}

normalize_named_list <- function(x, required_names) {
  out <- setNames(as.list(rep(NA, length(required_names))), required_names)

  if (is.null(x)) {
    return(out)
  }

  if (!is.list(x)) {
    x <- as.list(x)
  }

  for (name in intersect(required_names, names(x))) {
    value <- x[[name]]
    out[[name]] <- if (length(value) == 0) NA else value[[1]]
  }

  out
}
