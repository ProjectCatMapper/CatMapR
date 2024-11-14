#' Call API
#'
#' This is a helper function to call the API. It takes the endpoint, parameters, request type, and URL as input and returns the API response.
#'
#' @param endpoint API endpoint
#' @param parameters API parameters
#' @param request GET or POST
#' @param url API URL
#' @param type default or stream
#'
#' @return API response
#'
#' @examples
#' callAPI(endpoint = "search", parameters = list(term = "Dan", database = "SocioMap", property = "Name", domain = "ETHNICITY"), request = "GET")
callAPI = function(endpoint,
                     parameters,
                     request = "GET",
                     url = "https://catmapper.org/api",
                     type = "default"
) {
  tictoc::tic("API call")
  httr::set_config(httr::config(ssl_verifypeer = 0L))
  result = NULL
  e = NULL
  if (request == "GET") {
    result = tryCatch(
      httr::GET(glue::glue("{url}/{endpoint}"),
                query = parameters),
      error = function(e) {
        warning(e)
        return(e)
      }
    )
  } else {
    if (!jsonlite::validate(parameters[[1]])) {
      parameters = jsonlite::toJSON(parameters)
    }
    result = tryCatch(
      httr::POST(glue::glue("{url}/{endpoint}"),
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
      httr::content(result),
      error = function(e)
        return(e)
    )
    if (inherits(resultContent, "xml_node")) {
      resultData = tryCatch(
        xml2::as_list(resultContent) |> unlist() |> unname(),
        error = function(e)
          return(e)
      )
    } else if (is.character(resultContent)) {
      if (type == "default"){
        resultData = tryCatch(
          resultContent |> jsonlite::fromJSON(),
          error = function(e) {
            warning(e)
            return(NULL)
          }
        )
      } else if (type == "stream"){
        resultData = resultContent
      } else {
        resultData = "Error: must specify type as default or stream"
      }

    } else {
      resultData = tryCatch(
        jsonlite::toJSON(resultContent, auto_unbox = T) |> jsonlite::fromJSON(),
        error = function(e) {
          warning(e)
          return(NULL)
        }
      )
    }
  } else {
    resultContent = tryCatch(
      httr::content(result),
      error = function(e)
        return(e)
    )
    errMsg = tryCatch(
      xml2::as_list(resultContent) |> unlist() |> unname(),
      error = function(e)
        return("Unknown error")
    )
    warning(e)
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
