#' Retrieve Domain Metadata from a Specified Database
#'
#' This function retrieves CatMapper domain and subdomain metadata from a
#' specified database. By default, it returns a simplified data frame with the
#' domain, subdomain, and description columns. When `advanced = TRUE`, it
#' returns all metadata fields exposed by the API when available.
#'
#' @param database A string specifying the database from which to retrieve domains. Valid options are "SocioMap" or "ArchaMap".
#' @param advanced Logical; if `TRUE`, return richer metadata fields when available. Defaults to `FALSE`.
#'
#' @return A data frame of domain metadata. By default, the result contains the
#' columns `domain`, `subdomain`, and `description`. When `advanced = TRUE`,
#' additional metadata columns returned by the API are preserved.
#'
#' @export
#' @examples
#' \dontrun{
#' getDomains(database = "SocioMap")
#' getDomains(database = "ArchaMap", advanced = TRUE)
#' }
getDomains <- function(database = "SocioMap", advanced = FALSE) {
  database <- validate_database(database)
  if (!is.logical(advanced) || length(advanced) != 1 || is.na(advanced)) {
    stop("`advanced` must be TRUE or FALSE.", call. = FALSE)
  }

  response <- callAPI(
    endpoint = "getTranslatedomains",
    parameters = list(database = database),
    request = "GET"
  )

  domains <- normalize_domain_response(response)

  if (!"description" %in% names(domains)) {
    domains$description <- NA_character_
  }

  if (!advanced) {
    domains <- domains[, c("domain", "subdomain", "description"), drop = FALSE]
  }

  domains
}

normalize_domain_response <- function(response) {
  if (is.null(response)) {
    return(data.frame(
      domain = character(0),
      subdomain = character(0),
      description = character(0),
      stringsAsFactors = FALSE
    ))
  }

  if (is.data.frame(response)) {
    records <- lapply(seq_len(nrow(response)), function(i) as.list(response[i, , drop = FALSE]))
  } else if (is.list(response) && !is.null(response$group) && !is.null(response$nodes)) {
    n_records <- max(length(response$group), length(response$nodes))
    records <- lapply(seq_len(n_records), function(i) {
      pieces <- lapply(response, function(value) {
        if (is.list(value)) {
          value[[i]]
        } else {
          value[[i]]
        }
      })
      pieces
    })
  } else if (is.list(response) && length(response) > 0 && is.list(response[[1]])) {
    records <- response
  } else {
    records <- list(response)
  }

  rows <- unlist(lapply(records, flatten_domain_record), recursive = FALSE)
  rows <- Filter(Negate(is.null), rows)

  if (length(rows) == 0) {
    return(data.frame(
      domain = character(0),
      subdomain = character(0),
      description = character(0),
      stringsAsFactors = FALSE
    ))
  }

  all_names <- unique(unlist(lapply(rows, names), use.names = FALSE))
  out <- lapply(all_names, function(name) {
    values <- lapply(rows, function(row) row[[name]])
    values[sapply(values, is.null)] <- NA
    unlist(values, use.names = FALSE)
  })
  names(out) <- all_names

  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

flatten_domain_record <- function(record) {
  if (is.null(record)) {
    return(NULL)
  }

  record <- as.list(record)

  domain <- record$domain
  if (is.null(domain)) {
    domain <- record$group
  }
  if (is.null(domain) || length(domain) == 0 || is.na(domain[[1]]) || !nzchar(as.character(domain[[1]]))) {
    return(NULL)
  }
  domain <- as.character(domain[[1]])

  subdomains <- record$subdomain
  if (is.null(subdomains)) {
    subdomains <- record$nodes
  }
  if (is.null(subdomains) || length(subdomains) == 0) {
    subdomains <- NA_character_
  }

  subdomains <- unlist(subdomains, recursive = TRUE, use.names = FALSE)
  if (length(subdomains) == 0) {
    subdomains <- NA_character_
  }
  subdomains <- as.character(subdomains)

  extras <- record[setdiff(names(record), c("domain", "group", "subdomain", "nodes"))]

  lapply(seq_along(subdomains), function(i) {
    c(list(domain = domain, subdomain = subdomains[[i]]), extras)
  })
}
