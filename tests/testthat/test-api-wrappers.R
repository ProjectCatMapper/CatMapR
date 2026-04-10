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

test_that("getMergingTemplate calls canonical template endpoint and normalizes rows", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(
        list(
          mergingID = "AD354277",
          mergingCMName = "Becoming Hopi merge",
          mergingShortName = "BH merge",
          mergingCitation = "Citation",
          stackID = "",
          datasetID = "",
          datasetName = "",
          filePath = "Please enter the working directory as the first filepath"
        ),
        list(
          mergingID = "AD354277",
          mergingCMName = "Becoming Hopi merge",
          mergingShortName = "BH merge",
          mergingCitation = "Citation",
          stackID = "AS1",
          datasetID = "AD354273",
          datasetName = "Adobe Bricks",
          filePath = ""
        )
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getMergingTemplate(cmid = "AD354277", database = "ArchaMap")

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "merge/template/archamap/AD354277")
  expect_identical(captured$parameters, list())
  expect_identical(captured$request, "GET")
  expect_identical(
    names(result),
    c("mergingID", "mergingCMName", "mergingShortName", "mergingCitation", "stackID", "datasetID", "datasetName", "filePath")
  )
  expect_identical(result$datasetID[[2]], "AD354273")
})

test_that("getMergingTemplateSummary calls canonical summary endpoint and preserves transform fields", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(
        nodeType = "MERGING",
        stackSummary = list(
          list(
            stackID = "AS1",
            stackCMName = "Stack 1",
            datasetCount = 2,
            equivalenceTieCount = 8,
            keyReassignmentCount = 1,
            variableCount = 3
          )
        ),
        stackSummaryTotals = list(
          datasetCount = 2,
          equivalenceTieCount = 8,
          keyReassignmentCount = 1,
          variableCount = 3
        ),
        datasetSummary = list(),
        mergingTemplateCount = 0,
        mergingTies = list(
          list(
            mergingID = "AD354277",
            mergingCMName = "Becoming Hopi merge",
            stackID = "AS1",
            stackCMName = "Stack 1",
            relationship = "MERGING",
            targetLabels = c("VARIABLE", "UNIT"),
            targetCMID = "AV1",
            targetCMName = "Wall thickness",
            tieStackID = "AS1",
            varName = "wall_thickness",
            stackTransform = "[{\"op\":\"as_numeric\",\"target\":\"wall_thickness\"}]",
            datasetTransform = "[{\"op\":\"copy\",\"target\":\"wall_thickness\",\"sources\":[\"WallThick\"]}]",
            variableFilter = "[{\"op\":\"drop_na\",\"target\":\"wall_thickness\"}]",
            summaryStatistic = "mean",
            summaryFilter = NA_character_,
            summaryWeight = NA_character_
          )
        ),
        equivalenceTies = list(
          list(
            stackID = "AS1",
            datasetID = "AD354273",
            Key = "type == adobe",
            originalCMID = "AM1",
            originalCMName = "Adobe",
            equivalentCMID = "AM2",
            equivalentCMName = "Adobe brick",
            selfReference = FALSE
          )
        )
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getMergingTemplateSummary(cmid = "AD354277", database = "ArchaMap")

  expect_type(result, "list")
  expect_identical(captured$endpoint, "merge/template/summary/archamap/AD354277")
  expect_identical(captured$parameters, list())
  expect_identical(captured$request, "GET")
  expect_identical(result$nodeType, "MERGING")
  expect_s3_class(result$stackSummary, "data.frame")
  expect_s3_class(result$mergingTies, "data.frame")
  expect_identical(result$stackSummaryTotals$datasetCount, 2)
  expect_identical(result$mergingTies$targetLabels[[1]], c("VARIABLE", "UNIT"))
  expect_identical(result$mergingTies$variableFilter[[1]], "[{\"op\":\"drop_na\",\"target\":\"wall_thickness\"}]")
  expect_true(all(c("stackTransform", "datasetTransform", "variableFilter", "summaryFilter", "summaryWeight") %in% names(result$mergingTies)))
})

test_that("getUploadProperties preserves transform-related property metadata", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(
        database = "archamap",
        nodeProperties = list(),
        usesProperties = list(
          list(property = "stackTransform", description = "Stack-level transform"),
          list(property = "datasetTransform", description = "Dataset-level transform"),
          list(property = "variableFilter", description = "Filter applied before summary"),
          list(property = "summaryStatistic", description = "Summary function"),
          list(property = "summaryFilter", description = "Reserved summary filter"),
          list(property = "summaryWeight", description = "Reserved summary weight")
        )
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getUploadProperties(database = "ArchaMap")

  expect_identical(
    result$usesProperties$property,
    c("stackTransform", "datasetTransform", "variableFilter", "summaryStatistic", "summaryFilter", "summaryWeight")
  )
})

test_that("camelCase property wrappers surface API errors cleanly", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(error = "Not Found")
    },
    .package = "CatMapR"
  )

  expect_error(CatMapR::getMergingTemplate(cmid = "AD1", database = "ArchaMap"), "Not Found", fixed = TRUE)
  expect_error(CatMapR::getMergingTemplateSummary(cmid = "AD1", database = "ArchaMap"), "Not Found", fixed = TRUE)
})

