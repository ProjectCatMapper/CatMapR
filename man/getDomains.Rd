% Generated manually to match package style.
\name{getDomains}
\alias{getDomains}
\title{Retrieve Domain Metadata from a Specified Database}
\usage{
getDomains(database = "SocioMap", advanced = FALSE)
}
\arguments{
\item{database}{A string specifying the database from which to retrieve domains. Valid options are "SocioMap" or "ArchaMap".}

\item{advanced}{Logical; if \code{TRUE}, return richer metadata fields when available. Defaults to \code{FALSE}.}
}
\value{
A data frame of domain metadata. By default, the result contains the
columns \code{domain}, \code{subdomain}, and \code{description}. When
\code{advanced = TRUE}, additional metadata columns returned by the API are
preserved.
}
\description{
This function retrieves CatMapper domain and subdomain metadata from a
specified database. By default, it returns a simplified data frame with the
domain, subdomain, and description columns. When \code{advanced = TRUE}, it
returns all metadata fields exposed by the API when available.
}
\examples{
\dontrun{
getDomains(database = "SocioMap")
getDomains(database = "ArchaMap", advanced = TRUE)
}
}
