# global script for functions and data manipulation

library(tidyverse)
library(shiny)
library(tidyverse)
library(leaflet)
library(rnaturalearth) #for world map
library(sf)

# get world map as sf object
world <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  select(name_long, brk_name, iso_a3)

# define coordinate reference system
st_crs(world) = 4326

# read inequality data
# Note: I had to set the precise path of the .csv file despite working in the project 
master_data <- read_csv("raw-data/master_data.csv")

# make long format 
data <- master_data %>% 
  select(country, year, "grouping_var" = category, measure, gini_sch, gini_chm, gini_chm, gini_wlth) %>% 
  pivot_longer(cols = starts_with("gini_"), names_to = "outcome_var", values_to = "gini_value") %>% 
  filter(year>=2013)
 

