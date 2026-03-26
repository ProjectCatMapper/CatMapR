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
#' @param optionalProperties Optional vector/list alias for \code{allContext}.
#'   When provided, this value is used as the upload property list.
#' @param mergingType Optional merging mode used by merge upload workflows.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param poll_interval_seconds Polling interval in seconds while waiting for
#'   queued upload tasks.
#' @param timeout_seconds Maximum seconds to wait for upload completion.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return A data frame built from the upload task result rows returned by the
#'   API.
#' @details CatMapR does not manage username/password login flows. It sends
#'   API-key-authenticated requests and the CatMapper API identifies the acting
#'   user on the server side. For \code{so = "simple"}, only
#'   \code{ao = "add_uses"} is supported and key values in the selected key
#'   column must be raw values without \code{==}.
#' @export
#'
#' @examples
#' \dontrun{
#' upload_result <- uploadInputNodes(
#'   df = data.frame(
#'     CMName = "Yoruba",
#'     Name = "Yoruba",
#'     CMID = "",
#'     Key = "Type == Adamana Brown",
#'     datasetID = "SD1",
#'     label = "ETHNICITY",
#'     stringsAsFactors = FALSE
#'   ),
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
#'   so = "standard",
#'   ao = "add_uses",
#'   poll_interval_seconds = 1,
#'   timeout_seconds = 600,
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' head(upload_result)
#' }
uploadInputNodes <- function(df,
                             database,
                             formData = list(),
                             so = "standard",
                             ao = "add_node",
                             addoptions = list(district = FALSE, recordyear = FALSE),
                             allContext = list(),
                             optionalProperties = NULL,
                             mergingType = "0",
                             api_key = NULL,
                             poll_interval_seconds = 1,
                             timeout_seconds = 600,
                             url = NULL) {
  key <- resolve_api_key(api_key)
  prepared <- prepare_edit_upload(
    df = df,
    formData = formData,
    so = so,
    ao = ao,
    allContext = allContext,
    optionalProperties = optionalProperties,
    mergingType = mergingType
  )
  poll_interval_seconds <- validate_positive_number(
    poll_interval_seconds,
    "poll_interval_seconds"
  )
  timeout_seconds <- validate_positive_number(
    timeout_seconds,
    "timeout_seconds"
  )

  payload <- list(
    formData = prepared$formData,
    database = prepared$database,
    df = prepared$rows,
    so = prepared$so,
    ao = prepared$ao,
    addoptions = normalize_addoptions(addoptions),
    allContext = prepared$allContext,
    mergingType = prepared$mergingType
  )

  headers <- build_api_key_headers(api_key = key)
  upload_result <- run_upload_and_wait(
    payload = payload,
    headers = headers,
    url = url,
    poll_interval_seconds = poll_interval_seconds,
    timeout_seconds = timeout_seconds
  )

  df_out <- upload_result$data
  attr(df_out, "upload_task") <- upload_result$status
  df_out
}

# Trigger waiting-USES contextual relationship refresh in fire-and-forget mode.
# This is intentionally internal and used by submitEditUpload().
# The endpoint does not require API-key headers.
# @noRd
updateWaitingUSES <- function(database,
                              url = NULL) {
  database <- validate_database(database)
  payload <- list(database = database)
  callAPI(
    endpoint = "updateWaitingUSES",
    parameters = payload,
    request = "POST",
    url = url
  )
}

