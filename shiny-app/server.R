# Server 

server <- function(input, output, session) {
  
  # initial zoom set to SSA
  initial_lat = 0
  initial_lng = 20
  initial_zoom = 2
  
  output$map <- renderLeaflet({
    world_ext <- world %>% 

      right_join(data, by = c("iso_a3" = "ISO")) %>% 
      filter(outcome_var == input$outcome_var,
             grouping_var == input$grouping_var, 
             measure == input$measure,
             year == input$year)
    
    bins <- round(as.vector(quantile(world_ext$gini_value, na.rm = T)), digits = 2)
    pal <- colorBin("Blues", domain = world_ext$gini_value, bins = bins)
    
    labels <- sprintf("<strong>%s</strong><br/>%g",
                      world_ext$name_long, round(world_ext$gini_value, digits = 2)) %>%
      lapply(htmltools::HTML)
    
    
    leaflet(world_ext) %>% 
      setView(lat = initial_lat, lng = initial_lng, zoom = initial_zoom) %>% 
      addTiles() %>% 
      addPolygons(fillColor = ~pal(gini_value),

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
      addLegend(pal = pal, values = ~gini_value, opacity = 0.7,

                position = "bottomright",
                title = "Quantiles of Gini-Coefficient")
  })
}

