#' Retrieve a Downloadable Merging Template
#'
#' This function retrieves the downloadable merging template rows for a
#' CatMapper merging template or related CMID.
#'
#' @param cmid A merging-template-related CMID accepted by the API route.
#' @param database A string specifying the database from which to retrieve the
#'   template. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
#'   otherwise `"https://api.catmapper.org"`.
#'
#' @return A data frame with one row per template entry, including the
#'   instructional working-directory row.
#'
#' @export
#' @examples
#' \dontrun{
#' getMergingTemplate(cmid = "AD354277", database = "ArchaMap")
#' }
getMergingTemplate <- function(cmid, database = "SocioMap", url = NULL) {
  database <- validate_database(database)
  cmid <- validate_scalar_character(cmid, "cmid")

  endpoint <- paste0("merge/template/", tolower(database), "/", cmid)
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  normalize_merging_template_response(response)
}

#' Retrieve a Merging Template Summary
#'
#' This function retrieves a structured summary for a MERGING or STACK node,
#' including stack summaries, dataset summaries, merge ties, and equivalence
#' ties.
#'
#' @param cmid A MERGING or STACK CMID.
#' @param database A string specifying the database from which to retrieve the
#'   summary. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
#'   otherwise `"https://api.catmapper.org"`.
#'
#' @return A list with normalized `stackSummary`, `datasetSummary`,
#'   `mergingTies`, and `equivalenceTies` data frames plus scalar summary
#'   fields returned by the API.
#'
#' @export
#' @examples
#' \dontrun{
#' getMergingTemplateSummary(cmid = "AD354277", database = "ArchaMap")
#' }
getMergingTemplateSummary <- function(cmid, database = "SocioMap", url = NULL) {
  database <- validate_database(database)
  cmid <- validate_scalar_character(cmid, "cmid")

  endpoint <- paste0("merge/template/summary/", tolower(database), "/", cmid)
  response <- callAPI(endpoint = endpoint, parameters = list(), request = "GET", url = url)

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  normalize_merging_template_summary_response(response)
}

#' Find and Classify a Merging Template
#'
#' Combines the merge-template summary and downloadable template rows into a
#' single convenience object and classifies whether the CMID is a merging
#' template, whether variable mappings are present, and whether a link file can
#' be downloaded.
#'
#' @param cmid A MERGING or STACK CMID.
#' @param database A string specifying the database from which to retrieve the
#'   template. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param url API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
#'   otherwise `"https://api.catmapper.org"`.
#'
#' @return A list with `status`, `summary`, and `template` entries.
#' @export
#' @examples
#' \dontrun{
#' template_info <- findMergingTemplate(cmid = "AD354277", database = "ArchaMap")
#' template_info$status
#' }
findMergingTemplate <- function(cmid, database = "SocioMap", url = NULL) {
  summary <- getMergingTemplateSummary(cmid = cmid, database = database, url = url)
  template <- getMergingTemplate(cmid = cmid, database = database, url = url)
  status <- summarize_merging_template_status(summary)

  list(
    cmid = cmid,
    database = database,
    status = status,
    summary = summary,
    template = template
  )
}

#' Download a Merging Template Workbook
#'
#' Writes the downloadable merge-template rows to an `.xlsx` workbook.
#'
#' @param cmid A merging-template-related CMID accepted by the API route.
#' @param database A string specifying the database from which to retrieve the
#'   template. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param path Optional output workbook path. Defaults to
#'   `merging_template_<CMID>.xlsx` in the working directory.
#' @param overwrite Whether to overwrite an existing file.
#' @param url API URL override.
#'
#' @return Invisibly returns a list with `path` and `template`.
#' @export
#' @examples
#' \dontrun{
#' downloadMergingTemplateWorkbook(
#'   cmid = "AD354277",
#'   database = "ArchaMap",
#'   path = "merging_template_AD354277.xlsx",
#'   overwrite = TRUE
#' )
#' }
downloadMergingTemplateWorkbook <- function(cmid,
                                            database = "SocioMap",
                                            path = NULL,
                                            overwrite = FALSE,
                                            url = NULL) {
  cmid <- validate_scalar_character(cmid, "cmid")
  database <- validate_database(database)
  overwrite <- validate_scalar_logical(overwrite, "overwrite")

  template <- getMergingTemplate(cmid = cmid, database = database, url = url)
  path <- normalize_workbook_path(path %||% file.path(getwd(), paste0("merging_template_", cmid, ".xlsx")))
  assert_writable_output_path(path, overwrite = overwrite)

  writexl::write_xlsx(list(MergingTemplate = template), path = path)

  invisible(list(path = normalizePath(path, winslash = "/", mustWork = FALSE), template = template))
}

