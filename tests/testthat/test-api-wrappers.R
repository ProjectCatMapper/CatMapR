test_that("list_datasets uses allDatasets endpoint", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(ok = TRUE)
    },
    .package = "CatMapR"
  )

  result <- CatMapR::list_datasets(database = "SocioMap")
  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "allDatasets")
  expect_identical(captured$request, "GET")
  expect_identical(captured$parameters, list(database = "SocioMap"))
})

test_that("get_dataset_metadata sends cmid parameter", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(ok = TRUE)
    },
    .package = "CatMapR"
  )

  CatMapR::get_dataset_metadata(
    database = "ArchaMap",
    cmid = "AD1",
    domain = "CATEGORY",
    children = TRUE
  )

  expect_identical(captured$endpoint, "dataset")
  expect_identical(captured$request, "GET")
  expect_identical(
    captured$parameters,
    list(database = "ArchaMap", cmid = "AD1", domain = "CATEGORY", children = TRUE)
  )
})

test_that("search_database validates query and limit", {
  expect_error(
    CatMapR::search_database(database = "SocioMap", query = "maybe"),
    "`query` must be one of: true, false.",
    fixed = TRUE
  )
  expect_error(
    CatMapR::search_database(database = "SocioMap", query = "false", limit = 0),
    "`limit` must be a positive number.",
    fixed = TRUE
  )
})

test_that("translate_rows posts translate payload", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(file = list(), order = character(0))
    },
    .package = "CatMapR"
  )

  result <- CatMapR::translate_rows(
    rows = data.frame(period = "Archaic", stringsAsFactors = FALSE),
    database = "ArchaMap",
    term = "period",
    domain = c("PERIOD", "CATEGORY"),
    unique_rows = TRUE
  )

  expect_type(result, "list")
  expect_identical(captured$endpoint, "translate")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$domain, "PERIOD")
  expect_identical(captured$parameters$uniqueRows, TRUE)
})

test_that("propose_merge_links formats dataset choices", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      data.frame(datasetID = "SD1", stringsAsFactors = FALSE)
    },
    .package = "CatMapR"
  )

  result <- CatMapR::propose_merge_links(
    categoryLabel = "ETHNICITY",
    datasetChoices = c("SD5", "SD6"),
    database = "SocioMap"
  )

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "proposeMergeSubmit")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$datasetChoices, "SD5,SD6")
})

test_that("join_datasets posts to joinDatasets endpoint", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      data.frame(stringsAsFactors = FALSE)
    },
    .package = "CatMapR"
  )

  left <- data.frame(datasetID = "SD1", key = "A", stringsAsFactors = FALSE)
  right <- data.frame(datasetID = "SD2", key = "A", stringsAsFactors = FALSE)
  CatMapR::join_datasets(database = "SocioMap", joinLeft = left, joinRight = right)

  expect_identical(captured$endpoint, "joinDatasets")
  expect_identical(captured$request, "POST")
})

test_that("get_cmid_info uses REST CMID endpoint", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$request <- request
      list()
    },
    .package = "CatMapR"
  )

  CatMapR::get_cmid_info(database = "SocioMap", cmid = "SM1")
  expect_identical(captured$endpoint, "CMID/SocioMap/SM1")
  expect_identical(captured$request, "GET")
})

test_that("domain and property wrappers normalize output", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      if (endpoint == "getTranslatedomains") {
        return(list(list(group = "ETHNICITY", nodes = list("ETHNICITY"))))
      }
      if (endpoint == "metadata/properties/archamap") {
        return(list(table = list(list(nodeID = "n1", CMName = "foo", property = "type", value = "x"))))
      }
      if (endpoint == "metadata/uploadProperties/archamap") {
        return(list(
          database = "ArchaMap",
          nodeProperties = list(list(property = "CMName", description = "Name")),
          usesProperties = list(list(property = "Key", description = "Expression"))
        ))
      }
      stop(endpoint)
    },
    .package = "CatMapR"
  )

  domains <- CatMapR::get_domains(database = "SocioMap")
  expect_true(all(c("domain", "subdomain", "description") %in% names(domains)))

  props <- CatMapR::get_properties(database = "ArchaMap")
  expect_true(all(c("nodeID", "CMName", "property", "value") %in% names(props)))

  upload_props <- CatMapR::get_upload_properties(database = "ArchaMap")
  expect_true(is.list(upload_props))
  expect_true(all(c("database", "nodeProperties", "usesProperties") %in% names(upload_props)))
})

