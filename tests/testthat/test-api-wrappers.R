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
