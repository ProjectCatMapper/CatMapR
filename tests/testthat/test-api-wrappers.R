test_that("allDatasets uses expected endpoint and query parameters", {
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

  result <- CatMapR::allDatasets(database = "SocioMap")

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "allDatasets")
  expect_identical(captured$request, "GET")
  expect_identical(captured$parameters, list(database = "SocioMap"))
})

test_that("allDatasets validates database values", {
  expect_error(
    CatMapR::allDatasets(database = "UnknownMap"),
    "`database` must be one of",
    fixed = TRUE
  )
})

test_that("listDatasetMetadata is a behavior-compatible alias of allDatasets", {
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

  result <- CatMapR::listDatasetMetadata(database = "SocioMap")

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "allDatasets")
  expect_identical(captured$request, "GET")
  expect_identical(captured$parameters, list(database = "SocioMap"))
})

test_that("datasetInfo includes domain and children parameters", {
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

  result <- CatMapR::datasetInfo(
    database = "ArchaMap",
    CMID = "AD1",
    domain = "CATEGORY",
    children = TRUE
  )

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "dataset")
  expect_identical(captured$request, "GET")
  expect_identical(
    captured$parameters,
    list(database = "ArchaMap", cmid = "AD1", domain = "CATEGORY", children = TRUE)
  )
})

test_that("getDatasetMetadata is a behavior-compatible alias of datasetInfo", {
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

  result <- CatMapR::getDatasetMetadata(
    database = "ArchaMap",
    CMID = "AD1",
    domain = "CATEGORY",
    children = TRUE
  )

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "dataset")
  expect_identical(captured$request, "GET")
  expect_identical(
    captured$parameters,
    list(database = "ArchaMap", cmid = "AD1", domain = "CATEGORY", children = TRUE)
  )
})

test_that("datasetInfo validates optional scalar children", {
  expect_error(
    CatMapR::datasetInfo(database = "SocioMap", CMID = "SD1", children = c(TRUE, FALSE)),
    "`children` must be TRUE or FALSE.",
    fixed = TRUE
  )
})

test_that("searchDatabase forwards modern search parameters", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(data = data.frame(), count = list())
    },
    .package = "CatMapR"
  )

  result <- CatMapR::searchDatabase(
    database = "SocioMap",
    domain = "ETHNICITY",
    term = "Dan",
    property = "Name",
    yearStart = 1900,
    yearEnd = 2000,
    country = "SM1",
    context = "SM2",
    dataset = "SD1",
    query = "false",
    limit = 250
  )

  expect_type(result, "list")
  expect_identical(captured$endpoint, "search")
  expect_identical(captured$request, "GET")
  expect_identical(captured$parameters$dataset, "SD1")
  expect_identical(captured$parameters$query, "false")
  expect_identical(captured$parameters$limit, 250)
})

test_that("searchDatabase validates query and limit inputs", {
  expect_error(
    CatMapR::searchDatabase(database = "SocioMap", query = "maybe"),
    "`query` must be one of: true, false.",
    fixed = TRUE
  )

  expect_error(
    CatMapR::searchDatabase(database = "SocioMap", query = "false", limit = 0),
    "`limit` must be a positive number.",
    fixed = TRUE
  )
})

test_that("translate uses /translate endpoint and includes options", {
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

  input <- data.frame(period = "Archaic", stringsAsFactors = FALSE)

  result <- CatMapR::translate(
    rows = input,
    database = "ArchaMap",
    term = "period",
    property = "Name",
    domain = c("PERIOD", "CATEGORY"),
    context = "AM1",
    country = "AM2",
    dataset = "AD1",
    yearStart = 500,
    yearEnd = 700,
    key = "true",
    query = "false",
    countsamename = TRUE,
    uniqueRows = TRUE
  )

  expect_true(is.list(result))
  expect_identical(captured$endpoint, "translate")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$domain, "PERIOD")
  expect_identical(captured$parameters$countsamename, TRUE)
  expect_identical(captured$parameters$uniqueRows, TRUE)
})

test_that("translate validates key/query flags", {
  input <- data.frame(period = "Archaic", stringsAsFactors = FALSE)

  expect_error(
    CatMapR::translate(
      rows = input,
      database = "ArchaMap",
      term = "period",
      key = "1"
    ),
    "`key` must be one of: true, false.",
    fixed = TRUE
  )
})

