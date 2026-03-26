valid_databases <- c("SocioMap", "ArchaMap")

validate_scalar_character <- function(x, arg) {
  if (!is.character(x) || length(x) != 1 || is.na(x) || !nzchar(x)) {
    stop(sprintf("`%s` must be a non-empty character scalar.", arg), call. = FALSE)
  }
  x
}

validate_database <- function(database, arg = "database") {
  database <- validate_scalar_character(database, arg)
  if (!database %in% valid_databases) {
    stop(
      sprintf(
        "`%s` must be one of: %s.",
        arg,
        paste(valid_databases, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  database
}

validate_choice <- function(x, choices, arg) {
  x <- validate_scalar_character(x, arg)
  if (!x %in% choices) {
    stop(
      sprintf("`%s` must be one of: %s.", arg, paste(choices, collapse = ", ")),
      call. = FALSE
    )
  }
  x
}

validate_positive_integer <- function(x, arg) {
  if (length(x) != 1 || is.na(x) || !is.numeric(x) || x < 1 || (x %% 1) != 0) {
    stop(sprintf("`%s` must be a positive integer.", arg), call. = FALSE)
  }
  as.integer(x)
}

validate_scalar_logical <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1 || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", arg), call. = FALSE)
  }
  x
}

validate_optional_scalar_logical <- function(x, arg) {
  if (is.null(x)) {
    return(NULL)
  }
  validate_scalar_logical(x, arg)
}

validate_character_collection <- function(x, arg) {
  if (is.null(x)) {
    return(list())
  }

  if (is.character(x)) {
    return(as.list(x))
  }

  if (is.list(x)) {
    return(x)
  }

  stop(sprintf("`%s` must be NULL, a character vector, or a list.", arg), call. = FALSE)
}

