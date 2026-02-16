pkgname <- "CatMapR"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('CatMapR')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("CMIDinfo")
### * CMIDinfo

flush(stderr()); flush(stdout())

### Name: CMIDinfo
### Title: Retrieve Details for a Specific CMID (CatMapperID)
### Aliases: CMIDinfo

### ** Examples

CMIDinfo(database = "SocioMap", cmid = "SM1")
CMIDinfo(database = "ArchaMap", cmid = "AM1")



cleanEx()
nameEx("allDatasets")
### * allDatasets

flush(stderr()); flush(stdout())

### Name: allDatasets
### Title: Retrieve All Datasets from a Specified Database
### Aliases: allDatasets

### ** Examples

allDatasets(database = "SocioMap")
allDatasets(database = "ArchaMap")



cleanEx()
nameEx("callAPI")
### * callAPI

flush(stderr()); flush(stdout())

### Name: callAPI
### Title: Call API
### Aliases: callAPI

### ** Examples

CatMapR:::callAPI(endpoint = "search", parameters = list(term = "Dan", database = "SocioMap", property = "Name", domain = "ETHNICITY"), request = "GET")



cleanEx()
nameEx("createLinkfile")
### * createLinkfile

flush(stderr()); flush(stdout())

### Name: createLinkfile
### Title: Create Linkfile from Dataset CMIDs
### Aliases: createLinkfile

### ** Examples


categoryLabel <- c("ETHNICITY")
datasetChoices <- c("SD5", "SD6")
merged_data <- createLinkfile(categoryLabel, datasetChoices, equivalence = "standard")




cleanEx()
nameEx("datasetInfo")
### * datasetInfo

flush(stderr()); flush(stdout())

### Name: datasetInfo
### Title: Retrieve Dataset Information by CMID
### Aliases: datasetInfo

### ** Examples

datasetInfo(database = "SocioMap", CMID = "SD1", domain = "CATEGORY")
datasetInfo(database = "ArchaMap", CMID = "AD1")



cleanEx()
nameEx("joinDatasets")
### * joinDatasets

flush(stderr()); flush(stdout())

### Name: joinDatasets
### Title: Join Datasets by Key
### Aliases: joinDatasets

### ** Examples

joinLeft = data.frame(datasetID = "SD1", country = "Afghanistan", GID = "AFG", val0 = 1)
joinRight = data.frame(datasetID = "SD2", country = "Afghanistan", geonameid = "1149361", val1 = 2)
joinDatasets("SocioMap", joinLeft, joinRight, domain = "CATEGORY")



cleanEx()
nameEx("searchDatabase")
### * searchDatabase

flush(stderr()); flush(stdout())

### Name: searchDatabase
### Title: Search
### Aliases: searchDatabase

### ** Examples

searchDatabase(database = "SocioMap", domain = "ETHNICITY", term = "Dan", property = "Name")



cleanEx()
nameEx("translate")
### * translate

flush(stderr()); flush(stdout())

### Name: translate
### Title: Translate
### Aliases: translate

### ** Examples

df = data.frame(country = "Afghanistan")
translate(rows = df, database = "SocioMap",domain = "ADM0", term = "country", property = "Name", yearStart = NULL, yearEnd = NULL, country = NULL, context = NULL, query = 'false')



### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
