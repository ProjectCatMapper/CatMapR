#' Upload Edit-Page Rows to CatMapper
#'
#' Mirrors the CatMapperJS edit-page upload call to \code{/uploadInputNodes}.
#' This wrapper is intended for write operations and requires an API key.
#'
#' @param df Data frame or list of row objects to upload.
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param formData Named list matching the edit-page \code{formData} payload.
#' @param so Upload mode, usually \code{"standard"} or \code{"simple"}.
#' @param ao Advanced upload option, e.g. \code{"add_node"}, \code{"add_uses"}, \code{"update_add"}.
#' @param addoptions Named list with \code{district} and \code{recordyear} booleans.
#' @param user Optional CatMapper user id for attribution/logging.
#' @param allContext Optional vector/list of contextual columns.
#' @param mergingType Optional merging mode used by merge upload workflows.
#' @param api_key API key used for authenticated write actions. If \code{NULL}, \code{CATMAPR_API_KEY} is used.
#' @param api_user Optional API user id. If omitted, \code{user} or \code{CATMAPR_API_USER} is used when available.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed API response.
#' @export
#'
#' @examples
#' \dontrun{
#' uploadInputNodes(
#'   df = data.frame(CMName = "Yoruba", Name = "Yoruba", Key = "eth:yoruba", stringsAsFactors = FALSE),
#'   database = "SocioMap",
#'   formData = list(
#'     domain = "ETHNICITY",
#'     subdomain = "ETHNICITY",
#'     datasetID = "SD1",
#'     cmNameColumn = "CMName",
#'     categoryNamesColumn = "Name",
#'     alternateCategoryNamesColumns = character(0),
#'     cmidColumn = "CMID",
#'     keyColumn = "Key"
#'   ),
#'   so = "simple",
#'   ao = "add_uses",
#'   user = "your-userid",
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' }
uploadInputNodes <- function(df,
                             database,
                             formData = list(),
                             so = "standard",
                             ao = "add_node",
                             addoptions = list(district = FALSE, recordyear = FALSE),
                             user = NULL,
                             allContext = list(),
                             mergingType = "0",
                             api_key = NULL,
                             api_user = NULL,
                             url = NULL) {
  key <- resolve_api_key(api_key)
  resolved_user <- resolve_api_user(api_user = api_user, user = user)
  if (!is.list(formData)) {
    stop("`formData` must be a list.")
  }

  payload <- list(
    formData = formData,
    database = database,
    df = coerce_upload_rows(df),
    so = so,
    ao = ao,
    addoptions = normalize_addoptions(addoptions),
    user = user,
    allContext = allContext,
    mergingType = mergingType
  )

  if (!is.null(resolved_user) && nzchar(resolved_user)) {
    payload$cred <- list(userid = resolved_user, key = key)
  }

  headers <- build_api_key_headers(api_key = key, api_user = resolved_user)

  callAPI(
    endpoint = "uploadInputNodes",
    parameters = payload,
    request = "POST",
    url = url,
    headers = headers
  )
}

#' Refresh Waiting USES Queue
#'
#' Mirrors the post-upload CatMapperJS edit-page call to \code{/updateWaitingUSES}.
#' This wrapper is intended for write operations and requires an API key.
#'
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param user Optional CatMapper user id for attribution/logging.
#' @param api_key API key used for authenticated write actions. If \code{NULL}, \code{CATMAPR_API_KEY} is used.
#' @param api_user Optional API user id. If omitted, \code{user} or \code{CATMAPR_API_USER} is used when available.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed API response.
#' @export
#'
#' @examples
#' \dontrun{
#' updateWaitingUSES(
#'   database = "SocioMap",
#'   user = "your-userid",
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' }
updateWaitingUSES <- function(database,
                              user = NULL,
                              api_key = NULL,
                              api_user = NULL,
                              url = NULL) {
  key <- resolve_api_key(api_key)
  resolved_user <- resolve_api_user(api_user = api_user, user = user)
  payload <- list(database = database)
  if (!is.null(resolved_user) && nzchar(resolved_user)) {
    payload$cred <- list(userid = resolved_user, key = key)
  }

  headers <- build_api_key_headers(api_key = key, api_user = resolved_user)

  callAPI(
    endpoint = "updateWaitingUSES",
    parameters = payload,
    request = "POST",
    url = url,
    headers = headers
  )
}

