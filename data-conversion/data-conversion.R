## CONVERT ALL FILES IN A DIRECTORY
library(readr)
library(haven)
## Convert all files in wd from DTA to CSV
for (f in Sys.glob("./raw-data/*.dta")) {
  write_csv(read_dta(f), file = gsub('dta$', 'csv', f))
}