test_that("createLinkfile formats dataset choices for proposeMergeSubmit", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      data.frame(CMID = "SM1")
    },
    .package = "CatMapR"
  )

  result <- CatMapR::createLinkfile(
    categoryLabel = c("ETHNICITY", "LANGUAGE"),
    datasetChoices = c("SD5", "SD6"),
    database = "SocioMap",
    intersection = FALSE,
    equivalence = "standard",
    mergelevel = 2,
    resultFormat = "key-to-key",
    selectedKeyvariable = list()
  )

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "proposeMergeSubmit")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$categoryLabel, "ETHNICITY")
  expect_identical(captured$parameters$datasetChoices, "SD5,SD6")
  expect_identical(captured$parameters$equivalence, "standard")
})

test_that("createLinkfile validates logical intersection", {
  expect_error(
    CatMapR::createLinkfile(
      categoryLabel = "ETHNICITY",
      datasetChoices = c("SD5", "SD6"),
      database = "SocioMap",
      intersection = NA
    ),
    "`intersection` must be TRUE or FALSE.",
    fixed = TRUE
  )
})

test_that("joinDatasets includes domain in post payload", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      data.frame(CMID = "SM1")
    },
    .package = "CatMapR"
  )

  join_left <- data.frame(datasetID = "SD1", GID = "AFG", stringsAsFactors = FALSE)
  join_right <- data.frame(datasetID = "SD2", geonameid = "1149361", stringsAsFactors = FALSE)

  result <- CatMapR::joinDatasets(
    database = "SocioMap",
    joinLeft = join_left,
    joinRight = join_right,
    domain = "CATEGORY"
  )

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "joinDatasets")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$domain, "CATEGORY")
})

test_that("CATMAPR_API_URL controls default API URL resolution", {
  original <- Sys.getenv("CATMAPR_API_URL", unset = NA_character_)
  on.exit({
    if (is.na(original)) {
      Sys.unsetenv("CATMAPR_API_URL")
    } else {
      Sys.setenv(CATMAPR_API_URL = original)
    }
  }, add = TRUE)

  Sys.unsetenv("CATMAPR_API_URL")
  expect_identical(
    CatMapR:::resolve_api_url(NULL),
    "https://api.catmapper.org"
  )

  Sys.setenv(CATMAPR_API_URL = "https://example.org/custom-api")
  expect_identical(
    CatMapR:::resolve_api_url(NULL),
    "https://example.org/custom-api"
  )

  expect_identical(
    CatMapR:::resolve_api_url("https://override.example.org/api"),
    "https://override.example.org/api"
  )
})

test_that("callAPI accepts 2xx responses and surfaces non-2xx errors", {
  local_mocked_bindings(
    GET = function(url, query = NULL, ...) {
      structure(list(status_code = 201L, body = '{"ok":true}'), class = 'response')
    },
    content = function(x, as = 'text', encoding = 'UTF-8', ...) x$body,
    .package = 'httr'
  )

  expect_equal(
    CatMapR:::callAPI(endpoint = 'search', parameters = list(), request = 'GET'),
    list(ok = TRUE)
  )

  local_mocked_bindings(
    GET = function(url, query = NULL, ...) {
      structure(list(status_code = 404L, body = '{"error":"Not Found"}'), class = 'response')
    },
    content = function(x, as = 'text', encoding = 'UTF-8', ...) x$body,
    .package = 'httr'
  )

  expect_error(
    CatMapR:::callAPI(endpoint = 'search', parameters = list(), request = 'GET'),
    'Not Found',
    fixed = TRUE
  )
})

test_that("CMIDinfo uses REST-style CMID/database/cmid endpoint", {
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

  result <- CatMapR::CMIDinfo(database = "SocioMap", cmid = "SM1")

  expect_equal(result, list(ok = TRUE))
  expect_identical(captured$endpoint, "CMID/SocioMap/SM1")
  expect_identical(captured$request, "GET")
  expect_identical(captured$parameters, list())
})

