#' Translate
#'
#' This function translate a dataframe by matching the specified term with the property in the database.
#'
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
#' df = data.frame(country = "Afghanistan")
#' translate(rows = df, database = "SocioMap",domain = "ADM0", term = "country", property = "Name", yearStart = NULL, yearEnd = NULL, country = NULL, context = NULL, query = 'false')
translate = function(rows,database,term,property = "Name",domain = "CATEGORY", context = NULL, country = NULL, dataset = NULL, yearStart = NULL, yearEnd = NULL, key = 'false',query = 'false', countsamename = FALSE, uniqueRows = TRUE){
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
