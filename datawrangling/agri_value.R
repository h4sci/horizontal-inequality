#data preparation script

library(tidyverse)
library(leaflet)
library(rnaturalearth) #for world map
library(sf)

world <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  select(name_long, brk_name, iso_a3)

data <- read_csv(file = "agriculture-value-added-per-worker-wdi.csv") 

data <- data %>% 
  drop_na(code) %>% 
  mutate(value = round(value, digits = 0))

world_ext <- world %>% 
  full_join(data, by = c("iso_a3" = "code")) %>% 
  filter(year == 2011)

quantile(world_ext$value, na.rm = T)

bins <- c(0, 200, 1500, 4000, 13000, 4000000)
pal <- colorBin("viridis", domain = world_ext$value, bins = bins)

labels <- sprintf("<strong>%s</strong><br/>%g $ / worker",
                  world_ext$name_long, world_ext$value) %>%
  lapply(htmltools::HTML)


leaflet(world_ext) %>% 
  addTiles() %>% 
  addPolygons(fillColor = ~pal(value),
              weight = 2,
              opacity = 1,
              color = "white",
              dashArray = "2",
              fillOpacity = 0.7,
              highlight = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
              label = labels,
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>% 
  addLegend(pal = pal, values = ~value, opacity = 0.7,
            position = "bottomright",
            title = "Agriculture value added<br>(in 2010 constant $)")