test_that("getDomains returns simplified domain metadata by default", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      list(
        list(group = "DISTRICT", nodes = list(c("ADM0", "ADM1")), description = "Administrative district"),
        list(group = "ETHNICITY", nodes = list("ETHNICITY"), description = "Ethnicity category")
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getDomains(database = "SocioMap")

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "getTranslatedomains")
  expect_identical(captured$request, "GET")
  expect_identical(captured$parameters, list(database = "SocioMap"))
  expect_identical(names(result), c("domain", "subdomain", "description"))
  expect_identical(result$domain, c("DISTRICT", "DISTRICT", "ETHNICITY"))
  expect_identical(result$subdomain, c("ADM0", "ADM1", "ETHNICITY"))
  expect_identical(
    result$description,
    c("Administrative district", "Administrative district", "Ethnicity category")
  )
})

test_that("getDomains returns richer metadata when advanced is TRUE", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      data.frame(
        group = c("DISTRICT", "LANGUOID"),
        nodes = I(list(c("ADM0", "ADM1"), c("LANGUAGE", "DIALECT"))),
        description = c("Administrative district", "Language grouping"),
        public = c(TRUE, FALSE),
        stringsAsFactors = FALSE
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getDomains(database = "SocioMap", advanced = TRUE)

  expect_true(all(c("domain", "subdomain", "description", "public") %in% names(result)))
  expect_identical(result$domain, c("DISTRICT", "DISTRICT", "LANGUOID", "LANGUOID"))
  expect_identical(result$subdomain, c("ADM0", "ADM1", "LANGUAGE", "DIALECT"))
  expect_identical(result$public, c(TRUE, TRUE, FALSE, FALSE))
})

test_that("getDomains adds missing descriptions and validates advanced", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(list(group = "DISTRICT", nodes = list(c("ADM0", "ADM1"))))
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getDomains(database = "SocioMap")

  expect_identical(names(result), c("domain", "subdomain", "description"))
  expect_true(all(is.na(result$description)))

  expect_error(
    CatMapR::getDomains(database = "SocioMap", advanced = NA),
    "`advanced` must be TRUE or FALSE.",
    fixed = TRUE
  )
})

test_that("getProperties calls canonical properties endpoint and returns table", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      list(
        database = "archamap",
        table = list(
          list(nodeID = "CP1", CMName = "country", property = "CMName", value = "country"),
          list(nodeID = "CP1", CMName = "country", property = "type", value = "relationship")
        )
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getProperties(database = "ArchaMap")

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "metadata/properties/archamap")
  expect_identical(captured$parameters, list())
  expect_identical(captured$request, "GET")
  expect_identical(names(result), c("nodeID", "CMName", "property", "value"))
  expect_identical(result$CMName, c("country", "country"))
  expect_identical(result$property, c("CMName", "type"))
})

test_that("getProperties handles empty or bare table responses", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(database = "sociomap", table = list())
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getProperties(database = "SocioMap")
  expect_s3_class(result, "data.frame")
  expect_identical(names(result), c("nodeID", "CMName", "property", "value"))
  expect_identical(nrow(result), 0L)

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(nodeID = "CP2", CMName = "yearStart", property = "property", value = "yearStart")
    },
    .package = "CatMapR"
  )

  bare <- CatMapR::getProperties(database = "SocioMap")
  expect_identical(nrow(bare), 1L)
  expect_identical(bare$CMName, "yearStart")
})

test_that("getUploadProperties calls canonical upload properties endpoint", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      list(
        database = "archamap",
        nodeProperties = list(
          list(property = "DatasetCitation", description = "Dataset citation")
        ),
        usesProperties = list(
          list(property = "yearStart", description = "Starting date")
        )
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getUploadProperties(database = "ArchaMap")

  expect_type(result, "list")
  expect_identical(captured$endpoint, "metadata/uploadProperties/archamap")
  expect_identical(captured$parameters, list())
  expect_identical(captured$request, "GET")
  expect_identical(result$database, "archamap")
  expect_s3_class(result$nodeProperties, "data.frame")
  expect_s3_class(result$usesProperties, "data.frame")
  expect_identical(result$nodeProperties$property, "DatasetCitation")
  expect_identical(result$usesProperties$property, "yearStart")
})

