test_that("findMergingTemplate combines template rows and summary status", {
  local_mocked_bindings(
    getMergingTemplate = function(cmid, database = "SocioMap", url = NULL) {
      data.frame(
        mergingID = c("AD957", "AD957"),
        mergingCMName = c("Test Merge", "Test Merge"),
        mergingShortName = c("TM", "TM"),
        mergingCitation = c("Citation", "Citation"),
        stackID = c("", "AD958"),
        datasetID = c("", "AD354274"),
        datasetName = c("", "Dataset A"),
        filePath = c("Please enter the working directory as the first filepath", ""),
        stringsAsFactors = FALSE
      )
    },
    getMergingTemplateSummary = function(cmid, database = "SocioMap", url = NULL) {
      list(
        nodeType = "MERGING",
        stackSummary = data.frame(),
        stackSummaryTotals = list(datasetCount = 1, categoryMergingTieCount = 3, keyReassignmentCount = 1, variableCount = 2),
        datasetSummary = data.frame(),
        mergingTemplateCount = 0,
        mergingTies = data.frame(),
        categoryMergingTies = data.frame(
          stackID = "AD958",
          datasetID = "AD354274",
          Key = "Site == AM1142",
          categoryCMID = "AM1142",
          categoryCMName = "Shared Site",
          stringsAsFactors = FALSE
        )
      )
    },
    .package = "CatMapR"
  )

  result <- CatMapR::findMergingTemplate(cmid = "AD957", database = "ArchaMap")

  expect_true(result$status$isMergingTemplate)
  expect_true(result$status$hasVariableMappings)
  expect_true(result$status$canDownloadLinkFile)
  expect_identical(result$status$variableCount, 2)
  expect_s3_class(result$template, "data.frame")
})

test_that("downloadMergingTemplateWorkbook writes the template workbook", {
  local_mocked_bindings(
    getMergingTemplate = function(cmid, database = "SocioMap", url = NULL) {
      data.frame(
        mergingID = c("AD957", "AD957"),
        mergingCMName = c("Test Merge", "Test Merge"),
        mergingShortName = c("TM", "TM"),
        mergingCitation = c("Citation", "Citation"),
        stackID = c("", "AD958"),
        datasetID = c("", "AD354274"),
        datasetName = c("", "Dataset A"),
        filePath = c("Please enter the working directory as the first filepath", ""),
        stringsAsFactors = FALSE
      )
    },
    .package = "CatMapR"
  )

  out_path <- file.path(tempdir(), "merging_template_AD957_test.xlsx")
  if (file.exists(out_path)) {
    unlink(out_path)
  }

  result <- CatMapR::downloadMergingTemplateWorkbook(
    cmid = "AD957",
    database = "ArchaMap",
    path = out_path,
    overwrite = TRUE
  )

  expect_true(file.exists(out_path))
  expect_identical(readxl::excel_sheets(out_path), "MergingTemplate")
  saved <- readxl::read_excel(out_path)
  expect_identical(saved$mergingID[[2]], "AD957")
  expect_identical(result$path, normalizePath(out_path, winslash = "/", mustWork = FALSE))
})