#' Download a Link-File Workbook
#'
#' For merging templates without variable mappings, writes long and wide link
#' file sheets derived from the template's equivalence ties.
#'
#' @param cmid A MERGING CMID.
#' @param database A string specifying the database from which to retrieve the
#'   template. Valid options are `"SocioMap"` or `"ArchaMap"`.
#' @param path Optional output workbook path. Defaults to `link_file_<CMID>.xlsx`
#'   in the working directory.
#' @param overwrite Whether to overwrite an existing file.
#' @param url API URL override.
#'
#' @return Invisibly returns a list with `path`, `status`, and `sheets`.
#' @export
#' @examples
#' \dontrun{
#' downloadLinkFileWorkbook(
#'   cmid = "AD354277",
#'   database = "ArchaMap",
#'   path = "link_file_AD354277.xlsx",
#'   overwrite = TRUE
#' )
#' }
downloadLinkFileWorkbook <- function(cmid,
                                     database = "SocioMap",
                                     path = NULL,
                                     overwrite = FALSE,
                                     url = NULL) {
  cmid <- validate_scalar_character(cmid, "cmid")
  database <- validate_database(database)
  overwrite <- validate_scalar_logical(overwrite, "overwrite")

  result <- findMergingTemplate(cmid = cmid, database = database, url = url)
  if (!isTRUE(result$status$isMergingTemplate)) {
    stop(sprintf("\"%s\" is not a merging template.", cmid), call. = FALSE)
  }
  if (isTRUE(result$status$hasVariableMappings)) {
    stop(
      sprintf(
        "Merging template \"%s\" has variable mappings. Download the merge template workbook instead.",
        cmid
      ),
      call. = FALSE
    )
  }
  if (!isTRUE(result$status$canDownloadLinkFile)) {
    stop(sprintf("Merging template \"%s\" has no equivalence ties to build a link file.", cmid), call. = FALSE)
  }

  sheets <- build_link_file_sheets(
    template_rows = result$template,
    equivalence_ties = result$summary$equivalenceTies
  )
  path <- normalize_workbook_path(path %||% file.path(getwd(), paste0("link_file_", cmid, ".xlsx")))
  assert_writable_output_path(path, overwrite = overwrite)

  writexl::write_xlsx(sheets, path = path)

  invisible(list(path = normalizePath(path, winslash = "/", mustWork = FALSE), status = result$status, sheets = sheets))
}

#' Generate Merge Files
#'
#' Submits a filled merge template to the CatMapper merge-syntax endpoint. The
#' template may be supplied as a data frame, a list of row objects, or the path
#' to a `.xlsx`, `.xls`, or `.csv` file.
#'
#' @param template A data frame, list of row objects, or file path.
#' @param database A string specifying the target database.
#' @param download_zip Whether to immediately download the returned zip archive.
#' @param zip_path Optional local path for the downloaded zip archive.
#' @param overwrite Whether to overwrite an existing zip archive when
#'   `download_zip = TRUE`.
#' @param url API URL override.
#'
#' @return A list with the API response, normalized template rows, and optional
#'   `zip_path`.
#' @export
#' @examples
#' \dontrun{
#' template <- data.frame(
#'   mergingID = "AD354277",
#'   stackID = "AD354278",
#'   datasetID = "AD354279",
#'   filePath = "/path/to/local_dataset.csv",
#'   stringsAsFactors = FALSE
#' )
#'
#' result <- generateMergeFiles(
#'   template = template,
#'   database = "ArchaMap",
#'   download_zip = TRUE,
#'   overwrite = TRUE
#' )
#' result$zip_path
#' }
generateMergeFiles <- function(template,
                               database = "SocioMap",
                               download_zip = TRUE,
                               zip_path = NULL,
                               overwrite = FALSE,
                               url = NULL) {
  database <- validate_database(database)
  download_zip <- validate_scalar_logical(download_zip, "download_zip")
  overwrite <- validate_scalar_logical(overwrite, "overwrite")

  template_df <- coerce_merge_template_input(template)
  response <- callAPI(
    endpoint = paste0("merge/syntax/", database),
    parameters = list(
      template = lapply(seq_len(nrow(template_df)), function(i) {
        as.list(template_df[i, , drop = FALSE])
      })
    ),
    request = "POST",
    url = url
  )

  if (is.list(response) && !is.null(response$error)) {
    stop(as.character(response$error[[1]]), call. = FALSE)
  }

  result <- list(
    response = response,
    template = template_df
  )

  hash_id <- response$download$hash %||% NULL
  if (isTRUE(download_zip) && !is.null(hash_id) && nzchar(hash_id)) {
    default_zip_path <- file.path(tempdir(), paste0("merged_output_", hash_id, ".zip"))
    result$zip_path <- downloadMergeZip(
      hash_id = hash_id,
      path = zip_path %||% default_zip_path,
      overwrite = overwrite,
      url = url
    )
  }

  result
}

