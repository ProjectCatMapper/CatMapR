#' Search
#'
#' Search for a term in a database and retrieve the CMID (CatMapperID), CMName (CatMapper Name), and other information about the matches.
#'
#' @param database name of database (SocioMap or ArchaMap)
#' @param domain name of category domain to search for (DISTRICT, ETHNICITY, etc.)
#' @param term search term ("Afghanistan")
#' @param property property to search by (Name, CMID, or Key)
#' @param yearStart year to search by start
#' @param yearEnd year to search by end
#' @param country country to search by (must be a CMID)
#' @param context context to search by (e.g., hierarchical category as in the state for a county--must be a CMID)
#' @param dataset dataset to search by (must be a dataset CMID)
#' @param query return query instead of results ('true' or 'false')
#' @param limit limit number of results (currently ignored by API and capped at 10,000 server-side)
#'
#' @return A list with \code{data} and \code{count} elements.
#' @export
#'
#' @examples
#' searchDatabase(database = "SocioMap", domain = "ETHNICITY", term = "Dan", property = "Name")
searchDatabase = function(database,
                  domain = NULL,
                  term = NULL,
                  property = "Name",
                  yearStart = NULL,
                  yearEnd = NULL,
                  country = NULL,
                  context = NULL,
                  dataset = NULL,
                  query = "false",
                  limit = 1000){
  result = callAPI(endpoint = "search",
                   parameters = list(
                     term = term,
                     database = database,
                     domain = domain,
                     property = property,
                     yearStart = yearStart,
                     yearEnd = yearEnd,
                     country = country,
                     context = context,
                     dataset = dataset,
                     query = query,
                     limit = limit)
  )
  return(result)
}