#' Submit Edit Upload and Refresh Queue
#'
#' Convenience wrapper that executes the CatMapperJS edit-page flow. It uploads
#' rows via \code{/uploadInputNodes} and then triggers waiting-USES contextual
#' relationship refresh in fire-and-forget mode.
#' This write flow requires a valid API key for upload calls, and permissions
#' are enforced by the server.
#'
#' @inheritParams uploadInputNodes
#' @param refresh_waiting_uses If \code{TRUE}, ensure waiting-USES refresh is
#'   triggered after upload without polling for completion.
#'
#' @return A data frame built from the upload task result rows returned by the
#'   API.
#' @export
#'
#' @examples
#' \dontrun{
#' result <- submitEditUpload(
#'   df = data.frame(
#'     CMName = "Yoruba",
#'     Name = "Yoruba",
#'     CMID = "",
#'     Key = "Type == Adamana Brown",
#'     datasetID = "SD1",
#'     label = "ETHNICITY",
#'     stringsAsFactors = FALSE
#'   ),
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
#'   so = "standard",
#'   ao = "add_uses",
#'   poll_interval_seconds = 1,
#'   timeout_seconds = 600,
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' head(result)
#' }
submitEditUpload <- function(df,
                             database,
                             formData = list(),
                             so = "standard",
                             ao = "add_node",
                             addoptions = list(district = FALSE, recordyear = FALSE),
                             allContext = list(),
                             optionalProperties = NULL,
                             mergingType = "0",
                             api_key = NULL,
                             refresh_waiting_uses = TRUE,
                             poll_interval_seconds = 1,
                             timeout_seconds = 600,
                             url = NULL) {
  key <- resolve_api_key(api_key)
  refresh_waiting_uses <- validate_scalar_logical(
    refresh_waiting_uses,
    "refresh_waiting_uses"
  )
  prepared <- prepare_edit_upload(
    df = df,
    formData = formData,
    so = so,
    ao = ao,
    allContext = allContext,
    optionalProperties = optionalProperties,
    mergingType = mergingType,
    database = database,
    fail_on_simple_mismatch = TRUE
  )
  poll_interval_seconds <- validate_positive_number(
    poll_interval_seconds,
    "poll_interval_seconds"
  )
  timeout_seconds <- validate_positive_number(
    timeout_seconds,
    "timeout_seconds"
  )
  headers <- build_api_key_headers(api_key = key)
  payload <- list(
    formData = prepared$formData,
    database = prepared$database,
    df = prepared$rows,
    so = prepared$so,
    ao = prepared$ao,
    addoptions = normalize_addoptions(addoptions),
    allContext = prepared$allContext,
    mergingType = prepared$mergingType
  )
  upload_result <- run_upload_and_wait(
    payload = payload,
    headers = headers,
    url = url,
    poll_interval_seconds = poll_interval_seconds,
    timeout_seconds = timeout_seconds
  )
  upload_status <- upload_result$status

  if (isTRUE(refresh_waiting_uses)) {
    waiting_task_id <- upload_status$waitingUsesTask
    waiting_task_exists <- !is.null(waiting_task_id) && nzchar(as.character(waiting_task_id))
    if (!waiting_task_exists) {
      tryCatch(
        updateWaitingUSES(
          database = prepared$database,
          url = url
        ),
        error = function(e) {
          warning(
            sprintf(
              "Failed to trigger waiting-USES refresh for `%s`: %s",
              prepared$database,
              conditionMessage(e)
            ),
            call. = FALSE
          )
          invisible(NULL)
        }
      )
    }
  }

  df_out <- upload_result$data
  attr(df_out, "upload_task") <- upload_status
  df_out
}

#' Prepare Edit Upload Payload Components
#'
#' Validates upload mode, operation, formData mappings, and key safety before
#' sending write requests.
#'
#' @param df Data frame or list of row objects to upload.
#' @param formData Named list matching the edit-page \code{formData} payload.
#' @param so Upload mode, usually \code{"standard"} or \code{"simple"}.
#' @param ao Advanced upload option, e.g. \code{"add_node"}, \code{"add_uses"}, \code{"update_add"}.
#' @param allContext Optional vector/list of contextual columns.
#' @param optionalProperties Optional vector/list alias for \code{allContext}.
#' @param mergingType Optional merging mode used by merge upload workflows.
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param fail_on_simple_mismatch Internal guard; when \code{TRUE}, simple-mode
#'   restrictions are strictly enforced.
#'
#' @return A named list with validated upload components.
#' @export
prepare_edit_upload <- function(df,
                                formData = list(),
                                so = "standard",
                                ao = "add_node",
                                allContext = list(),
                                optionalProperties = NULL,
                                mergingType = "0",
                                database = "SocioMap",
                                fail_on_simple_mismatch = TRUE) {
  database <- validate_database(database)
  so <- validate_scalar_character(so, "so")
  ao <- validate_scalar_character(ao, "ao")
  mergingType <- validate_scalar_character(mergingType, "mergingType")
  fail_on_simple_mismatch <- validate_scalar_logical(
    fail_on_simple_mismatch,
    "fail_on_simple_mismatch"
  )
  if (!is.list(formData)) {
    stop("`formData` must be a list.", call. = FALSE)
  }

  normalized_context <- resolve_optional_properties(
    allContext = allContext,
    optionalProperties = optionalProperties
  )
  rows <- coerce_upload_rows(df)
  validate_form_data(formData = formData, rows = rows, so = so, ao = ao)
  validate_required_columns_by_ao(rows = rows, so = so, ao = ao, formData = formData)
  if (isTRUE(fail_on_simple_mismatch)) {
    validate_simple_mode_selection(so = so, ao = ao)
    validate_simple_upload_key_values(rows = rows, so = so, formData = formData)
  }

  list(
    database = database,
    formData = formData,
    so = so,
    ao = ao,
    allContext = normalized_context,
    mergingType = mergingType,
    rows = rows
  )
}

