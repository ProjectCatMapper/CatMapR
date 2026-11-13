spatial_response <- function(payload, status = 200L) {
  structure(list(status_code = status,
                 headers = list("Content-Type" = "application/json"),
                 content = charToRaw(jsonlite::toJSON(payload, auto_unbox = TRUE))),
            class = "response")
}

spatial_details <- list(list(feature = 2L, field = "Key", code = "uses_not_unique", message = "Missing tie"))
spatial_token <- paste(rep("a", 32), collapse = "")

test_that("httr prepares multipart fields and policy row arrays on the wire", {
  path <- tempfile(fileext = ".geojson")
  writeLines("{}", path)
  on.exit(unlink(path), add = TRUE)
  calls <- list()
  local_mocked_bindings(request_perform = function(req, handle, refresh = TRUE) {
    calls[[length(calls) + 1L]] <<- req
    spatial_response(list(valid = TRUE, token = spatial_token))
  }, .package = "httr")
  preflight_polygon_upload(path, "SocioMap", replace_existing = TRUE, api_key = "test-key")
  req <- calls[[1]]
  expect_identical(req$method, "POST")
  expect_identical(req$fields$replaceExisting, "true")
  expect_s3_class(req$fields$file, "form_file")
  expect_identical(unname(req$headers["X-API-Key"]), "test-key")
  expect_false("Content-Type" %in% names(req$headers))

  validate_contextual_rows(list(list(CMID = "SM1", parent = list("SM2"))), "SocioMap")
  wire <- jsonlite::fromJSON(rawToChar(calls[[2]]$options$postfields), simplifyVector = FALSE)
  expect_identical(wire$rows, list(list(CMID = "SM1", parent = list("SM2"))))
})

test_that("polygon preflight sends a file using multipart without a JSON content type", {
  path <- tempfile(fileext = ".geojson")
  writeLines('{"type":"FeatureCollection","features":[]}', path)
  on.exit(unlink(path), add = TRUE)
  captured <- new.env()
  local_mocked_bindings(POST = function(url, ...) {
    captured$url <- url
    captured$args <- list(...)
    spatial_response(list(valid = TRUE, token = spatial_token))
  }, .package = "httr")

  report <- preflight_polygon_upload(path, "ArchaMap", api_key = "test-key", url = "https://example.test")
  expect_identical(report$token, spatial_token)
  expect_identical(captured$url, "https://example.test/api/uploads/geojson/polygons/preflight")
  expect_identical(captured$args$encode, "multipart")
  expect_identical(captured$args$body$database, "archamap")
  expect_identical(captured$args$body$replaceExisting, "false")
  expect_s3_class(captured$args$body$file, "form_file")
  expect_identical(captured$args$body$file$path, normalizePath(path, winslash = "/"))
  unnamed <- captured$args[names(captured$args) == ""]
  headers <- unlist(lapply(unnamed, function(x) x$headers))
  expect_identical(unname(headers["X-API-Key"]), "test-key")
  expect_false("Content-Type" %in% names(headers))
})

test_that("preflight rejection preserves feature diagnostics and does not apply", {
  path <- tempfile(fileext = ".json")
  writeLines("{}", path)
  on.exit(unlink(path), add = TRUE)
  calls <- character()
  local_mocked_bindings(POST = function(url, ...) {
    calls <<- c(calls, url)
    spatial_response(list(error = "Preflight failed", error_details = spatial_details), 422L)
  }, .package = "httr")
  err <- tryCatch(preflight_polygon_upload(path, "SocioMap", api_key = "test-key"),
                  catmapr_api_error = identity)
  expect_s3_class(err, "catmapr_api_error")
  expect_identical(conditionMessage(err), "Preflight failed")
  expect_identical(err$status_code, 422L)
  expect_identical(err$error_details, spatial_details)
  expect_length(calls, 1)
  expect_match(calls, "/preflight$")
})

