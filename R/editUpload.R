#' Upload Edit Rows to CatMapper
#'
#' Upload rows to CatMapper's `uploadInputNodes` endpoint using authenticated
#' write requests.
#'
#' @param df Data frame or list of row objects to upload.
#' @param database Target database, typically `"SocioMap"` or `"ArchaMap"`.
#' @param form_data Named list matching CatMapper edit-page `formData`.
#' @param action Upload action option. Supported values map directly to the
#'   CatMapperJS Edit-page advanced upload options:
#'   - `"add_node"` = "Adding new node for every row"
#'   - `"node_add"` = "Updating existing Node properties--add or add to properties"
#'   - `"node_replace"` = "Updating existing Node properties--replace one property"
#'   - `"add_uses"` = "Adding new uses ties (with old or new nodes)"
#'   - `"update_add"` = "Updating existing USES only--add or add to properties"
#'   - `"update_replace"` = "Updating existing USES only--replace one property"
#'   - `"add_merging"` = "Adding new merging ties for every row"
#'   - `"merging_add"` = "Updating existing Merging tie properties--add or add to properties"
#'   - `"merging_replace"` = "Updating existing Merging tie properties--replace one property"
#' @param add_options Named list with `district` and `recordyear` booleans.
#' @param properties Optional vector/list of upload property names to include.
#' @param merging_type Optional merging mode used by merge upload workflows.
#' @param api_key API key used for authenticated write actions. If `NULL`,
#'   `CATMAPR_API_KEY` is used.
#' @param poll_interval_seconds Polling interval in seconds while waiting for
#'   queued upload tasks.
#' @param timeout_seconds Maximum seconds to wait for upload completion.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set.
#'
#' @return A data frame built from the upload task result rows returned by the
#'   API. The function always triggers a background `updateWaitingUSES` refresh
#'   after upload completion; refresh trigger errors are suppressed.
#' @export
#'
#' @examples
#' \dontrun{
#' result <- upload_rows(
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
#'   form_data = list(
#'     domain = "ETHNICITY",
#'     subdomain = "ETHNICITY",
#'     datasetID = "SD1",
#'     cmNameColumn = "CMName",
#'     categoryNamesColumn = "Name",
#'     alternateCategoryNamesColumns = character(0),
#'     cmidColumn = "CMID",
#'     keyColumn = "Key"
#'   ),
#'   action = "add_uses",
#'   properties = c("variable"),
#'   api_key = Sys.getenv("CATMAPR_API_KEY")
#' )
#' head(result)
#' }
upload_rows <- function(df,
                        database,
                        form_data = list(),
                        action = "add_node",
                        add_options = list(district = FALSE, recordyear = FALSE),
                        properties = NULL,
                        merging_type = "0",
                        api_key = NULL,
                        poll_interval_seconds = 1,
                        timeout_seconds = 600,
                        url = NULL) {
  key <- resolve_api_key(api_key)
  prepared <- prepare_upload_rows(
    df = df,
    form_data = form_data,
    action = action,
    properties = properties,
    merging_type = merging_type,
    database = database
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
    formData = prepared$form_data,
    database = prepared$database,
    df = prepared$rows,
    so = "standard",
    ao = prepared$action,
    addoptions = normalize_add_options(add_options),
    optionalProperties = prepared$properties,
    mergingType = prepared$merging_type
  )

  headers <- build_api_key_headers(api_key = key)
  upload_result <- run_upload_and_wait(
    payload = payload,
    headers = headers,
    url = url,
    poll_interval_seconds = poll_interval_seconds,
    timeout_seconds = timeout_seconds
  )

  # Fire-and-forget trigger; intentionally silent on errors.
  maybe_trigger_waiting_uses_refresh(database = prepared$database, url = url)

  df_out <- upload_result$data
  attr(df_out, "upload_task") <- upload_result$status
  df_out
}

# Trigger waiting-USES contextual relationship refresh in fire-and-forget mode.
# This is intentionally internal and used by upload_rows().
# @noRd
trigger_waiting_uses_refresh <- function(database, url = NULL) {
  database <- validate_database(database)
  callAPI(
    endpoint = "updateWaitingUSES",
    parameters = list(database = database),
    request = "POST",
    url = url
  )
}

maybe_trigger_waiting_uses_refresh <- function(database, url = NULL) {
  tryCatch(
    trigger_waiting_uses_refresh(database = database, url = url),
    error = function(e) invisible(NULL)
  )
}

