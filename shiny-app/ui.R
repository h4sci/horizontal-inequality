#Shiny app: Horizontal inequality in Sub-Sahara Africa


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