#' Download a Generated Merge Zip Archive
#'
#' Downloads the merge zip archive exposed by `/download/zip/<hash>`.
#'
#' @param hash_id Merge bundle hash returned by `generateMergeFiles()`.
#' @param path Optional local output path. Defaults to
#'   `merged_output_<hash>.zip` in `tempdir()`.
#' @param overwrite Whether to overwrite an existing file.
#' @param url API URL override.
#'
#' @return Normalized local output path.
#' @export
#' @examples
#' \dontrun{
#' downloadMergeZip(
#'   hash_id = "returned_merge_hash",
#'   path = "merged_output.zip",
#'   overwrite = TRUE
#' )
#' }
downloadMergeZip <- function(hash_id,
                             path = NULL,
                             overwrite = FALSE,
                             url = NULL) {
  hash_id <- validate_scalar_character(hash_id, "hash_id")
  overwrite <- validate_scalar_logical(overwrite, "overwrite")

  path <- normalize_workbook_path(path %||% file.path(tempdir(), paste0("merged_output_", hash_id, ".zip")))
  assert_writable_output_path(path, overwrite = overwrite)

  base_url <- resolve_api_url(url)
  response <- httr::GET(
    paste0(base_url, "/download/zip/", hash_id),
    httr::write_disk(path, overwrite = overwrite)
  )

  status_code <- httr::status_code(response)
  if (!status_code %in% 200:299) {
    error_text <- tryCatch(httr::content(response, as = "text", encoding = "UTF-8"), error = function(e) "")
    stop(if (nzchar(error_text)) error_text else sprintf("HTTP %s", status_code), call. = FALSE)
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

normalize_merging_template_response <- function(response) {
  required_cols <- c(
    "mergingID",
    "mergingCMName",
    "mergingShortName",
    "mergingCitation",
    "stackID",
    "datasetID",
    "datasetName",
    "filePath"
  )

  normalize_section_df(response, required_cols)
}

normalize_merging_template_summary_response <- function(response) {
  if (is.null(response)) {
    response <- list()
  }

  list(
    nodeType = if (!is.null(response$nodeType)) as.character(response$nodeType[[1]]) else NA_character_,
    stackSummary = normalize_section_df(
      response$stackSummary,
      c("stackID", "stackCMName", "datasetCount", "equivalenceTieCount", "keyReassignmentCount", "variableCount")
    ),
    stackSummaryTotals = normalize_named_list(
      response$stackSummaryTotals,
      c("datasetCount", "equivalenceTieCount", "keyReassignmentCount", "variableCount")
    ),
    datasetSummary = normalize_section_df(
      response$datasetSummary,
      c("datasetID", "datasetCMName", "equivalenceTieCount", "keyReassignmentCount", "variableCount")
    ),
    mergingTemplateCount = if (!is.null(response$mergingTemplateCount)) response$mergingTemplateCount[[1]] else 0,
    mergingTies = normalize_section_df(
      response$mergingTies,
      c(
        "mergingID",
        "mergingCMName",
        "stackID",
        "stackCMName",
        "relationship",
        "targetLabels",
        "targetCMID",
        "targetCMName",
        "tieStackID",
        "varName",
        "stackTransform",
        "datasetTransform",
        "variableFilter",
        "summaryStatistic",
        "summaryFilter",
        "summaryWeight"
      )
    ),
    equivalenceTies = normalize_section_df(
      response$equivalenceTies,
      c("stackID", "datasetID", "Key", "originalCMID", "originalCMName", "equivalentCMID", "equivalentCMName", "selfReference")
    )
  )
}

normalize_section_df <- function(x, required_cols) {
  if (is.null(x)) {
    out <- data.frame(stringsAsFactors = FALSE)
  } else if (is.data.frame(x)) {
    out <- x
  } else if (is.list(x) && length(x) == 0) {
    out <- data.frame(stringsAsFactors = FALSE)
  } else if (is.list(x) && length(x) > 0 && all(vapply(x, is.list, logical(1)))) {
    row_names <- unique(unlist(lapply(x, names), use.names = FALSE))
    out_cols <- lapply(row_names, function(name) {
      values <- lapply(x, function(row) row[[name]])
      values <- lapply(values, function(value) {
        if (is.null(value) || length(value) == 0) {
          return(NA)
        }
        if (length(value) == 1 && !is.list(value)) {
          return(value[[1]])
        }
        unname(unlist(value, recursive = TRUE, use.names = FALSE))
      })

      if (any(vapply(values, function(value) length(value) > 1, logical(1)))) {
        return(I(values))
      }

      unlist(values, use.names = FALSE)
    })
    names(out_cols) <- row_names
    out <- as.data.frame(out_cols, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (is.list(x) && !is.null(names(x))) {
    out <- as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    out <- as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
  }

  missing_cols <- setdiff(required_cols, names(out))
  for (col in missing_cols) {
    out[[col]] <- rep(NA_character_, nrow(out))
  }

  out[, c(required_cols, setdiff(names(out), required_cols)), drop = FALSE]
}

normalize_named_list <- function(x, required_names) {
  out <- stats::setNames(as.list(rep(NA, length(required_names))), required_names)

  if (is.null(x)) {
    return(out)
  }

  if (!is.list(x)) {
    x <- as.list(x)
  }

  for (name in intersect(required_names, names(x))) {
    value <- x[[name]]
    out[[name]] <- if (length(value) == 0) NA else value[[1]]
  }

  out
}

summarize_merging_template_status <- function(summary) {
  node_type <- toupper(as.character(summary$nodeType %||% NA_character_))
  variable_count <- suppressWarnings(as.numeric(summary$stackSummaryTotals$variableCount %||% 0))
  if (length(variable_count) == 0 || is.na(variable_count)) {
    variable_count <- 0
  }

  equivalence_tie_count <- if (is.data.frame(summary$equivalenceTies)) {
    nrow(summary$equivalenceTies)
  } else {
    0
  }

  list(
    nodeType = node_type,
    isMergingTemplate = identical(node_type, "MERGING"),
    hasVariableMappings = variable_count > 0,
    canDownloadLinkFile = identical(node_type, "MERGING") && equivalence_tie_count > 0,
    variableCount = variable_count,
    equivalenceTieCount = equivalence_tie_count
  )
}

normalize_workbook_path <- function(path) {
  validate_scalar_character(path, "path")
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

assert_writable_output_path <- function(path, overwrite = FALSE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path) && !isTRUE(overwrite)) {
    stop(sprintf("File already exists: %s", path), call. = FALSE)
  }
  invisible(path)
}

coerce_merge_template_input <- function(template) {
  if (is.data.frame(template)) {
    return(as.data.frame(template, stringsAsFactors = FALSE, check.names = FALSE))
  }

  if (is.list(template) && length(template) > 0 && all(vapply(template, is.list, logical(1)))) {
    return(normalize_section_df(template, required_cols = character(0)))
  }

  if (is.character(template) && length(template) == 1 && !is.na(template) && nzchar(template)) {
    ext <- tolower(tools::file_ext(template))
    if (ext %in% c("xlsx", "xls")) {
      return(as.data.frame(readxl::read_excel(template), stringsAsFactors = FALSE, check.names = FALSE))
    }
    if (identical(ext, "csv")) {
      return(utils::read.csv(template, stringsAsFactors = FALSE, check.names = FALSE))
    }
    stop("`template` file path must end in .xlsx, .xls, or .csv.", call. = FALSE)
  }

  stop("`template` must be a data frame, a list of row objects, or a file path.", call. = FALSE)
}

parse_key_expression <- function(key) {
  text <- trimws(as.character(key %||% ""))
  if (!nzchar(text)) {
    return(list())
  }

  parts <- strsplit(text, " && ", fixed = TRUE)[[1]]
  parts <- trimws(parts[nzchar(trimws(parts))])
  out <- list()

  for (i in seq_along(parts)) {
    part <- parts[[i]]
    marker_index <- regexpr(" == ", part, fixed = TRUE)[[1]]
    if (identical(marker_index, -1L)) {
      out[[paste0("KeyPart", i)]] <- part
      next
    }

    raw_name <- trimws(substr(part, 1, marker_index - 1))
    raw_value <- trimws(substr(part, marker_index + 4, nchar(part)))
    if (!nzchar(raw_name)) {
      raw_name <- paste0("KeyPart", i)
    }

    name <- raw_name
    suffix <- 2
    while (!is.null(out[[name]])) {
      name <- paste0(raw_name, "_", suffix)
      suffix <- suffix + 1
    }
    out[[name]] <- raw_value
  }

  out
}

build_link_file_sheets <- function(template_rows, equivalence_ties) {
  if (!is.data.frame(template_rows)) {
    template_rows <- as.data.frame(template_rows, stringsAsFactors = FALSE, check.names = FALSE)
  }
  if (!is.data.frame(equivalence_ties)) {
    equivalence_ties <- as.data.frame(equivalence_ties, stringsAsFactors = FALSE, check.names = FALSE)
  }

  dataset_lookup <- template_rows[template_rows$datasetID %in% equivalence_ties$datasetID, , drop = FALSE]
  dataset_lookup <- unique(dataset_lookup[, intersect(c("datasetID", "datasetName"), names(dataset_lookup)), drop = FALSE])

  long_rows <- lapply(seq_len(nrow(equivalence_ties)), function(i) {
    row <- equivalence_ties[i, , drop = FALSE]
    dataset_id <- as.character(row$datasetID[[1]] %||% "")
    dataset_name <- ""
    if (nrow(dataset_lookup) > 0 && "datasetID" %in% names(dataset_lookup)) {
      match_idx <- match(dataset_id, dataset_lookup$datasetID)
      if (!is.na(match_idx) && "datasetName" %in% names(dataset_lookup)) {
        dataset_name <- dataset_lookup$datasetName[[match_idx]] %||% ""
      }
    }

    parsed <- parse_key_expression(row$Key[[1]] %||% "")
    c(
      list(
        stackID = row$stackID[[1]] %||% "",
        datasetID = dataset_id,
        datasetName = dataset_name,
        CMID = row$equivalentCMID[[1]] %||% row$originalCMID[[1]] %||% "",
        CMName = row$equivalentCMName[[1]] %||% row$originalCMName[[1]] %||% "",
        originalCMID = row$originalCMID[[1]] %||% "",
        originalCMName = row$originalCMName[[1]] %||% "",
        Key = row$Key[[1]] %||% ""
      ),
      parsed
    )
  })

  long_df <- if (length(long_rows) == 0) {
    data.frame(
      stackID = character(),
      datasetID = character(),
      datasetName = character(),
      CMID = character(),
      CMName = character(),
      originalCMID = character(),
      originalCMName = character(),
      Key = character(),
      stringsAsFactors = FALSE
    )
  } else {
    normalize_section_df(long_rows, required_cols = c(
      "stackID", "datasetID", "datasetName", "CMID", "CMName", "originalCMID", "originalCMName", "Key"
    ))
  }

  wide_rows <- list()
  if (nrow(long_df) > 0) {
    category_keys <- unique(paste(long_df$CMID, long_df$CMName, sep = "||"))
    wide_rows <- lapply(category_keys, function(key_id) {
      key_rows <- long_df[paste(long_df$CMID, long_df$CMName, sep = "||") == key_id, , drop = FALSE]
      row <- list(
        CMID = key_rows$CMID[[1]],
        CMName = key_rows$CMName[[1]]
      )
      for (i in seq_len(nrow(key_rows))) {
        dataset_id <- key_rows$datasetID[[i]]
        row[[paste0(dataset_id, " Key")]] <- key_rows$Key[[i]]
        parsed <- parse_key_expression(key_rows$Key[[i]])
        if (length(parsed) > 0) {
          for (name in names(parsed)) {
            row[[paste0(dataset_id, " ", name)]] <- parsed[[name]]
          }
        }
      }
      row
    })
  }

  wide_df <- if (length(wide_rows) == 0) {
    data.frame(CMID = character(), CMName = character(), stringsAsFactors = FALSE)
  } else {
    normalize_section_df(wide_rows, required_cols = c("CMID", "CMName"))
  }

  list(
    LinkFileWide = wide_df,
    LinkFileLong = long_df
  )
}
