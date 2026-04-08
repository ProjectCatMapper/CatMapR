#' Build CatMapper Key Expressions
#'
#' Build key expressions in the `FIELD == VALUE` format used by CatMapper
#' upload workflows.
#'
#' @param field Field name(s) used on the left side of the expression.
#' @param value Value(s) used on the right side of the expression.
#'
#' @return A character vector of key expressions.
#' @export
#'
#' @examples
#' build_key("Type", "Adamana Brown")
#' build_key(c("Type", "Region"), c("Adamana Brown", "Flagstaff"))
build_key <- function(field, value) {
  if (!is.character(field) || !is.character(value)) {
    stop("`field` and `value` must be character vectors.", call. = FALSE)
  }
  if (length(field) == 0 || length(value) == 0) {
    return(character(0))
  }
  if (length(field) != length(value)) {
    if (length(field) == 1) {
      field <- rep(field, length(value))
    } else if (length(value) == 1) {
      value <- rep(value, length(field))
    } else {
      stop("`field` and `value` must have the same length or length 1.", call. = FALSE)
    }
  }
  paste(trimws(field), "==", trimws(value))
}

#' Build Row-Wise Composite Key Column From Source Columns
#'
#' Build a CatMapper-compatible key column from one or more source columns
#' using the `FIELD == VALUE` expression format, joined by `&&` per row.
#'
#' @param data Data frame containing source key columns.
#' @param columns Character vector of source column names to include in the key.
#' @param key_column Name of the output key column. Defaults to `Key`.
#' @param drop_source If `TRUE`, remove source key columns after creating the
#'   output key column.
#'
#' @return A data frame with the generated key column.
#' @export
#'
#' @examples
#' rows <- data.frame(Type = "Adamana Brown", Region = "Flagstaff", stringsAsFactors = FALSE)
#' build_key_from_columns(rows, c("Type", "Region"))
build_key_from_columns <- function(data,
                                   columns,
                                   key_column = "Key",
                                   drop_source = FALSE) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(columns) || length(columns) == 0) {
    stop("`columns` must be a non-empty character vector.", call. = FALSE)
  }
  columns <- unique(trimws(columns))
  columns <- columns[nzchar(columns)]
  if (length(columns) == 0) {
    stop("`columns` must include at least one non-empty column name.", call. = FALSE)
  }

  if (!is.character(key_column) || length(key_column) != 1 || is.na(key_column) || !nzchar(key_column)) {
    stop("`key_column` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.logical(drop_source) || length(drop_source) != 1 || is.na(drop_source)) {
    stop("`drop_source` must be TRUE or FALSE.", call. = FALSE)
  }

  missing_cols <- columns[!columns %in% names(data)]
  if (length(missing_cols) > 0) {
    stop(
      sprintf("Source key column(s) not found in `data`: %s.", paste(missing_cols, collapse = ", ")),
      call. = FALSE
    )
  }

  if (nrow(data) == 0) {
    data[[key_column]] <- character(0)
    return(data)
  }

  column_parts <- lapply(columns, function(col) {
    raw <- data[[col]]
    text <- trimws(as.character(raw))
    text[is.na(raw)] <- ""
    ifelse(nzchar(text), build_key(col, text), "")
  })

  keys <- vapply(seq_len(nrow(data)), function(i) {
    row_parts <- vapply(column_parts, function(part) part[[i]], character(1), USE.NAMES = FALSE)
    row_parts <- row_parts[nzchar(row_parts)]
    paste(row_parts, collapse = " && ")
  }, character(1))

  empty_rows <- which(!nzchar(keys))
  if (length(empty_rows) > 0) {
    stop(
      sprintf(
        "Cannot build Key values for row(s) with empty source values across selected columns: %s.",
        paste(empty_rows, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  data[[key_column]] <- keys

  if (isTRUE(drop_source)) {
    keep_cols <- setdiff(names(data), columns)
    data <- data[, keep_cols, drop = FALSE]
  }

  data
}

#' Normalize Key Expressions
#'
#' Normalize key strings by removing stored-form prefixes (for example
#' `Key == `), trimming whitespace around separators, and standardizing
#' `&&`-joined segments.
#'
#' @param key Character vector of key expressions.
#'
#' @return Character vector of normalized key expressions.
#' @export
#'
#' @examples
#' normalize_key("Key == Region == Flagstaff")
#' normalize_key(" Region==Flagstaff  && Type== Adamana Brown ")
normalize_key <- function(key) {
  if (!is.character(key)) {
    stop("`key` must be a character vector.", call. = FALSE)
  }
  if (length(key) == 0) {
    return(character(0))
  }
  out <- key
  na_idx <- is.na(out)
  if (all(na_idx)) {
    return(out)
  }
  work <- trimws(out[!na_idx])
  work <- gsub("^\\s*Key\\s*==\\s*", "", work, perl = TRUE)

  normalize_segment <- function(segment) {
    part <- trimws(segment)
    if (!grepl("==", part, fixed = TRUE)) {
      return(part)
    }
    pieces <- strsplit(part, "==", fixed = TRUE)[[1]]
    if (length(pieces) < 2) {
      return(trimws(part))
    }
    left <- trimws(pieces[1])
    right <- trimws(paste(pieces[-1], collapse = "=="))
    paste(left, "==", right)
  }

  work <- vapply(
    work,
    function(x) {
      segments <- strsplit(x, "\\s*&&\\s*", perl = TRUE)[[1]]
      segments <- vapply(segments, normalize_segment, character(1), USE.NAMES = FALSE)
      paste(segments, collapse = " && ")
    },
    character(1),
    USE.NAMES = FALSE
  )
  out[!na_idx] <- work
  out
}

#' Check Whether Keys Are Normalized
#'
#' Test whether key strings are already in normalized CatMapper expression form.
#'
#' @param key Character vector of key expressions.
#'
#' @return Logical vector (`TRUE` when normalized).
#' @export
#'
#' @examples
#' is_normalized_key("Region == Flagstaff")
#' is_normalized_key("Key == Region == Flagstaff")
is_normalized_key <- function(key) {
  if (!is.character(key)) {
    stop("`key` must be a character vector.", call. = FALSE)
  }
  normalized <- normalize_key(key)
  pattern <- "^.+?\\s==\\s.+?(?:\\s&&\\s.+?\\s==\\s.+?)*$"
  is.na(key) | (normalized == key & grepl(pattern, normalized))
}
