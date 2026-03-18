#' Translate
#'
#' This function translate a dataframe by matching the specified term with the property in the database.
#'
#' @param rows data frame to translate
#' @param database database to use (SocioMap or ArchaMap)
#' @param domain name of category domain to search for (DISTRICT, ETHNICITY, etc.)
#' @param term column name to translate
#' @param property property to search by (Name, CMID, or Key)
#' @param yearStart year to search by start
#' @param yearEnd year to search by end
#' @param country column name of country to search by (CMID)
#' @param context column name of context to search by (CMID)
#' @param dataset column name of dataset to search by (dataset CMID)
#' @param key include Key values in results ('true' or 'false')
#' @param query return query instead of results
#' @param countsamename count duplicate matching names in scoring logic
#' @param uniqueRows deduplicate identical input rows before matching
#'
#' @return A list with \code{file} and \code{order} from the API.
#' @export
#'
#' @examples
#' \dontrun{
#' df = data.frame(country = "Afghanistan")
#' translate(
#'   rows = df,
#'   database = "SocioMap",
#'   domain = "ADM0",
#'   term = "country",
#'   property = "Name",
#'   yearStart = NULL,
#'   yearEnd = NULL,
#'   country = NULL,
#'   context = NULL,
#'   query = "false"
#' )
#' }
translate = function(rows,database,term,property = "Name",domain = "CATEGORY", context = NULL, country = NULL, dataset = NULL, yearStart = NULL, yearEnd = NULL, key = 'false',query = 'false', countsamename = FALSE, uniqueRows = TRUE){
  database <- validate_database(database)
  term <- validate_scalar_character(term, "term")
  property <- validate_scalar_character(property, "property")
  if (length(domain) < 1 || !is.character(domain) || is.na(domain[1]) || !nzchar(domain[1])) {
    stop("`domain` must contain at least one non-empty character value.", call. = FALSE)
  }
  if (!is.data.frame(rows)) {
    stop("`rows` must be a data frame.", call. = FALSE)
  }
  if (!is.null(context)) {
    context <- validate_scalar_character(context, "context")
  }
  if (!is.null(country)) {
    country <- validate_scalar_character(country, "country")
  }
  if (!is.null(dataset)) {
    dataset <- validate_scalar_character(dataset, "dataset")
  }
  key <- validate_choice(key, c("true", "false"), "key")
  query <- validate_choice(query, c("true", "false"), "query")
  if (!is.logical(countsamename) || length(countsamename) != 1 || is.na(countsamename)) {
    stop("`countsamename` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(uniqueRows) || length(uniqueRows) != 1 || is.na(uniqueRows)) {
    stop("`uniqueRows` must be TRUE or FALSE.", call. = FALSE)
  }

  results = callAPI(endpoint = "translate", parameters = list(
         table = rows,
         database = database,
         property = property,
         term = term,
         country = country,
         context = context,
         dataset = dataset,
         yearStart = yearStart,
         yearEnd = yearEnd,
         domain = domain[1],
         key = key,
         query = query,
         countsamename = countsamename,
         uniqueRows = uniqueRows
  ), request = "POST")

  return(results)
}