test_that("merge template wrappers hit correct endpoints", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$request <- request
      captured$parameters <- parameters
      list(ok = TRUE)
    },
    .package = "CatMapR"
  )

  CatMapR::get_merge_template(database = "ArchaMap", dataset_id = "AD947")
  expect_identical(captured$endpoint, "merge/template/ArchaMap/AD947")
  expect_identical(captured$request, "GET")

  CatMapR::get_merge_template_summary(database = "ArchaMap", cmid = "AMM1")
  expect_identical(captured$endpoint, "merge/template/summary/ArchaMap/AMM1")
  expect_identical(captured$request, "GET")

  CatMapR::build_merge_syntax(
    template = data.frame(mergingID = "M1", datasetID = "D1", filePath = "/tmp/x.csv", stringsAsFactors = FALSE),
    database = "ArchaMap"
  )
  expect_identical(captured$endpoint, "merge/syntax/ArchaMap")
  expect_identical(captured$request, "POST")
})

test_that("resolve_api_key supports preferred and legacy env vars", {
  original_new <- Sys.getenv("CATMAPR_API_KEY", unset = NA_character_)
  original_legacy <- Sys.getenv("CATMAPPER_API_KEY", unset = NA_character_)
  on.exit({
    if (is.na(original_new)) Sys.unsetenv("CATMAPR_API_KEY") else Sys.setenv(CATMAPR_API_KEY = original_new)
    if (is.na(original_legacy)) Sys.unsetenv("CATMAPPER_API_KEY") else Sys.setenv(CATMAPPER_API_KEY = original_legacy)
  }, add = TRUE)

  Sys.unsetenv("CATMAPR_API_KEY")
  Sys.setenv(CATMAPPER_API_KEY = "legacy-key")
  expect_identical(CatMapR:::resolve_api_key(NULL), "legacy-key")
})

test_that("upload_rows requires api key", {
  original <- Sys.getenv("CATMAPR_API_KEY", unset = NA_character_)
  on.exit({
    if (is.na(original)) Sys.unsetenv("CATMAPR_API_KEY") else Sys.setenv(CATMAPR_API_KEY = original)
  }, add = TRUE)
  Sys.unsetenv("CATMAPR_API_KEY")
  Sys.unsetenv("CATMAPPER_API_KEY")

  expect_error(
    CatMapR::upload_rows(df = data.frame(), database = "SocioMap", form_data = list()),
    "API key is required",
    fixed = TRUE
  )
})

test_that("upload_rows sends standard mode payload, polls status, and triggers waiting-uses refresh", {
  captured <- new.env(parent = emptyenv())
  captured$endpoints <- character(0)
  captured$refresh_calls <- 0L

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", headers = NULL, ...) {
      captured$endpoints <- c(captured$endpoints, endpoint)
      if (endpoint == "uploadInputNodes") {
        captured$start_parameters <- parameters
        captured$headers <- headers
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(list(
          taskId = "task-123",
          status = "completed",
          file = list(list(CMID = "SM1", Key = "Type == Adamana Brown", datasetID = "SD1")),
          order = c("CMID", "Key", "datasetID")
        ))
      }
      if (endpoint == "updateWaitingUSES") {
        captured$refresh_calls <- captured$refresh_calls + 1L
        return(list(ok = TRUE))
      }
      stop(endpoint)
    },
    .package = "CatMapR"
  )

  rows <- data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    CMID = "",
    Key = "Type == Adamana Brown",
    datasetID = "SD1",
    label = "ETHNICITY",
    variable = "CeramicType",
    stringsAsFactors = FALSE
  )

  result <- CatMapR::upload_rows(
    df = rows,
    database = "SocioMap",
    form_data = list(
      domain = "ETHNICITY",
      subdomain = "ETHNICITY",
      datasetID = "SD1",
      cmNameColumn = "CMName",
      categoryNamesColumn = "Name",
      cmidColumn = "CMID",
      keyColumn = "Key"
    ),
    action = "add_uses",
    properties = c("variable"),
    api_key = "cmk_abc123",
    poll_interval_seconds = 0.001,
    timeout_seconds = 1
  )

  expect_s3_class(result, "data.frame")
  expect_identical(captured$start_parameters$so, "standard")
  expect_identical(captured$start_parameters$ao, "add_uses")
  expect_identical(captured$start_parameters$optionalProperties, list("variable"))
  expect_identical(captured$headers[["X-API-Key"]], "cmk_abc123")
  expect_identical(captured$refresh_calls, 1L)
})