test_that("uploadInputNodes simple mode warns and strips preformatted key expressions", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      captured$headers <- headers
      list(ok = TRUE)
    },
    .package = "CatMapR"
  )

  rows <- data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    Key = "language == yoruba",
    stringsAsFactors = FALSE
  )

  expect_warning(
    result <- CatMapR::uploadInputNodes(
      df = rows,
      database = "SocioMap",
      formData = list(
        domain = "ETHNICITY",
        subdomain = "ETHNICITY",
        datasetID = "SD1",
        cmNameColumn = "CMName",
        categoryNamesColumn = "Name",
        cmidColumn = "CMID",
        keyColumn = "Key"
      ),
      so = "simple",
      ao = "add_uses",
      api_key = "cmk_abc123"
    ),
    "`so = \"simple\"` expects raw key values",
    fixed = TRUE
  )

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$parameters$df[[1]]$Key, "yoruba")
})

test_that("uploadInputNodes simple mode rejects compound key expressions", {
  captured <- new.env(parent = emptyenv())
  captured$called <- FALSE

  local_mocked_bindings(
    callAPI = function(...) {
      captured$called <- TRUE
      list(ok = TRUE)
    },
    .package = "CatMapR"
  )

  rows <- data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    Key = "language == yoruba && country == ng",
    stringsAsFactors = FALSE
  )

  expect_error(
    CatMapR::uploadInputNodes(
      df = rows,
      database = "SocioMap",
      formData = list(
        domain = "ETHNICITY",
        subdomain = "ETHNICITY",
        datasetID = "SD1",
        cmNameColumn = "CMName",
        categoryNamesColumn = "Name",
        cmidColumn = "CMID",
        keyColumn = "Key"
      ),
      so = "simple",
      ao = "add_uses",
      api_key = "cmk_abc123"
    ),
    "must use `so = \"standard\"`",
    fixed = TRUE
  )

  expect_false(captured$called)
})

test_that("updateWaitingUSES uses env API key when api_key argument is omitted", {
  original <- Sys.getenv("CATMAPR_API_KEY", unset = NA_character_)
  on.exit({
    if (is.na(original)) {
      Sys.unsetenv("CATMAPR_API_KEY")
    } else {
      Sys.setenv(CATMAPR_API_KEY = original)
    }
  }, add = TRUE)
  Sys.setenv(CATMAPR_API_KEY = "env-key")

  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$headers <- headers
      list(ok = TRUE)
    },
    .package = "CatMapR"
  )

  result <- CatMapR::updateWaitingUSES(database = "ArchaMap")

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "updateWaitingUSES")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$database, "ArchaMap")
  expect_identical(captured$headers[["X-API-Key"]], "env-key")
})

test_that("uploadInputNodesStatus posts taskId and cursor with API-key auth", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$headers <- headers
      list(taskId = "abc123", status = "running", nextCursor = 4)
    },
    .package = "CatMapR"
  )

  result <- CatMapR::uploadInputNodesStatus(
    task_id = "abc123",
    cursor = 3,
    api_key = "cmk_status_key"
  )

  expect_identical(captured$endpoint, "uploadInputNodesStatus")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters, list(taskId = "abc123", cursor = 3L))
  expect_identical(captured$headers[["X-API-Key"]], "cmk_status_key")
  expect_identical(result$status, "running")
})

test_that("waitForUploadTask polls until completion", {
  captured <- new.env(parent = emptyenv())
  captured$cursors <- integer(0)

  local_mocked_bindings(
    uploadInputNodesStatus = function(task_id, cursor = 0L, api_key = NULL, url = NULL) {
      captured$cursors <- c(captured$cursors, cursor)
      if (length(captured$cursors) == 1) {
        return(list(
          taskId = task_id,
          status = "running",
          events = list("batch 1"),
          nextCursor = 1
        ))
      }
      list(
        taskId = task_id,
        status = "completed",
        events = list("done"),
        nextCursor = 2,
        file = data.frame(CMID = "AD1", stringsAsFactors = FALSE)
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::waitForUploadTask(
    task_id = "abc123",
    poll_seconds = 0.001,
    timeout_seconds = 1,
    quiet = TRUE
  )

  expect_identical(captured$cursors, c(0L, 1L))
  expect_identical(result$status, "completed")
  expect_identical(result$nextCursor, 2)
})

test_that("submitEditUpload executes upload then waiting-uses refresh", {
  captured <- new.env(parent = emptyenv())
  captured$calls <- character(0)

  local_mocked_bindings(
    uploadInputNodes = function(...) {
      captured$calls <- c(captured$calls, "upload")
      list(step = "upload")
    },
    updateWaitingUSES = function(...) {
      captured$calls <- c(captured$calls, "waiting")
      list(step = "waiting")
    },
    .package = "CatMapR"
  )

  result <- CatMapR::submitEditUpload(
    df = data.frame(CMName = "Yoruba", stringsAsFactors = FALSE),
    database = "SocioMap",
    formData = list(
      domain = "ETHNICITY",
      subdomain = "ETHNICITY",
      datasetID = "SD1",
      cmNameColumn = "CMName",
      categoryNamesColumn = "Name",
      cmidColumn = "CMID",
      keyColumn = "Key"
    ),
    ao = "add_uses",
    api_key = "cmk_abc123"
  )

  expect_identical(captured$calls, c("upload", "waiting"))
  expect_identical(result$upload$step, "upload")
  expect_identical(result$waiting_uses$step, "waiting")
})
