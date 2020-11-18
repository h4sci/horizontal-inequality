library(shiny)
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


ui <- bootstrapPage(
    titlePanel(title = "Agriculture value added"),
    tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
    leafletOutput("map", width = "100%", height = "100%"),
    absolutePanel(top = 100, right = 50,
                  sliderInput("year", "Year", min(data$year), max(data$year),
                              value = 2010
                  )
                  
    )
)

server <- function(input, output, session) {
    initial_lat = 10
    initial_lng = -30
    initial_zoom = 2
    
    output$map <- renderLeaflet({
        world_ext <- world %>% 
            full_join(data, by = c("iso_a3" = "code")) %>% 
            filter(year == input$year)
        
        #quantile(world_ext$value, na.rm = T)
        #c(0,as.vector(quantile(world_ext$value, na.rm = T)),Inf)
        
        #bins <- c(0, 200, 1500, 4000, 13000, 4000000)
        bins <- c(0,as.vector(quantile(world_ext$value, na.rm = T)),Inf)
        pal <- colorBin("viridis", domain = world_ext$value, bins = bins)
        
        labels <- sprintf("<strong>%s</strong><br/>%g $ / worker",
                          world_ext$name_long, world_ext$value) %>%
            lapply(htmltools::HTML)
        
        
        leaflet(world_ext) %>% 
            setView(lat = initial_lat, lng = initial_lng, zoom = initial_zoom) %>% 
            addProviderTiles(providers$Esri.WorldStreetMap) %>% 
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