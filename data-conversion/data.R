## CONVERT ALL FILES IN A DIRECTORY

library(haven)

## Set working directory in which dtw files can be found)
setwd("~/Desktop")

## Convert all files in wd from DTA to CSV
### Note: alter the write/read functions for different file types.  dta->csv used in this specific example

for (f in Sys.glob('*.dta')) 
  write.csv(read.dta(f), file = gsub('dta$', 'csv', f))