test_that("downloadLinkFileWorkbook writes long and wide link-file sheets", {
  local_mocked_bindings(
    findMergingTemplate = function(cmid, database = "SocioMap", url = NULL) {
      list(
        status = list(
          isMergingTemplate = TRUE,
          hasVariableMappings = FALSE,
          canDownloadLinkFile = TRUE
        ),
        template = data.frame(
          mergingID = c("AD957", "AD957", "AD957"),
          stackID = c("", "AD958", "AD959"),
          datasetID = c("", "AD354274", "AD354275"),
          datasetName = c("", "Dataset A", "Dataset B"),
          filePath = c("Please enter the working directory as the first filepath", "", ""),
          stringsAsFactors = FALSE
        ),
        summary = list(
          categoryMergingTies = data.frame(
            stackID = c("AD958", "AD959"),
            datasetID = c("AD354274", "AD354275"),
            Key = c("Site == AM1142", "Site == AM1142 && Field == Depth"),
            categoryCMID = c("AM1142", "AM1142"),
            categoryCMName = c("Shared Site", "Shared Site"),
            stringsAsFactors = FALSE
          )
        )
      )
    },
    .package = "CatMapR"
  )

  out_path <- file.path(tempdir(), "link_file_AD957_test.xlsx")
  if (file.exists(out_path)) {
    unlink(out_path)
  }

  result <- CatMapR::downloadLinkFileWorkbook(
    cmid = "AD957",
    database = "ArchaMap",
    path = out_path,
    overwrite = TRUE
  )

  expect_true(file.exists(out_path))
  expect_identical(sort(readxl::excel_sheets(out_path)), c("LinkFileLong", "LinkFileWide"))

  link_long <- readxl::read_excel(out_path, sheet = "LinkFileLong")
  link_wide <- readxl::read_excel(out_path, sheet = "LinkFileWide")

  expect_identical(link_long$datasetID[[1]], "AD354274")
  expect_true("AD354275 Field" %in% names(link_wide))
  expect_identical(link_wide$`AD354275 Field`[[1]], "Depth")
  expect_identical(result$path, normalizePath(out_path, winslash = "/", mustWork = FALSE))
})

test_that("generateMergeFiles submits merge syntax request and can download the zip", {
  captured <- new.env(parent = emptyenv())

  local_mocked_bindings(
    callAPI = function(endpoint, parameters, request = "GET", url = NULL, ...) {
      captured$endpoint <- endpoint
      captured$parameters <- parameters
      captured$request <- request
      captured$url <- url
      list(
        msg = "Syntax created successfully",
        download = list(zip = "/app/tmp/merged_output_hash123.zip", hash = "hash123")
      )
    },
    downloadMergeZip = function(hash_id, path = NULL, overwrite = FALSE, url = NULL) {
      captured$zip_hash <- hash_id
      captured$zip_path <- path
      normalizePath(path, winslash = "/", mustWork = FALSE)
    },
    .package = "CatMapR"
  )

  template <- data.frame(
    mergingID = c("AD957", "AD957"),
    stackID = c("AD958", "AD959"),
    datasetID = c("AD354274", "AD354275"),
    filePath = c("pseudo_data/A.csv", "pseudo_data/B.csv"),
    stringsAsFactors = FALSE
  )
  out_path <- file.path(tempdir(), "merged_output_hash123_test.zip")

  result <- CatMapR::generateMergeFiles(
    template = template,
    database = "ArchaMap",
    download_zip = TRUE,
    zip_path = out_path,
    overwrite = TRUE
  )

  expect_identical(captured$endpoint, "merge/syntax/ArchaMap")
  expect_identical(captured$request, "POST")
  expect_identical(captured$parameters$template[[1]]$mergingID, "AD957")
  expect_identical(captured$zip_hash, "hash123")
  expect_identical(result$zip_path, normalizePath(out_path, winslash = "/", mustWork = FALSE))
})

test_that("downloadMergeZip writes the returned archive to disk", {
  local_mocked_bindings(
    GET = function(url, ...) {
      args <- list(...)
      write_disk_cfg <- args[[1]]
      writeBin(charToRaw("zip-binary"), write_disk_cfg$output$path)
      structure(list(status_code = 200L), class = "response")
    },
    status_code = function(x) x$status_code,
    .package = "httr"
  )

  out_path <- file.path(tempdir(), "merged_output_hash456_test.zip")
  if (file.exists(out_path)) {
    unlink(out_path)
  }

  result <- CatMapR::downloadMergeZip(
    hash_id = "hash456",
    path = out_path,
    overwrite = TRUE,
    url = "https://api.example.org"
  )

  expect_true(file.exists(out_path))
  expect_identical(result, normalizePath(out_path, winslash = "/", mustWork = FALSE))
  expect_identical(readBin(out_path, what = "raw", n = 10), charToRaw("zip-binary"))
})
