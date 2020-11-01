library(tidyverse)
# reading stata .dta datasets
library(haven) 
# convenient functions to process and summarize labelled data
library(sjmisc)
library(sjlabelled)
# %<>% pipe operator
library(magrittr)
# Multiple correspondence analysis
library(FactoMineR)
library(factoextra)

# read example data from ghana and kenya
gha_mrir <- read_dta("raw-data/ghana_men&women_2014.dta")
gha_pr <- read_dta("raw-data/ghana_ai_men&women_2014.dta")

ken_mr_ir <- read_dta("raw-data/kenya_men&women_2014.dta")
ken_pr <- read_dta("raw-data/ghana_ai_men&women_2014.dta")

# sample weights
gha_mrir %<>% 
  mutate(wgt = v005/1000000)
gha_pr %<>%
  mutate(wgt = hv005/1000000)