test_that("getUploadProperties fills missing descriptions and defaults database", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(
        nodeProperties = list(list(property = "shortName")),
        usesProperties = list()
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getUploadProperties(database = "SocioMap")

  expect_identical(result$database, "SocioMap")
  expect_true(all(c("property", "description") %in% names(result$nodeProperties)))
  expect_true(is.na(result$nodeProperties$description[[1]]))
  expect_identical(nrow(result$usesProperties), 0L)
})

test_that("property wrappers surface API errors cleanly", {
  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", ...) {
      list(error = "Not Found")
    },
    .package = "CatMapR"
  )

  expect_error(CatMapR::getProperties(database = "ArchaMap"), "Not Found", fixed = TRUE)
  expect_error(CatMapR::getUploadProperties(database = "ArchaMap"), "Not Found", fixed = TRUE)
})

test_that("uploadInputNodes requires API key", {
  original <- Sys.getenv("CATMAPR_API_KEY", unset = NA_character_)
  on.exit({
    if (is.na(original)) {
      Sys.unsetenv("CATMAPR_API_KEY")
    } else {
      Sys.setenv(CATMAPR_API_KEY = original)
    }
  }, add = TRUE)

  Sys.unsetenv("CATMAPR_API_KEY")

  expect_error(
    CatMapR::uploadInputNodes(df = data.frame(), database = "SocioMap", formData = list()),
    "API key is required",
    fixed = TRUE
  )
})

test_that("uploadInputNodes polls task status and returns server dataframe", {
  captured <- new.env(parent = emptyenv())
  captured$calls <- character(0)

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$calls <- c(captured$calls, endpoint)
      if (endpoint == "uploadInputNodes") {
        captured$start_parameters <- parameters
        captured$headers <- headers
        captured$request <- request
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(
          list(
            taskId = "task-123",
            status = "completed",
            nextCursor = 1,
            waitingUsesTask = "wait-1",
            file = list(list(CMID = "SM100", Key = "Type == Adamana Brown", variable = "CeramicType")),
            order = c("CMID", "Key", "variable")
          )
        )
      }
      stop(sprintf("Unexpected endpoint: %s", endpoint), call. = FALSE)
    },
    .package = "CatMapR"
  )

  rows <- data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    Key = "eth:yoruba",
    stringsAsFactors = FALSE
  )

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
    allContext = c("Name"),
    api_key = "cmk_abc123",
    poll_interval_seconds = 0.001,
    timeout_seconds = 1
  )

  expect_s3_class(result, "data.frame")
  expect_identical(names(result), c("CMID", "Key", "variable"))
  expect_identical(result$CMID[[1]], "SM100")
  expect_identical(captured$calls, c("uploadInputNodes", "uploadInputNodesStatus"))
  expect_identical(captured$request, "POST")
  expect_identical(captured$headers[["X-API-Key"]], "cmk_abc123")
  expect_identical(captured$start_parameters$so, "simple")
  expect_identical(captured$start_parameters$ao, "add_uses")
  expect_identical(captured$start_parameters$database, "SocioMap")
  expect_identical(captured$start_parameters$df[[1]]$CMName, "Yoruba")
  expect_identical(captured$start_parameters$addoptions, list(district = FALSE, recordyear = FALSE))
  expect_identical(captured$start_parameters$allContext, list("Name"))
})

test_that("uploadInputNodes validates allContext and optionalProperties", {
  expect_error(
    CatMapR::uploadInputNodes(
      df = data.frame(CMName = "Yoruba", stringsAsFactors = FALSE),
      database = "SocioMap",
      formData = list(),
      allContext = TRUE,
      api_key = "cmk_abc123"
    ),
    "`allContext` must be NULL, a character vector, or a list.",
    fixed = TRUE
  )

  expect_error(
    CatMapR::uploadInputNodes(
      df = data.frame(CMName = "Yoruba", stringsAsFactors = FALSE),
      database = "SocioMap",
      formData = list(),
      optionalProperties = TRUE,
      api_key = "cmk_abc123"
    ),
    "`optionalProperties` must be NULL, a character vector, or a list.",
    fixed = TRUE
  )
})

test_that("uploadInputNodes simple mode only supports add_uses", {
  expect_error(
    CatMapR::uploadInputNodes(
      df = data.frame(CMName = "Yoruba", Name = "Yoruba", Key = "eth:yoruba", stringsAsFactors = FALSE),
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
      ao = "update_add",
      api_key = "cmk_abc123"
    ),
    "only supported when `ao = \"add_uses\"`",
    fixed = TRUE
  )
})

