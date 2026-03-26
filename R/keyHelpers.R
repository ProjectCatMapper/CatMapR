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
