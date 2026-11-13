#' Preflight a Polygon GeoJSON Upload
#'
#' Validate the complete file and its existing USES targets without graph writes.
#' Requires an administrator API key. Each Feature must have string properties
#' `CMID`, `Key`, and `datasetID`. Only valid, nonempty Polygon/MultiPolygon
#' geometry in WGS84 longitude/latitude is accepted. The server checks topology,
#' target identity, ownership, and configured limits.
#'
#' @param file Path to an existing `.geojson` or `.json` FeatureCollection.
#' @param database Target database: `"SocioMap"` or `"ArchaMap"`.
#' @param replace_existing Explicitly permit replacement of existing polygon
#'   references. Defaults to `FALSE`.
#' @param api_key Administrator API key; defaults to `CATMAPR_API_KEY`.
#' @param url API base URL override; defaults to `CATMAPR_API_URL` or production.
#' @return Server validation report with counts, warnings, digest, and token.
#' @examples
#' \dontrun{
#' report <- preflight_polygon_upload("polygons.geojson", "SocioMap")
#' # Inspect report before applying.
#' task <- apply_polygon_upload(report$token)
#' result <- waitForUploadTask(task$taskId)
#' }
#' @export
preflight_polygon_upload <- function(file, database, replace_existing = FALSE,
                                     api_key = NULL, url = NULL) {
  database <- tolower(validate_database(database))
  replace_existing <- validate_scalar_logical(replace_existing, "replace_existing")
  file <- validate_scalar_character(file, "file")
  if (!file.exists(file) || dir.exists(file) || !grepl("\\.(geojson|json)$", file, ignore.case = TRUE)) {
    stop("`file` must be an existing .geojson or .json file.", call. = FALSE)
  }
  callAPI("api/uploads/geojson/polygons/preflight",
          list(database = database, replaceExisting = tolower(as.character(replace_existing)),
               file = httr::upload_file(file, type = "application/geo+json")),
          request = "POST", url = url, encode = "multipart",
          headers = list("X-API-Key" = resolve_api_key(api_key)))
}

validate_polygon_token <- function(token) {
  token <- validate_scalar_character(token, "token")
  if (!grepl("^[a-f0-9]{32}$", token)) {
    stop("`token` must be the 32-character token returned by polygon preflight.", call. = FALSE)
  }
  token
}

#' Apply a Preflighted Polygon Upload
#'
#' Revalidate and queue the file. Tokens are single-use, belong to the
#' preflighting user, and expire (one hour by default). Apply requests are not
#' automatically retried. Use `waitForUploadTask()` to observe completion.
#'
#' @param token Token returned by `preflight_polygon_upload()`.
#' @inheritParams preflight_polygon_upload
#' @return Queued task response including `taskId`.
#' @export
apply_polygon_upload <- function(token, api_key = NULL, url = NULL) {
  token <- validate_polygon_token(token)
  callAPI(paste0("api/uploads/geojson/polygons/", token, "/apply"),
          list(), request = "POST", url = url,
          headers = list("X-API-Key" = resolve_api_key(api_key)))
}

#' Discard an Unused Polygon Preflight
#'
#' Deletes the token and staged file. This does not undo an applied upload.
#'
#' @inheritParams apply_polygon_upload
#' @return Server discard confirmation.
#' @export
discard_polygon_upload <- function(token, api_key = NULL, url = NULL) {
  token <- validate_polygon_token(token)
  callAPI(paste0("api/uploads/geojson/polygons/", token),
          list(), request = "DELETE", url = url,
          headers = list("X-API-Key" = resolve_api_key(api_key)))
}

#' Request Upload Task Cancellation
#'
#' Supports tabular and polygon upload tasks owned by the authenticated user.
#' Cancellation is cooperative; a task may finish before it takes effect.
#' Continue polling with `uploadInputNodesStatus()` for the final status.
#'
#' @param task_id Upload task identifier.
#' @param cursor Non-negative integer event cursor.
#' @inheritParams preflight_polygon_upload
#' @return Server cancellation response and task status.
#' @export
cancel_upload_task <- function(task_id, cursor = 0L, api_key = NULL, url = NULL) {
  task_id <- validate_scalar_character(task_id, "task_id")
  if (length(cursor) != 1 || !is.numeric(cursor) || !is.finite(cursor) || cursor < 0 || cursor %% 1 != 0) {
    stop("`cursor` must be a non-negative integer.", call. = FALSE)
  }
  callAPI("api/uploads/input-nodes/cancel", list(taskId = task_id, cursor = cursor),
          request = "POST", url = url,
          headers = list("X-API-Key" = resolve_api_key(api_key)))
}