test_that("apply and discard use authenticated requests and shared task polling", {
  calls <- list()
  local_mocked_bindings(POST = function(url, ...) {
    calls[[length(calls) + 1L]] <<- c(list(url = url), list(...))
    if (grepl("/apply$", url)) return(spatial_response(list(taskId = "task-1", status = "queued"), 202L))
    if (grepl("/cancel$", url)) return(spatial_response(list(taskId = "task-1", status = "running"), 202L))
    spatial_response(list(taskId = "task-1", status = "completed", file = list(list(usesLinks = 1L))))
  }, DELETE = function(url, ...) {
    calls[[length(calls) + 1L]] <<- c(list(url = url), list(...))
    spatial_response(list(message = "Polygon upload discarded."))
  }, .package = "httr")
  task <- apply_polygon_upload(spatial_token, api_key = "test-key")
  done <- waitForUploadTask(task$taskId, api_key = "test-key")
  expect_identical(done$status, "completed")
  expect_equal(done$file$usesLinks, 1)
  cancel_upload_task(task$taskId, cursor = 4L, api_key = "test-key")
  discard_polygon_upload(spatial_token, api_key = "test-key")
  expect_length(calls, 4)
  expect_identical(calls[[3]]$body, list(taskId = "task-1", cursor = 4L))
  expect_match(calls[[4]]$url, paste0("/", spatial_token, "$"))
  for (call in calls) {
    headers <- unlist(lapply(call[names(call) == ""], function(x) x$headers))
    expect_identical(unname(headers["X-API-Key"]), "test-key")
  }
})

test_that("HTTP authorization failures retain the server response", {
  local_mocked_bindings(POST = function(...) {
    spatial_response(list(error = "Admin role required", error_details = spatial_details), 403L)
  }, .package = "httr")
  err <- tryCatch(apply_polygon_upload(spatial_token, api_key = "test-key"), catmapr_api_error = identity)
  expect_match(conditionMessage(err), "Not authorized")
  expect_identical(err$status_code, 403L)
  expect_identical(err$response$error, "Admin role required")
  expect_identical(err$error_details, spatial_details)
})

test_that("both task waiters keep task IDs and diagnostics on failure", {
  for (state in c("failed", "canceled")) {
    local_mocked_bindings(callAPI = function(...) {
      list(status = state, error = "Invalid polygon", message = "Stopped", error_details = spatial_details)
    }, .package = "CatMapR")
    err <- tryCatch(waitForUploadTask("task-1", api_key = "test-key"), catmapr_api_error = identity)
    expect_identical(err$error_details, spatial_details)
    expect_identical(err$task_id, "task-1")
    err <- tryCatch(CatMapR:::wait_for_upload_task("task-1", list(), NULL, 1, 5),
                    catmapr_api_error = identity)
    expect_identical(err$error_details, spatial_details)
    expect_identical(err$task_id, "task-1")
  }
})

test_that("read-only spatial wrappers preserve payloads and serialize policy rows", {
  calls <- list()
  payload <- list(polygons = list(), truncated = 3L, sources = "SD1")
  local_mocked_bindings(callAPI = function(endpoint, parameters, ...) {
    calls[[length(calls) + 1L]] <<- c(list(endpoint = endpoint, parameters = parameters), list(...))
    payload
  }, .package = "CatMapR")
  expect_identical(get_geometry("SocioMap", "SM1"), payload)
  expect_identical(explore_geometry("ArchaMap", "AM1", layers = c("direct", "related"),
                                    relations = "CONTAINS", max_depth = 2, polygon_limit = 12), payload)
  get_contextual_policy("ArchaMap")
  validate_contextual_rows(data.frame(CMID = "AM1", parent = "AM2"), "ArchaMap")
  expect_identical(calls[[1]]$parameters, list(database = "sociomap", cmid = "SM1"))
  expect_identical(calls[[2]]$endpoint, "api/databases/archamap/nodes/AM1/explore-geometry")
  expect_identical(calls[[2]]$parameters, list(layers = "direct,related", relations = "CONTAINS",
                                            maxDepth = 2L, polygonLimit = 12L))
  expect_identical(calls[[3]]$endpoint, "api/databases/archamap/metadata/contextual-policy")
  expect_identical(calls[[4]]$parameters, list(rows = list(list(CMID = "AM1", parent = "AM2"))))
  expect_identical(calls[[4]]$request, "POST")
})

test_that("invalid inputs never send requests", {
  local_mocked_bindings(callAPI = function(...) stop("unexpected request"), .package = "CatMapR")
  expect_error(preflight_polygon_upload("missing.geojson", "SocioMap"), "existing")
  expect_error(apply_polygon_upload("../bad"), "token")
  expect_error(discard_polygon_upload("expired"), "token")
  expect_error(cancel_upload_task("task-1", cursor = -1), "cursor")
  expect_error(explore_geometry("SocioMap", "SM1", polygon_limit = 1.5), "positive integer")
  expect_error(validate_contextual_rows(rep(list(list(CMID = "SM1")), 1001), "SocioMap"), "1000")
  expect_error(validate_contextual_rows(list("bad"), "SocioMap"), "row objects")
})
