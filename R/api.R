#' Resolve CatMapper API URL
#'
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set, otherwise \code{"https://api.catmapper.org"}.
#'
#' @return Resolved base API URL.
#'
#' @keywords internal
resolve_api_url <- function(url = NULL) {
  if (!is.null(url) && nzchar(url)) {
    return(url)
  }

  env_url <- Sys.getenv("CATMAPR_API_URL", unset = "")
  if (nzchar(env_url)) {
    return(env_url)
  }

  "https://api.catmapper.org"
}

#' Call API
#'
#' Helper function to call the CatMapper API.
#'
#' @param endpoint API endpoint
#' @param parameters API parameters
#' @param request GET, POST or DELETE
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set, otherwise \code{"https://api.catmapper.org"}.
#' @param type default or stream
#' @param headers Optional named list of request headers, for example \code{list("X-API-Key" = "cmk_...")}.
#' @param encode Body encoding: json or multipart. Multipart bodies can include
#'   files created by \code{httr::upload_file()}.
#'
#' @return API response
#'
#' @examples
#' \dontrun{
#' CatMapR:::callAPI(
#'   endpoint = "search",
#'   parameters = list(
#'     term = "Dan",
#'     database = "SocioMap",
#'     property = "Name",
#'     domain = "ETHNICITY"
#'   ),
#'   request = "GET"
#' )
#' }
#'
#' @keywords internal
callAPI <- function(endpoint,
                    parameters,
                    request = "GET",
                    url = NULL,
                    type = "default",
                    headers = NULL,
                    encode = "json") {
  api_help_url <- "https://help.catmapper.org/API.html"
  endpoint <- validate_scalar_character(endpoint, "endpoint")
  request <- validate_choice(toupper(request), c("GET", "POST", "DELETE"), "request")
  encode <- validate_choice(encode, c("json", "multipart"), "encode")
  type <- validate_choice(type, c("default", "stream"), "type")
  url <- resolve_api_url(url)

  tictoc::tic("API call")
  on.exit(tictoc::toc(), add = TRUE)

  request_headers <- NULL
  if (!is.null(headers) && length(headers) > 0) {
    headers <- headers[!vapply(headers, is.null, logical(1))]
    if (length(headers) > 0) {
      request_headers <- do.call(httr::add_headers, headers)
    }
  }

  if (request == "POST" &&
      is.character(parameters) &&
      length(parameters) == 1 &&
      jsonlite::validate(parameters)) {
    parameters <- jsonlite::fromJSON(parameters, simplifyVector = FALSE)
  }

  request_call <- if (request == "GET") {
    c(
      list(
        paste0(url, "/", endpoint),
        query = parameters
      ),
      if (!is.null(request_headers)) list(request_headers) else list()
    )
  } else {
    c(
      list(
        paste0(url, "/", endpoint),
        body = parameters,
        encode = encode
      ),
      if (encode == "json") list(httr::content_type_json()) else list(),
      if (!is.null(request_headers)) list(request_headers) else list()
    )
  }

  result <- tryCatch(
    do.call(switch(request, GET = httr::GET, POST = httr::POST, DELETE = httr::DELETE), request_call),
    error = function(e) {
      stop(sprintf("API request failed: %s", conditionMessage(e)), call. = FALSE)
    }
  )

  status_code <- httr::status_code(result)
  result_content <- tryCatch(
    httr::content(result, as = "text", encoding = "UTF-8"),
    error = function(e) ""
  )

  if (!status_code %in% 200:299) {
    parsed_err <- tryCatch(jsonlite::fromJSON(result_content, simplifyVector = FALSE), error = function(e) NULL)
    err_msg <- if (is.list(parsed_err) && !is.null(parsed_err$error)) {
      parsed_err$error
    } else if (nzchar(result_content)) {
      result_content
    } else {
      sprintf("HTTP %s", status_code)
    }
    if (status_code %in% c(401, 403)) {
      err_msg <- paste0(
          "Not authorized: missing or invalid API key/token. ",
          "Server response: ", err_msg, " ",
          "See ", api_help_url
      )
    }
    stop_catmapr_error(err_msg, response = parsed_err, status_code = status_code)
  }

  if (type == "stream") {
    return(result_content)
  }

  if (!nzchar(result_content)) {
    return(invisible(NULL))
  }

  result_data <- tryCatch(
    jsonlite::fromJSON(result_content),
    error = function(e) result_content
  )

  if (!inherits(result_data, "data.frame")) {
    result_data <- tryCatch(
      jsonlite::fromJSON(result_data),
      error = function(e) result_data
    )
  }

  result_data
}

# Preserve server diagnostics on catchable error conditions for HTTP and task failures.
stop_catmapr_error <- function(message, response = NULL, status_code = NULL, task_id = NULL) {
  stop(structure(
    list(message = message, call = NULL, response = response,
         status_code = status_code,
         error_details = if (is.list(response)) response$error_details else NULL,
         task_id = task_id %||% if (is.list(response)) response$taskId else NULL),
    class = c("catmapr_api_error", "error", "condition")
  ))
}
