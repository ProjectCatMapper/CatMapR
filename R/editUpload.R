#' Upload Edit Rows to CatMapper
#'
#' Upload rows to CatMapper's `uploadInputNodes` endpoint using authenticated
#' write requests.
#'
#' @param df Data frame or list of row objects to upload.
#' @param database Target database, typically `"SocioMap"` or `"ArchaMap"`.
#' @param form_data Named list matching CatMapper edit-page `formData`.
#' @param action Upload action option. Supported values:
#'   - `"add_node"`
#'   - `"add_uses"`
#'   - `"update_add"`
#'   - `"update_replace"`
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
#' @param action Upload action option.
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
