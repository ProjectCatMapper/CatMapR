% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/createLinkfile.R
\name{createLinkfile}
\alias{createLinkfile}
\title{Create Linkfile from Dataset CMIDs}
\usage{
createLinkfile(
  categoryLabel,
  datasetChoices,
  database = "SocioMap",
  intersection = FALSE
)
}
\arguments{
\item{categoryLabel}{Character vector specifying the category domain for the merge.}

\item{datasetChoices}{Character vector of CMIDs representing the selected datasets.}

\item{database}{Character string specifying the database to use. (default: "SocioMap" -- "ArchaMap" is the other option)}

\item{intersection}{Boolean value specifying whether to return the intersection of the datasets or all categories. (default: FALSE)}
}
\value{
Dataframe containing proposed merge information.
\itemize{
\item datasetID: Character string representing the dataset ID.
\item Key: Character string representing a unique identifier for the merge.
\item CMName: Character string representing the category name.
\item CMID: Character string representing the category ID.
\item Name: Character string representing a semicolon-separated list of dataset names.
}
}
\description{
This function propose a merge based on a category domain and selected datasets.
It then processes the response and returns a list of dictionaries containing proposed merge information.
}
\examples{

categoryLabel <- c("ETHNICITY")
datasetChoices <- c("SD5", "SD6")
merged_data <- createLinkfile(categoryLabel, datasetChoices)

}
