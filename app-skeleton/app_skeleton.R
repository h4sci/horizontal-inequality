set.seed(42) 

library(shiny)
library(tidyverse)
library(leaflet)
library(rnaturalearth) #for world map
library(sf)

world <- ne_countries(scale = "medium", returnclass = "sf") %>% 
  select(name_long, brk_name, iso_a3)
 
# generate some dummy data
country <- c(rep("KEN", 6), 
             rep("GHA", 6))
outcome_var <- c(
  rep(c(
    rep("wealth", 3),
    rep("mortality", 3)), 2))
grouping_var <- c(rep(c("gender", "ethnicity", "religion"), 4))
ggini <- c(rnorm(12))
ggini <- (ggini - min(ggini)) / (max(ggini)-min(ggini))

# bind to dataframe
data <- tibble(country, outcome_var, grouping_var, ggini)

# user interface
ui <- bootstrapPage(
  titlePanel(title = "Horizontal inequality in SSA"),
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 100, right = 50,
                selectInput("outcome_var", "Outcome variable", unique(data$outcome_var)
                ),
                selectInput("grouping_var", "Grouping", unique(data$grouping_var)
                )
  )
)

# server function
server <- function(input, output, session) {
  initial_lat = 10
  initial_lng = -30
  initial_zoom = 2
  
  output$map <- renderLeaflet({
    world_ext <- world %>% 
      full_join(data, by = c("iso_a3" = "country")) %>% 
      filter(outcome_var == input$outcome_var,
             grouping_var == input$grouping_var)
  
    #quantile(world_ext$value, na.rm = T)
    #c(0,as.vector(quantile(world_ext$value, na.rm = T)),Inf)
    
    #bins <- c(0, 200, 1500, 4000, 13000, 4000000)
    bins <- c(0,as.vector(quantile(world_ext$ggini, na.rm = T)),Inf)
    pal <- colorBin("viridis", domain = world_ext$ggini, bins = bins)
    
    labels <- sprintf("<strong>%s</strong><br/>%g $ / worker",
                      world_ext$name_long, world_ext$ggini) %>%
      lapply(htmltools::HTML)
    
    
    leaflet(world_ext) %>% 
      setView(lat = initial_lat, lng = initial_lng, zoom = initial_zoom) %>% 
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
  })
}

shinyApp(ui, server)