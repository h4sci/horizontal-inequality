# global script for functions and data manipulation

library(tidyverse)
library(shiny)
library(shinyWidgets)
library(leaflet)
library(rnaturalearth) #for world map
library(sf)

# get world map as sf object
world <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  select(name_long, brk_name, iso_a3)

# define coordinate reference system
 st_crs(world) = 4326

# read inequality data

master_data <- read_csv("master_data_ISO_phase.csv")

# make long format 
data <- master_data %>% 
  select(country, year, ISO, phase, "grouping_var" = category, measure, gini_sch, gini_chm, gini_st, gini_wlth) %>% 
  pivot_longer(cols = starts_with("gini_"), names_to = "outcome_var", values_to = "gini_value") %>% 
  mutate(outcome_var = fct_recode(outcome_var,
                                  "Schooling" = "gini_sch",
                                  "Child mortality" = "gini_chm",
                                  "Stunting" = "gini_st",
                                  "Wealth" = "gini_wlth"),
         grouping_var = fct_recode(grouping_var,
                                   "Urban/Rural" = "region",
                                   "Gender" = "gender",
                                   "Religion" = "religion",
                                   "Ethnicity" = "ethnicity")
         ) %>% 
  group_by(country, grouping_var, measure, outcome_var) %>% 
  mutate(lag = lag(gini_value))