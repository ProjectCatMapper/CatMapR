#' Upload Edit-Page Rows to CatMapper
#'
#' Mirrors the CatMapperJS edit-page upload call to \code{/uploadInputNodes}.
#' This wrapper is intended for write operations and requires a valid API key
#' tied to a registered CatMapper account.
#' Server-side permissions determine whether the authenticated user can perform
#' the requested write action.
#'
#' @param df Data frame or list of row objects to upload.
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param formData Named list matching the edit-page \code{formData} payload.
#' @param so Upload mode, usually \code{"standard"} or \code{"simple"}.
#'   Use \code{"standard"} when the upload key values are already full key
#'   expressions (for example \code{VARIABLE == VALUE}). Use \code{"simple"}
#'   when key values are raw terms only (for example \code{eth:yoruba}) without
#'   the \code{==} expression.
#' @param ao Advanced upload option, e.g. \code{"add_node"}, \code{"add_uses"}, \code{"update_add"}.
#' @param addoptions Named list with \code{district} and \code{recordyear} booleans.
#' @param allContext Optional vector/list of contextual columns.
#' @param mergingType Optional merging mode used by merge upload workflows.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed API response.
#' @details CatMapR does not manage username/password login flows. It sends
#'   API-key-authenticated requests and the CatMapper API identifies the acting
#'   user on the server side. For \code{so = "simple"}, CatMapR checks the
#'   selected key column and warns if preformatted key expressions are supplied;
#'   it strips the left-hand side before upload so the API does not produce
#'   malformed \code{Key == ... == ...} strings.
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
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' }
uploadInputNodes <- function(df,
                             database,
                             formData = list(),
                             so = "standard",
                             ao = "add_node",
                             addoptions = list(district = FALSE, recordyear = FALSE),
                             allContext = list(),
                             mergingType = "0",
                             api_key = NULL,
                             url = NULL) {
  database <- validate_database(database)
  so <- validate_scalar_character(so, "so")
  ao <- validate_scalar_character(ao, "ao")
  mergingType <- validate_scalar_character(mergingType, "mergingType")
  key <- resolve_api_key(api_key)
  if (!is.list(formData)) {
    stop("`formData` must be a list.")
  }

  rows <- coerce_upload_rows(df)
  rows <- sanitize_simple_upload_key_values(
    rows = rows,
    so = so,
    formData = formData
  )

  payload <- list(
    formData = formData,
    database = database,
    df = rows,
    so = so,
    ao = ao,
    addoptions = normalize_addoptions(addoptions),
    allContext = allContext,
    mergingType = mergingType
  )

  headers <- build_api_key_headers(api_key = key)

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
#' This wrapper is intended for write operations and requires a valid API key
#' tied to a registered CatMapper account.
#' Server-side permissions determine whether the authenticated user can perform
#' the requested write action.
#'
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed API response.
#' @details CatMapR does not manage username/password login flows. It sends
#'   API-key-authenticated requests and the CatMapper API identifies the acting
#'   user on the server side.
#' @export
#'
#' @examples
#' \dontrun{
#' updateWaitingUSES(
#'   database = "SocioMap",
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' }
updateWaitingUSES <- function(database,
                              api_key = NULL,
                              url = NULL) {
  database <- validate_database(database)
  key <- resolve_api_key(api_key)
  payload <- list(database = database)

  headers <- build_api_key_headers(api_key = key)

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
#' This write flow requires a valid API key tied to a registered CatMapper
#' account, and permissions are enforced by the server.
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
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' }
submitEditUpload <- function(df,
                             database,
                             formData = list(),
                             so = "standard",
                             ao = "add_node",
                             addoptions = list(district = FALSE, recordyear = FALSE),
                             allContext = list(),
                             mergingType = "0",
                             api_key = NULL,
                             refresh_waiting_uses = TRUE,
                             url = NULL) {
  database <- validate_database(database)
  so <- validate_scalar_character(so, "so")
  ao <- validate_scalar_character(ao, "ao")
  mergingType <- validate_scalar_character(mergingType, "mergingType")
  if (!is.logical(refresh_waiting_uses) || length(refresh_waiting_uses) != 1 || is.na(refresh_waiting_uses)) {
    stop("`refresh_waiting_uses` must be TRUE or FALSE.", call. = FALSE)
  }

  upload_result <- uploadInputNodes(
    df = df,
    database = database,
    formData = formData,
    so = so,
    ao = ao,
    addoptions = addoptions,
    allContext = allContext,
    mergingType = mergingType,
    api_key = api_key,
    url = url
  )

  waiting_result <- NULL
  if (isTRUE(refresh_waiting_uses)) {
    waiting_result <- updateWaitingUSES(
      database = database,
      api_key = api_key,
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

  stop(
    "An API key is required for write operations from a registered CatMapper account. Set `api_key` or CATMAPR_API_KEY."
  )
}

build_api_key_headers <- function(api_key) {
  list("X-API-Key" = api_key)
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

resolve_upload_key_column <- function(formData) {
  if (!is.list(formData)) {
    return("Key")
  }

  key_column <- formData$keyColumn
  if (!is.character(key_column) || length(key_column) != 1 || is.na(key_column) || !nzchar(key_column)) {
    return("Key")
  }

  key_column
}

sanitize_simple_upload_key_values <- function(rows, so, formData) {
  if (tolower(so) != "simple" || !is.list(rows) || length(rows) == 0) {
    return(rows)
  }

  key_column <- resolve_upload_key_column(formData)
  converted_rows <- integer(0)
  unsupported_rows <- integer(0)

  for (i in seq_along(rows)) {
    row <- rows[[i]]
    if (!is.list(row) || is.null(names(row)) || !key_column %in% names(row)) {
      next
    }

    raw_value <- row[[key_column]]
    if (is.null(raw_value) || length(raw_value) != 1 || is.na(raw_value)) {
      next
    }

    key_text <- trimws(as.character(raw_value))
    if (!grepl("==", key_text, fixed = TRUE)) {
      next
    }

    if (grepl("&&", key_text, fixed = TRUE)) {
      unsupported_rows <- c(unsupported_rows, i)
      next
    }

    parts <- trimws(strsplit(key_text, "==", fixed = TRUE)[[1]])
    parts <- parts[nzchar(parts)]
    if (length(parts) < 2) {
      unsupported_rows <- c(unsupported_rows, i)
      next
    }

    rows[[i]][[key_column]] <- parts[length(parts)]
    converted_rows <- c(converted_rows, i)
  }

  if (length(unsupported_rows) > 0) {
    stop(
      sprintf(
        paste0(
          "`so = \"simple\"` expects raw key values in `%s` without `==`. ",
          "Rows %s contain compound expressions (for example with `&&`) and must use `so = \"standard\"`."
        ),
        key_column,
        paste(unsupported_rows, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (length(converted_rows) > 0) {
    warning(
      sprintf(
        paste0(
          "`so = \"simple\"` expects raw key values in `%s` (for example `eth:yoruba`) and not `VARIABLE == VALUE`. ",
          "CatMapR stripped the left-hand side for rows: %s."
        ),
        key_column,
        paste(converted_rows, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  rows
}