test_that("uploadInputNodes simple mode rejects preformatted key expressions", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$called <- TRUE
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
    "include preformatted key expressions",
    fixed = TRUE
  )
  expect_false(isTRUE(captured$called))
})

test_that("uploadInputNodes standard mode accepts preformatted composite keys", {
  captured <- new.env(parent = emptyenv())
  captured$calls <- character(0)

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$calls <- c(captured$calls, endpoint)
      if (endpoint == "uploadInputNodes") {
        captured$key <- parameters$df[[1]]$Key
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(list(taskId = "task-123", status = "completed", file = list(list(CMID = "SM1")), order = c("CMID")))
      }
      stop(sprintf("Unexpected endpoint: %s", endpoint), call. = FALSE)
    },
    .package = "CatMapR"
  )

  rows <- data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    CMID = "SM1",
    Key = "language == yoruba && country == ng",
    datasetID = "SD1",
    stringsAsFactors = FALSE
  )

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
      so = "standard",
      ao = "add_uses",
      api_key = "cmk_abc123",
      poll_interval_seconds = 0.001,
      timeout_seconds = 1
  )
  expect_s3_class(result, "data.frame")
  expect_identical(captured$calls, c("uploadInputNodes", "uploadInputNodesStatus"))
  expect_identical(captured$key, "language == yoruba && country == ng")
})

test_that("uploadInputNodes times out when task does not complete", {
  rows <- data.frame(
    CMName = "Yoruba",
    Name = "Yoruba",
    Key = "eth:yoruba",
    stringsAsFactors = FALSE
  )

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      if (endpoint == "uploadInputNodes") {
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(list(taskId = "task-123", status = "running", nextCursor = 0))
      }
      stop(sprintf("Unexpected endpoint: %s", endpoint), call. = FALSE)
    },
    .package = "CatMapR"
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
      api_key = "cmk_abc123",
      poll_interval_seconds = 0.001,
      timeout_seconds = 0.01
    ),
    "Timed out waiting for upload task",
    fixed = TRUE
  )
})

test_that("resolve_api_key supports CATMAPPER_API_KEY fallback", {
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

test_that("submitEditUpload skips extra waiting-USES trigger when task id already present", {
  captured <- new.env(parent = emptyenv())
  captured$endpoints <- character(0)

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoints <- c(captured$endpoints, endpoint)
      if (endpoint == "uploadInputNodes") {
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(
          list(
            taskId = "task-123",
            status = "completed",
            waitingUsesTask = "wait-1",
            file = list(list(CMID = "SM1", variable = "CeramicType")),
            order = c("CMID", "variable")
          )
        )
      }
      stop(sprintf("Unexpected endpoint: %s", endpoint), call. = FALSE)
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
      categoryNamesColumn = "CMName",
      cmidColumn = "CMID",
      keyColumn = "CMName"
    ),
    so = "simple",
    ao = "add_uses",
    api_key = "cmk_example",
    poll_interval_seconds = 0.001,
    timeout_seconds = 1
  )

  expect_s3_class(result, "data.frame")
  expect_identical(result$CMID[[1]], "SM1")
  expect_identical(
    captured$endpoints,
    c("uploadInputNodes", "uploadInputNodesStatus")
  )
})

test_that("submitEditUpload fire-and-forget triggers updateWaitingUSES when waiting task id absent", {
  captured <- new.env(parent = emptyenv())
  captured$endpoints <- character(0)
  captured$update_headers <- NULL

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoints <- c(captured$endpoints, endpoint)
      if (endpoint == "uploadInputNodes") {
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(list(taskId = "task-123", status = "completed", file = list(list(CMID = "SM1")), order = c("CMID")))
      }
      if (endpoint == "updateWaitingUSES") {
        captured$update_headers <- headers
        return(list(ok = TRUE))
      }
      stop(sprintf("Unexpected endpoint: %s", endpoint), call. = FALSE)
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
      categoryNamesColumn = "CMName",
      cmidColumn = "CMID",
      keyColumn = "CMName"
    ),
    so = "simple",
    ao = "add_uses",
    api_key = "cmk_example",
    poll_interval_seconds = 0.001,
    timeout_seconds = 1
  )

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoints, c("uploadInputNodes", "uploadInputNodesStatus", "updateWaitingUSES"))
  expect_null(captured$update_headers)
})