#' Retrieve Direct Geometry
#'
#' Returns direct point/polygon rows with server-selected polygon simplifications.
#' Polygon row geometry may be JSON-encoded text. Use `explore_geometry()` for
#' processed map features and source information. No GIS package is required.
#'
#' @param cmid Category or dataset CMID.
#' @inheritParams preflight_polygon_upload
#' @return Server payload containing `polygons` and `points`.
#' @export
get_geometry <- function(database, cmid, url = NULL) {
  callAPI("api/geometry", list(database = tolower(validate_database(database)),
                              cmid = validate_scalar_character(cmid, "cmid")), url = url)
}

#' Retrieve Explore Map Geometry
#'
#' Retains the server's processed geometry, sources, and truncation metadata.
#' Omitted options use server defaults. Limits are requests subject to server
#' caps and behavior. No GIS package is required.
#'
#' @inheritParams get_geometry
#' @param layers Optional character vector or comma-separated layer names.
#' @param relations Optional character vector or comma-separated relationships.
#' @param max_depth Optional positive integer traversal depth.
#' @param node_limit Optional positive integer node limit.
#' @param point_limit Optional positive integer point limit.
#' @param polygon_limit Optional positive integer polygon limit.
#' @param feature_limit Optional positive integer feature limit.
#' @return Server map payload, including feature sources and any truncation.
#' @export
explore_geometry <- function(database, cmid, layers = NULL, relations = NULL,
                             max_depth = NULL, node_limit = NULL, point_limit = NULL,
                             polygon_limit = NULL, feature_limit = NULL, url = NULL) {
  database <- tolower(validate_database(database))
  cmid <- utils::URLencode(validate_scalar_character(cmid, "cmid"), reserved = TRUE)
  parameters <- list()
  for (name in c("layers", "relations")) {
    value <- if (name == "layers") layers else relations
    if (!is.null(value)) {
      if (!is.character(value) || !length(value) || anyNA(value) || any(!nzchar(value))) {
        stop(sprintf("`%s` must contain non-empty strings.", name), call. = FALSE)
      }
      parameters[[name]] <- paste(value, collapse = ",")
    }
  }
  limits <- list(maxDepth = max_depth, nodeLimit = node_limit, pointLimit = point_limit,
                 polygonLimit = polygon_limit, featureLimit = feature_limit)
  for (name in names(limits)) {
    if (!is.null(limits[[name]])) {
      parameters[[name]] <- validate_positive_integer(limits[[name]], name)
    }
  }
  callAPI(paste0("api/databases/", database, "/nodes/", cmid, "/explore-geometry"),
          parameters, url = url)
}

#' Retrieve Contextual Relationship Policy
#'
#' Fetch the current metadata-driven policy from the server.
#'
#' @inheritParams preflight_polygon_upload
#' @return Server policy, including whether policy validation is enabled.
#' @export
get_contextual_policy <- function(database = "SocioMap", url = NULL) {
  callAPI(paste0("api/databases/", tolower(validate_database(database)),
                 "/metadata/contextual-policy"), list(), url = url)
}

#' Validate Proposed Contextual Assertion Rows
#'
#' Read-only contextual policy validation of at most 1,000 rows. This checks
#' contextual policy only; upload endpoints still check other requirements and
#' mutable preconditions. Rows are sent together so projected domain changes can
#' be checked as a group.
#'
#' @param rows Data frame or list of named row objects, using server property
#'   names such as `CMID`, `label`, `country`, and `parent`.
#' @inheritParams preflight_polygon_upload
#' @return Server validation result with `valid` and `writes` fields; invalid
#'   requests raise a `catmapr_api_error` retaining the server response.
#' @export
validate_contextual_rows <- function(rows, database, url = NULL) {
  database <- tolower(validate_database(database))
  rows <- coerce_upload_rows(rows)
  if (length(rows) > 1000 || any(!vapply(rows, function(row) {
    is.list(row) && length(row) > 0 && !is.null(names(row)) && all(nzchar(names(row)))
  }, logical(1)))) {
    stop("Contextual validation requires at most 1000 named row objects.", call. = FALSE)
  }
  callAPI(paste0("api/databases/", database, "/metadata/contextual-policy/validate"),
          list(rows = rows), request = "POST", url = url)
}
