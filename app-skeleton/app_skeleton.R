#Shiny app: Horizontal inequality in Sub-Sahara Africa

library(shiny)
library(tidyverse)
library(leaflet)
library(rnaturalearth) #for world map
library(sf)

# get world map as sf object
world <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  select(name_long, brk_name, iso_a3)

# generate some dummy data
set.seed(42) 

country <- c(rep("KEN", 6), rep("GHA", 6))
outcome_var <- c(rep(c(rep("wealth", 3),rep("mortality", 3)), 2))
grouping_var <- c(rep(c("gender", "ethnicity", "religion"), 4))
ggini <- c(rnorm(12))
ggini <- (ggini - min(ggini)) / (max(ggini)-min(ggini))

# bind to dataframe
data <- tibble(country, outcome_var, grouping_var, ggini)


# user interface ----------------------------------------------------------

ui <- bootstrapPage(
  titlePanel(title = "Horizontal inequality in Sub-Sahara Africa"),
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 600, left = 400,
                selectInput("outcome_var", "Outcome variable", unique(data$outcome_var)
                ),
                selectInput("grouping_var", "Grouping", unique(data$grouping_var)
                )
  )
)


# server ------------------------------------------------------------------

server <- function(input, output, session) {

# initial zoom set to SSA
  initial_lat = 0
  initial_lng = 20
  initial_zoom = 3.5
  
  output$map <- renderLeaflet({
    world_ext <- world %>% 
      right_join(data, by = c("iso_a3" = "country")) %>% 
      filter(outcome_var == input$outcome_var,
             grouping_var == input$grouping_var)
    
    bins <- as.vector(quantile(world_ext$ggini, na.rm = T))
    pal <- colorBin("viridis", domain = world_ext$ggini, bins = bins)
    
    labels <- sprintf("<strong>%s</strong><br/>%g",
                      world_ext$name_long, round(world_ext$ggini, digits = 2)) %>%
      lapply(htmltools::HTML)
    
    
    leaflet(world_ext) %>% 
      setView(lat = initial_lat, lng = initial_lng, zoom = initial_zoom) %>% 
      addTiles() %>% 
      addPolygons(fillColor = ~pal(ggini),
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
      addLegend(pal = pal, values = ~ggini, opacity = 0.7,
                position = "bottomright",
                title = "Quantiles of Gini-Coefficient")
  })
}

shinyApp(ui, server)