#' Prepare Upload Payload Components
#'
#' Validate upload action, form-data mappings, and required columns before
#' sending write requests.
#'
#' @param df Data frame or list of row objects to upload.
#' @param form_data Named list matching CatMapper edit-page `formData`.
#' @param action Upload action option. See `upload_rows()` for the full
#'   CatMapperJS crosswalk of supported values and GUI labels.
#' @param properties Optional vector/list of upload property names to include.
#' @param merging_type Optional merging mode used by merge upload workflows.
#' @param database Target database, typically `"SocioMap"` or `"ArchaMap"`.
#'
#' @return A named list with validated upload components.
#' @export
prepare_upload_rows <- function(df,
                                form_data = list(),
                                action = "add_node",
                                properties = NULL,
                                merging_type = "0",
                                database = "SocioMap") {
  database <- validate_database(database)
  action <- validate_scalar_character(action, "action")
  merging_type <- validate_scalar_character(merging_type, "merging_type")
  if (!is.list(form_data)) {
    stop("`form_data` must be a list.", call. = FALSE)
  }

  normalized_properties <- normalize_upload_properties(properties)
  rows <- coerce_upload_rows(df)
  validate_form_data(form_data = form_data, rows = rows)
  validate_required_columns_by_action(rows = rows, action = action, form_data = form_data)

  list(
    database = database,
    form_data = form_data,
    action = action,
    properties = normalized_properties,
    merging_type = merging_type,
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

normalize_upload_properties <- function(properties) {
  validate_character_collection(properties, "properties")
}

validate_form_data <- function(form_data, rows) {
  required_form_fields <- c(
    "datasetID",
    "cmNameColumn",
    "categoryNamesColumn",
    "cmidColumn",
    "keyColumn"
  )
  missing <- required_form_fields[!required_form_fields %in% names(form_data)]
  if (length(missing) > 0) {
    stop(
      sprintf("`form_data` is missing required field(s): %s.", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }

  mapped <- unique(c(
    form_data$cmNameColumn,
    form_data$categoryNamesColumn,
    form_data$cmidColumn,
    form_data$keyColumn,
    as.list(form_data$alternateCategoryNamesColumns)
  ))
  mapped <- mapped[vapply(mapped, function(x) is.character(x) && length(x) == 1 && nzchar(x), logical(1))]
  if (length(rows) == 0 || length(mapped) == 0) {
    return(invisible(NULL))
  }
  row_cols <- names(rows[[1]])
  missing_cols <- mapped[!mapped %in% row_cols]
  if (length(missing_cols) > 0) {
    stop(
      sprintf(
        "Mapped form-data column(s) not found in upload rows: %s.",
        paste(unique(missing_cols), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(NULL)
}

validate_required_columns_by_action <- function(rows, action, form_data) {
  if (length(rows) == 0) {
    return(invisible(NULL))
  }
  row_cols <- names(rows[[1]])
  key_col <- resolve_upload_key_column(form_data)
  cmid_col <- form_data$cmidColumn
  required <- switch(
    action,
    add_uses = c(cmid_col, key_col, "datasetID"),
    update_add = c(cmid_col, key_col, "datasetID"),
    update_replace = c(cmid_col, key_col, "datasetID"),
    add_node = c(form_data$cmNameColumn, form_data$categoryNamesColumn, key_col, "datasetID", "label"),
    character(0)
  )
  required <- unique(required[nzchar(required)])
  missing <- required[!required %in% row_cols]
  if (length(missing) > 0) {
    stop(
      sprintf(
        "Required upload column(s) missing for `action = \"%s\"`: %s.",
        action,
        paste(missing, collapse = ", ")
      ),
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

normalize_add_options <- function(add_options) {
  if (is.null(add_options)) {
    add_options <- list()
  }
  if (!is.list(add_options)) {
    stop("`add_options` must be a list.")
  }

  list(
    district = isTRUE(add_options$district),
    recordyear = isTRUE(add_options$recordyear)
  )
}

resolve_upload_key_column <- function(form_data) {
  if (!is.list(form_data)) {
    return("Key")
  }

  key_column <- form_data$keyColumn
  if (!is.character(key_column) || length(key_column) != 1 || is.na(key_column) || !nzchar(key_column)) {
    return("Key")
  }

  key_column
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

normalize_addoptions <- function(addoptions) {
  normalize_add_options(addoptions)
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

#' Upload Edit-Page Rows to CatMapper
#'
#' Mirrors the CatMapperJS edit-page upload call to \code{/uploadInputNodes}.
#'
#' @param df Data frame or list of row objects to upload.
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param formData Named list matching the edit-page \code{formData} payload.
#' @param so Upload mode, usually \code{"standard"} or \code{"simple"}.
#' @param ao Advanced upload option. Supported values map directly to the
#'   CatMapperJS Edit-page advanced upload options:
#'   \itemize{
#'   \item \code{"add_node"} = "Adding new node for every row"
#'   \item \code{"node_add"} = "Updating existing Node properties--add or add to properties"
#'   \item \code{"node_replace"} = "Updating existing Node properties--replace one property"
#'   \item \code{"add_uses"} = "Adding new uses ties (with old or new nodes)"
#'   \item \code{"update_add"} = "Updating existing USES only--add or add to properties"
#'   \item \code{"update_replace"} = "Updating existing USES only--replace one property"
#'   \item \code{"add_merging"} = "Adding new merging ties for every row"
#'   \item \code{"merging_add"} = "Updating existing Merging tie properties--add or add to properties"
#'   \item \code{"merging_replace"} = "Updating existing Merging tie properties--replace one property"
#'   }
#' @param addoptions Named list with \code{district} and \code{recordyear} booleans.
#' @param allContext Optional vector/list of contextual columns.
#' @param mergingType Optional merging mode used by merge upload workflows.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed API response.
#' @details
#' The \code{ao} argument mirrors the CatMapperJS Edit-page advanced upload
#' option values. For example, the UI label "Updating existing Node
#' properties--replace one property" maps to \code{"node_replace"}, while
#' "Updating existing USES only--replace one property" maps to
#' \code{"update_replace"}.
#' @export
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
    stop("`formData` must be a list.", call. = FALSE)
  }
  allContext <- validate_character_collection(allContext, "allContext")

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

  callAPI(
    endpoint = "uploadInputNodes",
    parameters = payload,
    request = "POST",
    url = url,
    headers = build_api_key_headers(api_key = key)
  )
}

#' Refresh Waiting USES Queue
#'
#' Mirrors the post-upload CatMapperJS edit-page call to \code{/updateWaitingUSES}.
#'
#' @param database Target database, typically \code{"SocioMap"} or \code{"ArchaMap"}.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed API response.
#' @export
updateWaitingUSES <- function(database,
                              api_key = NULL,
                              url = NULL) {
  database <- validate_database(database)
  key <- resolve_api_key(api_key)

  callAPI(
    endpoint = "updateWaitingUSES",
    parameters = list(database = database),
    request = "POST",
    url = url,
    headers = build_api_key_headers(api_key = key)
  )
}

#' Get Upload Task Status
#'
#' Polls the asynchronous CatMapper upload task endpoint and returns the
#' current task state and any incremental events.
#'
#' @param task_id Upload task identifier returned by \code{uploadInputNodes()}.
#' @param cursor Optional event cursor used to request only new log messages.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#'
#' @return Parsed task-status payload.
#' @export
uploadInputNodesStatus <- function(task_id,
                                   cursor = 0L,
                                   api_key = NULL,
                                   url = NULL) {
  task_id <- validate_scalar_character(task_id, "task_id")
  if (length(cursor) != 1 || is.na(cursor) || !is.numeric(cursor) || cursor < 0) {
    stop("`cursor` must be a non-negative number.", call. = FALSE)
  }

  key <- resolve_api_key(api_key)

  callAPI(
    endpoint = "uploadInputNodesStatus",
    parameters = list(taskId = task_id, cursor = as.integer(cursor)),
    request = "POST",
    url = url,
    headers = build_api_key_headers(api_key = key)
  )
}

#' Wait For Upload Task Completion
#'
#' Repeatedly polls \code{/uploadInputNodesStatus} until the task completes,
#' fails, is canceled, or times out.
#'
#' @param task_id Upload task identifier returned by \code{uploadInputNodes()}.
#' @param poll_seconds Delay between status polls in seconds.
#' @param timeout_seconds Maximum time to wait before aborting.
#' @param cursor Optional starting event cursor.
#' @param api_key API key used for authenticated write actions. If \code{NULL},
#'   \code{CATMAPR_API_KEY} is used.
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set.
#' @param quiet If \code{FALSE}, stream newly received upload events with
#'   \code{message()} while waiting.
#'
#' @return Final task-status payload.
#' @export
waitForUploadTask <- function(task_id,
                              poll_seconds = 2,
                              timeout_seconds = 600,
                              cursor = 0L,
                              api_key = NULL,
                              url = NULL,
                              quiet = TRUE) {
  task_id <- validate_scalar_character(task_id, "task_id")
  poll_seconds <- validate_positive_number(poll_seconds, "poll_seconds")
  timeout_seconds <- validate_positive_number(timeout_seconds, "timeout_seconds")
  quiet <- validate_scalar_logical(quiet, "quiet")

  started_at <- Sys.time()
  next_cursor <- as.integer(cursor)

  repeat {
    status <- uploadInputNodesStatus(
      task_id = task_id,
      cursor = next_cursor,
      api_key = api_key,
      url = url
    )

    if (length(status$events) > 0 && !isTRUE(quiet)) {
      for (event in status$events) {
        message(sprintf("[%s] %s", task_id, event))
      }
    }

    if (!is.null(status$nextCursor) && length(status$nextCursor) > 0 && !is.na(status$nextCursor[[1]])) {
      next_cursor <- as.integer(status$nextCursor[[1]])
    }

    task_status <- tolower(as.character(status$status %||% ""))
    if (task_status %in% c("completed", "failed", "canceled")) {
      if (identical(task_status, "failed")) {
        stop(status$error %||% "Upload task failed.", call. = FALSE)
      }
      if (identical(task_status, "canceled")) {
        stop(status$message %||% "Upload task was canceled.", call. = FALSE)
      }
      return(status)
    }

    elapsed <- as.numeric(difftime(Sys.time(), started_at, units = "secs"))
    if (elapsed > timeout_seconds) {
      stop(
        sprintf(
          "Timed out waiting for upload task %s after %.1f seconds.",
          task_id,
          timeout_seconds
        ),
        call. = FALSE
      )
    }

    Sys.sleep(poll_seconds)
  }
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
  refresh_waiting_uses <- validate_scalar_logical(refresh_waiting_uses, "refresh_waiting_uses")

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
