library(shiny)
library(tidyquant)
library(ggplot2)
library(dplyr)
library(lubridate)
library(plotly)

# Define stock indices and corresponding country names
indices <- c(
  "^GSPC" = "United States (S&P 500)",
  "^HSI" = "Hong Kong (Hang Seng)",
  "^GDAXI" = "Germany (DAX)",
  "^N225" = "Japan (Nikkei 225)",
  "^AXJO" = "Australia (ASX 200)",
  "^FCHI" = "France (CAC 40)",
  "^GSPTSE" = "Canada (TSX)",
  "^STI" = "Singapore (STI)",
  "^FTSE" = "United Kingdom (FTSE 100)",
  "^KS11" = "South Korea (KOSPI)" # South Korea will be black
)

# Fetch stock data efficiently for all indices at once
get_stock_data <- function(symbols) {
  tryCatch({
    data <- tq_get(symbols, from = "1996-01-01", to = "2024-12-31", get = "stock.prices") %>%
      select(symbol, date, adjusted) %>%
      mutate(
        YearMonth = format(date, "%Y-%m"),
        Country = indices[symbol]
      ) %>%
      group_by(symbol, YearMonth, Country) %>%
      summarize(Close = last(adjusted), .groups = "drop")
    return(data)
  }, error = function(e) {
    message("Error fetching data: ", conditionMessage(e))
    return(NULL)
  })
}

# Download all stock data
stock_data <- get_stock_data(names(indices))

# Stop execution if no data is retrieved
if (is.null(stock_data) || nrow(stock_data) == 0) {
  stop("No stock data was retrieved. Check your internet connection and API limits.")
}

# Generate distinct colors for each country, except South Korea (which will be black)
color_palette <- setNames(scales::hue_pal()(length(indices)), indices)
color_palette["South Korea (KOSPI)"] <- "black"  # South Korea is always black

# UI
ui <- fluidPage(
  titlePanel("Interactive Stock Market Indices (1996-2024)"),
  
  # Expand layout width
  fluidRow(
    column(width = 12, align = "center",
           plotlyOutput("stock_plot", height = "550px") # Enlarged graph
    )
  ),
  
  hr(),  # Separation line
  
  # UI controls below graph
  fluidRow(
    column(width = 10, offset = 1,
           h4("Select Base Year-Month:"),
           sliderInput("base_date", "Base Year-Month", 
                       min = as.Date(min(paste0(stock_data$YearMonth, "-01"))), 
                       max = as.Date(max(paste0(stock_data$YearMonth, "-01"))), 
                       value = as.Date("2000-01-01"), 
                       timeFormat = "%Y-%m", step = 30, width = "100%"),  # Full-width slider
           helpText("This adjusts all indices so the selected date equals 1.", style = "text-align:center;")
    )
  )
)

# Server
server <- function(input, output, session) {
  
  adjusted_data <- reactive({
    req(input$base_date)
    base_date <- input$base_date
    base_values <- stock_data %>%
      filter(YearMonth == format(base_date, "%Y-%m")) %>%
      select(symbol, Close) %>%
      rename(BaseClose = Close)
    
    stock_data %>%
      left_join(base_values, by = "symbol") %>%
      mutate(AdjustedClose = Close / BaseClose) %>%
      filter(!is.na(AdjustedClose))
  })
  
  output$stock_plot <- renderPlotly({
    p <- ggplot(adjusted_data(), aes(
      x = as.Date(paste0(YearMonth, "-01")), 
      y = AdjustedClose, 
      color = Country, 
      group = Country
    )) +
      geom_line(size = 1.2, alpha = 0.85) +
      scale_color_manual(values = color_palette) +
      geom_vline(xintercept = as.numeric(input$base_date), linetype = "dashed", color = "red", size = 1.2) +
      labs(
        title = "Stock Market Indices (Adjusted to Base Year-Month = 1)",
        x = "Year",
        y = "Relative Performance",
        color = "Country"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        legend.position = "bottom", 
        legend.text = element_text(size = 12), 
        plot.title = element_text(hjust = 0.5, size = 16)
      )
    
    ggplotly(p) %>% layout(legend = list(orientation = "h", x = 0.5, xanchor = "center"))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

# shiny::runApp("c:/Users/user/Dropbox/Teaching/BUSS254-Slides/app")

# rsconnect::deployApp("c:/Users/user/Dropbox/Teaching/BUSS254-Slides/app", appName = "buss254-stock-app")