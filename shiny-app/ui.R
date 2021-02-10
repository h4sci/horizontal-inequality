#Shiny app: Horizontal inequality in Sub-Sahara Africa


# user interface ----------------------------------------------------------

ui <- bootstrapPage(
  titlePanel(title = "Horizontal Inequality in Sub-Sahara Africa"),
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = "30%", left = "2%",
                selectInput("outcome_var", "Outcome variable", unique(data$outcome_var)
                ),
                selectInput("grouping_var", "Grouping", unique(data$grouping_var), selected = "Gender"
                ),
                selectInput("measure", "Pop. weighting", unique(data$measure), selected = "Weighted"
                ),
                chooseSliderSkin("Flat"),
                setSliderColor("grey", 1),
                sliderInput("year", "Year", min = min(data$year), max = max(data$year), value = max(data$year), step = 1, sep = ""),

  )
)