#' Submit Edit Upload and Refresh Queue
#'
#' Convenience wrapper that executes the same two-step flow as the CatMapperJS
#' edit page: first \code{/uploadInputNodes}, then \code{/updateWaitingUSES}.
#'
#' @inheritParams uploadInputNodes
#' @param refresh_waiting_uses If \code{TRUE}, call \code{updateWaitingUSES} after upload.
#'
#' @return Named list with \code{upload} and \code{waiting_uses} elements.
#' @export
#'
#' @examples
#' \dontrun{
#' result <- submitEditUpload(
#'   df = data.frame(CMName = "Yoruba", Name = "Yoruba", Key = "eth:yoruba", stringsAsFactors = FALSE),
#'   database = "SocioMap",
#'   formData = list(
#'     domain = "ETHNICITY",
#'     subdomain = "ETHNICITY",
#'     datasetID = "SD1",
#'     cmNameColumn = "CMName",
#'     categoryNamesColumn = "Name",
#'     cmidColumn = "CMID",
#'     keyColumn = "Key"
#'   ),
#'   so = "simple",
#'   ao = "add_uses",
#'   user = "your-userid",
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' }
submitEditUpload <- function(df,
                             database,
                             formData = list(),
                             so = "standard",
                             ao = "add_node",
                             addoptions = list(district = FALSE, recordyear = FALSE),
                             user = NULL,
                             allContext = list(),
                             mergingType = "0",
                             api_key = NULL,
                             api_user = NULL,
                             refresh_waiting_uses = TRUE,
                             url = NULL) {
  upload_result <- uploadInputNodes(
    df = df,
    database = database,
    formData = formData,
    so = so,
    ao = ao,
    addoptions = addoptions,
    user = user,
    allContext = allContext,
    mergingType = mergingType,
    api_key = api_key,
    api_user = api_user,
    url = url
  )

  waiting_result <- NULL
  if (isTRUE(refresh_waiting_uses)) {
    waiting_result <- updateWaitingUSES(
      database = database,
      user = user,
      api_key = api_key,
      api_user = api_user,
      url = url
    )
  }

  list(upload = upload_result, waiting_uses = waiting_result)
}

resolve_api_key <- function(api_key = NULL) {
  if (!is.null(api_key) && nzchar(api_key)) {
    return(api_key)
  }

  env_key <- Sys.getenv("CATMAPR_API_KEY", unset = "")
  if (nzchar(env_key)) {
    return(env_key)
  }

  stop("An API key is required for write operations. Set `api_key` or CATMAPR_API_KEY.")
}

resolve_api_user <- function(api_user = NULL, user = NULL) {
  if (!is.null(api_user) && nzchar(api_user)) {
    return(api_user)
  }
  if (!is.null(user) && nzchar(user)) {
    return(user)
  }

  env_user <- Sys.getenv("CATMAPR_API_USER", unset = "")
  if (nzchar(env_user)) {
    return(env_user)
  }

  NULL
}

build_api_key_headers <- function(api_key, api_user = NULL) {
  headers <- list("X-API-Key" = api_key)
  if (!is.null(api_user) && nzchar(api_user)) {
    headers[["X-API-User"]] <- api_user
  }
  headers
}

coerce_upload_rows <- function(df) {
  if (is.data.frame(df)) {
    return(lapply(seq_len(nrow(df)), function(i) as.list(df[i, , drop = FALSE])))
  }

  if (is.list(df)) {
    return(df)
  }

  stop("`df` must be a data frame or a list of row objects.")
}

normalize_addoptions <- function(addoptions) {
  if (is.null(addoptions)) {
    addoptions <- list()
  }
  if (!is.list(addoptions)) {
    stop("`addoptions` must be a list.")
  }

  list(
    district = isTRUE(addoptions$district),
    recordyear = isTRUE(addoptions$recordyear)
  )
}