run_upload_and_wait <- function(payload,
                                headers,
                                url,
                                poll_interval_seconds,
                                timeout_seconds) {
  start <- callAPI(
    endpoint = "uploadInputNodes",
    parameters = payload,
    request = "POST",
    url = url,
    headers = headers
  )

  task_id <- as.character(start$taskId %||% "")
  if (!nzchar(task_id)) {
    stop(
      "Upload start response did not include `taskId`; cannot poll task completion.",
      call. = FALSE
    )
  }

  status <- wait_for_upload_task(
    task_id = task_id,
    headers = headers,
    url = url,
    poll_interval_seconds = poll_interval_seconds,
    timeout_seconds = timeout_seconds
  )
  data <- upload_status_to_dataframe(status)
  list(data = data, status = status, start = start)
}

wait_for_upload_task <- function(task_id,
                                 headers,
                                 url,
                                 poll_interval_seconds,
                                 timeout_seconds) {
  started <- Sys.time()
  cursor <- 0L
  repeat {
    status <- callAPI(
      endpoint = "uploadInputNodesStatus",
      parameters = list(taskId = task_id, cursor = cursor),
      request = "POST",
      url = url,
      headers = headers
    )
    next_cursor <- suppressWarnings(as.integer(status$nextCursor %||% cursor))
    if (!is.na(next_cursor)) {
      cursor <- next_cursor
    }
    state <- tolower(as.character(status$status %||% ""))
    if (state == "completed") {
      return(status)
    }
    if (state %in% c("failed", "canceled")) {
      err <- as.character(status$error %||% status$message %||% "Upload task did not complete successfully.")
      stop(
        sprintf("Upload task `%s` ended with status `%s`: %s", task_id, state, err),
        call. = FALSE
      )
    }
    elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    if (elapsed >= timeout_seconds) {
      stop(
        sprintf(
          "Timed out waiting for upload task `%s` after %.0f seconds (last status: %s).",
          task_id,
          timeout_seconds,
          state
        ),
        call. = FALSE
      )
    }
    Sys.sleep(poll_interval_seconds)
  }
}

upload_status_to_dataframe <- function(status) {
  file_data <- status$file %||%
    status$resultFile %||%
    status$data %||%
    status$rows %||%
    status$result
  out <- normalize_table(file_data)
  desired_order <- status$order %||%
    status$resultOrder %||%
    status$columns
  if (is.character(desired_order) && length(desired_order) > 0) {
    present <- desired_order[desired_order %in% names(out)]
    remainder <- setdiff(names(out), present)
    out <- out[, c(present, remainder), drop = FALSE]
  }
  out
}