test_that("upload_rows suppresses waiting-uses refresh errors", {
  captured <- new.env(parent = emptyenv())
  captured$endpoints <- character(0)

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", headers = NULL, ...) {
      captured$endpoints <- c(captured$endpoints, endpoint)
      if (endpoint == "uploadInputNodes") {
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(list(taskId = "task-123", status = "completed", file = list(list(CMID = "SM1")), order = c("CMID")))
      }
      if (endpoint == "updateWaitingUSES") {
        stop("refresh failed")
      }
      stop(endpoint)
    },
    .package = "CatMapR"
  )

  out <- CatMapR::upload_rows(
    df = data.frame(
      CMName = "Yoruba",
      Name = "Yoruba",
      CMID = "",
      Key = "Type == Adamana Brown",
      datasetID = "SD1",
      label = "ETHNICITY",
      stringsAsFactors = FALSE
    ),
    database = "SocioMap",
    form_data = list(
      domain = "ETHNICITY",
      subdomain = "ETHNICITY",
      datasetID = "SD1",
      cmNameColumn = "CMName",
      categoryNamesColumn = "Name",
      cmidColumn = "CMID",
      keyColumn = "Key"
    ),
    action = "add_uses",
    api_key = "cmk_abc123",
    poll_interval_seconds = 0.001,
    timeout_seconds = 1
  )

  expect_s3_class(out, "data.frame")
  expect_true("updateWaitingUSES" %in% captured$endpoints)
})

test_that("prepare_upload_rows validates action-required columns", {
  expect_error(
    CatMapR::prepare_upload_rows(
      df = data.frame(
        CMName = "Yoruba",
        Name = "Yoruba",
        CMID = "SM1",
        Key = "Type == Adamana Brown",
        stringsAsFactors = FALSE
      ),
      database = "SocioMap",
      form_data = list(
        domain = "ETHNICITY",
        subdomain = "ETHNICITY",
        datasetID = "SD1",
        cmNameColumn = "CMName",
        categoryNamesColumn = "Name",
        cmidColumn = "CMID",
        keyColumn = "Key"
      ),
      action = "add_uses"
    ),
    "Required upload column(s) missing",
    fixed = TRUE
  )
})

test_that("key helpers build and normalize expressions", {
  expect_identical(CatMapR::build_key("Type", "Adamana Brown"), "Type == Adamana Brown")
  rows <- data.frame(
    Type = c("Adamana Brown", "Kayenta"),
    Region = c("Flagstaff", "Winslow"),
    stringsAsFactors = FALSE
  )
  keyed <- CatMapR::build_key_from_columns(rows, c("Type", "Region"))
  expect_identical(
    keyed$Key,
    c(
      "Type == Adamana Brown && Region == Flagstaff",
      "Type == Kayenta && Region == Winslow"
    )
  )
  expect_identical(
    CatMapR::normalize_key("Key == Region == Flagstaff"),
    "Region == Flagstaff"
  )
  expect_true(CatMapR::is_normalized_key("Region == Flagstaff"))
  expect_false(CatMapR::is_normalized_key("Key == Region == Flagstaff"))
})