test_that("submitEditUpload warns but succeeds when waiting-USES trigger fails", {
  captured <- new.env(parent = emptyenv())
  captured$endpoints <- character(0)

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoints <- c(captured$endpoints, endpoint)
      if (endpoint == "uploadInputNodes") {
        return(list(taskId = "task-123", status = "queued"))
      }
      if (endpoint == "uploadInputNodesStatus") {
        return(list(taskId = "task-123", status = "completed", file = list(list(CMID = "SM1")), order = c("CMID")))
      }
      if (endpoint == "updateWaitingUSES") {
        stop("trigger unavailable")
      }
      stop(sprintf("Unexpected endpoint: %s", endpoint), call. = FALSE)
    },
    .package = "CatMapR"
  )

  expect_warning(
    result <- CatMapR::submitEditUpload(
      df = data.frame(CMName = "Yoruba", stringsAsFactors = FALSE),
      database = "SocioMap",
      formData = list(
        domain = "ETHNICITY",
        subdomain = "ETHNICITY",
        datasetID = "SD1",
        cmNameColumn = "CMName",
        categoryNamesColumn = "CMName",
        cmidColumn = "CMID",
        keyColumn = "CMName"
      ),
      so = "simple",
      ao = "add_uses",
      api_key = "cmk_example",
      poll_interval_seconds = 0.001,
      timeout_seconds = 1
    ),
    "Failed to trigger waiting-USES refresh",
    fixed = TRUE
  )

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoints, c("uploadInputNodes", "uploadInputNodesStatus", "updateWaitingUSES"))
})

test_that("prepare_edit_upload validates mapped formData columns for standard mode", {
  expect_error(
    CatMapR::prepare_edit_upload(
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
      so = "standard",
      ao = "add_uses"
    ),
    "Mapped formData column(s) not found",
    fixed = TRUE
  )
})

test_that("key helper functions normalize and validate keys", {
  expect_identical(CatMapR::build_key("Type", "Adamana Brown"), "Type == Adamana Brown")
  expect_identical(
    CatMapR::normalize_key("Key == Region == Flagstaff"),
    "Region == Flagstaff"
  )
  expect_true(CatMapR::is_normalized_key("Region == Flagstaff"))
  expect_false(CatMapR::is_normalized_key("Key == Region == Flagstaff"))
})

test_that("getMergingTemplate calls merge template endpoint", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      data.frame(mergingID = "M1", datasetID = "D1", stringsAsFactors = FALSE)
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getMergingTemplate(database = "ArchaMap", datasetID = "AD947")

  expect_s3_class(result, "data.frame")
  expect_identical(captured$endpoint, "merge/template/ArchaMap/AD947")
  expect_identical(captured$parameters, list())
  expect_identical(captured$request, "GET")
})

test_that("getMergingTemplateSummary calls merge summary endpoint", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      list(nodeType = "MERGING", mergingTies = data.frame())
    },
    .package = "CatMapR"
  )

  result <- CatMapR::getMergingTemplateSummary(database = "ArchaMap", cmid = "AMM1")

  expect_type(result, "list")
  expect_identical(captured$endpoint, "merge/template/summary/ArchaMap/AMM1")
  expect_identical(captured$parameters, list())
  expect_identical(captured$request, "GET")
})

test_that("createMergeSyntax posts template rows without API-key headers", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, headers = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      captured$headers <- headers
      list(msg = "Syntax created successfully", download = list(hash = "abc123"))
    },
    .package = "CatMapR"
  )

  template <- data.frame(
    mergingID = "M1",
    datasetID = "D1",
    filePath = "/mnt/storage/app/example.csv",
    stringsAsFactors = FALSE
  )

  result <- CatMapR::createMergeSyntax(template = template, database = "ArchaMap")

  expect_type(result, "list")
  expect_identical(captured$endpoint, "merge/syntax/ArchaMap")
  expect_identical(captured$request, "POST")
  expect_null(captured$headers)
  expect_identical(captured$parameters$template[[1]]$mergingID, "M1")
  expect_identical(result$download$hash, "abc123")
})