normalize_table <- function(x) {
  if (is.null(x)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  if (is.data.frame(x)) {
    return(x)
  }
  if (is.list(x) && length(x) == 0) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  if (is.list(x) && all(vapply(x, is.list, logical(1)))) {
    row_names <- unique(unlist(lapply(x, names), use.names = FALSE))
    if (length(row_names) == 0) {
      return(data.frame(stringsAsFactors = FALSE))
    }
    out_cols <- lapply(row_names, function(name) {
      values <- lapply(x, function(row) row[[name]])
      values[sapply(values, is.null)] <- NA
      unlist(values, use.names = FALSE)
    })
    names(out_cols) <- row_names
    return(as.data.frame(out_cols, stringsAsFactors = FALSE, check.names = FALSE))
  }
  as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
}

resolve_optional_properties <- function(allContext, optionalProperties) {
  if (is.null(optionalProperties)) {
    return(validate_character_collection(allContext, "allContext"))
  }
  validate_character_collection(optionalProperties, "optionalProperties")
}

validate_form_data <- function(formData, rows, so, ao) {
  required_form_fields <- c(
    "datasetID",
    "cmNameColumn",
    "categoryNamesColumn",
    "cmidColumn",
    "keyColumn"
  )
  missing <- required_form_fields[!required_form_fields %in% names(formData)]
  if (length(missing) > 0) {
    stop(
      sprintf("`formData` is missing required field(s): %s.", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }

  mapped <- unique(c(
    formData$cmNameColumn,
    formData$categoryNamesColumn,
    formData$cmidColumn,
    formData$keyColumn,
    as.list(formData$alternateCategoryNamesColumns)
  ))
  mapped <- mapped[vapply(mapped, function(x) is.character(x) && length(x) == 1 && nzchar(x), logical(1))]
  if (length(rows) == 0 || length(mapped) == 0) {
    return(invisible(NULL))
  }
  row_cols <- names(rows[[1]])
  missing_cols <- mapped[!mapped %in% row_cols]
  if (length(missing_cols) > 0 && tolower(so) == "standard") {
    stop(
      sprintf(
        "Mapped formData column(s) not found in upload rows for `so = \"standard\"`: %s.",
        paste(unique(missing_cols), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(NULL)
}

validate_required_columns_by_ao <- function(rows, so, ao, formData) {
  if (length(rows) == 0 || tolower(so) != "standard") {
    return(invisible(NULL))
  }
  row_cols <- names(rows[[1]])
  key_col <- resolve_upload_key_column(formData)
  cmid_col <- formData$cmidColumn
  required <- switch(
    ao,
    add_uses = c(cmid_col, key_col, "datasetID"),
    update_add = c(cmid_col, key_col, "datasetID"),
    update_replace = c(cmid_col, key_col, "datasetID"),
    add_node = c(formData$cmNameColumn, formData$categoryNamesColumn, key_col, "datasetID", "label"),
    character(0)
  )
  required <- unique(required[nzchar(required)])
  missing <- required[!required %in% row_cols]
  if (length(missing) > 0) {
    stop(
      sprintf(
        "Required upload column(s) missing for `ao = \"%s\"` in `so = \"standard\"`: %s.",
        ao,
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(NULL)
}

validate_simple_mode_selection <- function(so, ao) {
  if (tolower(so) == "simple" && ao != "add_uses") {
    stop(
      "`so = \"simple\"` is only supported when `ao = \"add_uses\"`. Use `so = \"standard\"` for other upload actions.",
      call. = FALSE
    )
  }
  invisible(NULL)
}

resolve_api_key <- function(api_key = NULL) {
  api_help_url <- "https://help.catmapper.org/API.html"
  if (!is.null(api_key) && nzchar(api_key)) {
    return(api_key)
  }

  env_key <- Sys.getenv("CATMAPR_API_KEY", unset = "")
  if (nzchar(env_key)) {
    return(env_key)
  }
  legacy_env_key <- Sys.getenv("CATMAPPER_API_KEY", unset = "")
  if (nzchar(legacy_env_key)) {
    return(legacy_env_key)
  }

  stop(
    paste0(
      "An API key is required for write operations from a registered CatMapper account. ",
      "Set `api_key`, `CATMAPR_API_KEY` (preferred), or `CATMAPPER_API_KEY`. ",
      "If your key is missing or invalid, see ", api_help_url
    ),
    call. = FALSE
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

validate_simple_upload_key_values <- function(rows, so, formData) {
  if (tolower(so) != "simple" || !is.list(rows) || length(rows) == 0) {
    return(invisible(NULL))
  }

  key_column <- resolve_upload_key_column(formData)
  offending_rows <- integer(0)

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
    offending_rows <- c(offending_rows, i)
  }

  if (length(offending_rows) > 0) {
    stop(
      sprintf(
        paste0(
          "`so = \"simple\"` expects raw key values in `%s` without `==`. ",
          "Rows %s include preformatted key expressions; use `so = \"standard\"`."
        ),
        key_column,
        paste(offending_rows, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invisible(NULL)
}

validate_positive_number <- function(x, arg) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
    stop(sprintf("`%s` must be a positive number.", arg), call. = FALSE)
  }
  as.numeric(x)
}

`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0) {
    return(b)
  }
  a
}
