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
#' @param query return query instead of results
#'
#' @return dataframe
#' @export
#'
#' @examples
#' df = data.frame(country = "Afghanistan")
#' translate(rows = df, database = "SocioMap",domain = "ADM0", term = "country", property = "Name", yearStart = NULL, yearEnd = NULL, country = NULL, context = NULL, query = 'false')
translate = function(rows,database,term,property = "Name",domain = "CATEGORY", context = NULL, country = NULL, dataset = NULL, yearStart = NULL, yearEnd = NULL, key = 'false',query = 'false'){
  results = callAPI(endpoint = "translate2", parameters = jsonlite::toJSON(
    list(table = rows,
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
         query = query
    )
  ), request = "POST")

  return(results)
}
