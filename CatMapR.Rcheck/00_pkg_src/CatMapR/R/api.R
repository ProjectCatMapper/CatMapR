#' Call API
#'
#' This is a helper function to call the API. It takes the endpoint, parameters, request type, and URL as input and returns the API response.
#'
#' @param endpoint API endpoint
#' @param parameters API parameters
#' @param request GET or POST
#' @param url API URL override. If \code{NULL}, \code{CATMAPR_API_URL} is used when set, otherwise \code{"https://api.catmapper.org"}.
#' @param type default or stream
#'
#' @return API response
#'
#' @examples
#' CatMapR:::callAPI(endpoint = "search", parameters = list(term = "Dan", database = "SocioMap", property = "Name", domain = "ETHNICITY"), request = "GET")
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

callAPI = function(endpoint,
                     parameters,
                     request = "GET",
                     url = NULL,
                     type = "default"
) {
  url <- resolve_api_url(url)
  tictoc::tic("API call")
  httr::set_config(httr::config(ssl_verifypeer = 0L))
  result = NULL
  if (request == "GET") {
    result = tryCatch(
      httr::GET(paste0(url,"/",endpoint),
                query = parameters),
      error = function(e) {
        warning(e)
        return(e)
      }
    )
  } else {
    if (is.character(parameters) &&
        length(parameters) == 1 &&
        jsonlite::validate(parameters)) {
      parameters = jsonlite::fromJSON(parameters, simplifyVector = FALSE)
    }
    result = tryCatch(
      httr::POST(paste0(url,"/",endpoint),
                 body = parameters,
                 encode = "json",
                 httr::content_type_json()),
      error = function(e) {
        warning(e)
        return(e)
      }
    )
  }
  if (!is.null(result) && !is.null(result$status_code) && result$status_code == 200) {
    resultContent = tryCatch(
      httr::content(result, as = "text", encoding = "UTF-8"),
      error = function(e)
        return(e)
    )
    if (is.character(resultContent)) {
      if (type == "default") {
        resultData = tryCatch(
          resultContent |> jsonlite::fromJSON(),
          error = function(e)
            resultContent
        )
      } else if (type == "stream") {
        resultData = resultContent
      } else {
        resultData = "Error: must specify type as default or stream"
      }
    } else {
      resultData = resultContent
    }
  } else {
    resultContent = tryCatch(
      httr::content(result, as = "text", encoding = "UTF-8"),
      error = function(e)
        "Unknown error"
    )
    parsedErr = tryCatch(
      jsonlite::fromJSON(resultContent),
      error = function(e)
        NULL
    )

    errMsg = if (!is.null(parsedErr) && !is.null(parsedErr$error)) {
      parsedErr$error
    } else if (is.character(resultContent)) {
      resultContent
    } else {
      "Unknown error"
    }

    resultData = list(error = errMsg)
  }
  tictoc::toc()
  if (!inherits(resultData,"data.frame")){
    resultData = tryCatch({
      resultData = resultData |> jsonlite::fromJSON()
    }, error = function(e) {
      return(resultData)
    })
  }
  return(resultData)
}
