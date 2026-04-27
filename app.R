library(shiny)
library(tidyverse)
library(nnet)
library(caret)

cat("Loading saved models...\n")
pitcher_models <- readRDS("pitcher_models_basic.rds")
pitch_data_features <- readRDS("pitch_data_features_basic.rds")
model_evaluations <- readRDS("model_evaluations_basic.rds")
cat("Models loaded successfully!\n")
cat("Total models:", length(pitcher_models), "\n")

# ============================================================================
# SHINY APP UI
# ============================================================================

ui <- fluidPage(
  titlePanel("MLB Pitch Sequence Predictor"),
  
  tags$head(
    tags$style(HTML("
      .info-box {
        background-color: #e3f2fd;
        border-left: 4px solid #1976d2;
        padding: 10px;
        margin-bottom: 15px;
      }
      .metric-box {
        text-align: center;
        padding: 15px;
        border-radius: 5px;
        margin-bottom: 10px;
      }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      div(class = "info-box",
          p("This app uses a model that predicts the next pitch type based on",
            "previous pitch sequence (pitch type and location), count, and batter handedness.")),

      selectInput("pitcher", "Select Pitcher:", choices = sort(names(pitcher_models)), selected = names(pitcher_models)[1]),
      
      hr(),

      h4("Current Count:"),
      fluidRow(
        column(6, selectInput("balls", "Balls:", choices = 0:3, selected = 1)),
        column(6, selectInput("strikes", "Strikes:", choices = 0:2, selected = 1))
      ),
      
      selectInput("stand", "Batter Stands:", choices = c("Right" = "R", "Left" = "L"), selected = "R"),
      
      hr(),
      
      h4("Previous Pitch (Most Recent):"),
      p(em("Required")),
      fluidRow(
        column(6, selectInput("prev_pitch_1", "Pitch Type:", choices = sort(unique(as.character(pitch_data_features$pitch_type))), selected = "FF")),
        column(6, selectInput("prev_zone_1", "Zone:", choices = 1:14,selected = "5"))
      ),
      
      h4("2nd Previous Pitch:"),
      fluidRow(
        column(6, selectInput("prev_pitch_2", "Pitch Type:", choices = c("None" = "", sort(unique(as.character(pitch_data_features$pitch_type)))), selected = "CH")),
        column(6, selectInput("prev_zone_2", "Zone:", choices = c("None" = "", 1:14), selected = "8"))
      ),
      
      hr(),
      
      actionButton("predict", "Predict Next Pitch", class = "btn-primary btn-lg btn-block"),
      
      hr(),
      
      h4("Pitch Type Abbreviations", style = "margin-top: 20px;"),
      tags$div(style = "font-size: 11px; line-height: 1.4;",
               HTML("
          <strong>CH</strong> - Changeup<br>
          <strong>CU</strong> - Curveball<br>
          <strong>FC</strong> - Cutter<br>
          <strong>EP</strong> - Eephus<br>
          <strong>FO</strong> - Forkball<br>
          <strong>FF</strong> - Four-Seam Fastball<br>
          <strong>KN</strong> - Knuckleball<br>
          <strong>KC</strong> - Knuckle-curve<br>
          <strong>SC</strong> - Screwball<br>
          <strong>SI</strong> - Sinker<br>
          <strong>SL</strong> - Slider<br>
          <strong>SV</strong> - Slurve<br>
          <strong>FS</strong> - Splitter<br>
          <strong>ST</strong> - Sweeper
        ")
      ),
      
      hr(),

      h4("Previous Pitch Zone Location"),
      p(em("Highlighted zone from most recent pitch (Catcher's view)")),
      plotOutput("zone_plot_sidebar", height = "220px")
    ),
    
    mainPanel(
      width = 9,

      fluidRow(
        column(12,
               wellPanel(
                 h3("Model Performance for Selected Pitcher"),
                 fluidRow(
                   column(4,
                          div(class = "metric-box", style = "background-color: #bbdefb;",
                              h4(textOutput("model_accuracy_text"), style = "color: #0d47a1; margin: 0;"),
                              p("Model Accuracy", style = "margin: 5px 0 0 0;")
                          )
                   ),
                   column(4,
                          div(class = "metric-box", style = "background-color: #fff9c4;",
                              h4(textOutput("baseline_text"), style = "color: #f57f17; margin: 0;"),
                              p("Baseline Accuracy", style = "margin: 5px 0 0 0;")
                          )
                   ),
                   column(4,
                          div(class = "metric-box", style = "background-color: #c8e6c9;",
                              h4(textOutput("improvement_text"), style = "color: #1b5e20; margin: 0;"),
                              p("Improvement", style = "margin: 5px 0 0 0;")
                          )
                   )
                 )
               )
        )
      ),
      
      fluidRow(
        column(12,
               wellPanel(
                 h3("Predicted Next Pitch Type"),
                 fluidRow(
                   column(6,
                          h2(textOutput("predicted_pitch"), 
                             style = "color: #e74c3c; font-weight: bold; margin-top: 0;"),
                          h5(textOutput("pitch_prob"), style = "color: #34495e;")
                   ),
                   column(6,
                          h4("Confidence Level:"),
                          plotOutput("confidence_gauge", height = "100px")
                   )
                 )
               )
        )
      ),

      fluidRow(
        column(6,
               wellPanel(
                 h3("All Pitch Type Probabilities"),
                 tableOutput("prob_table")
               )
        ),
        column(6,
               wellPanel(
                 h3("Probability Distribution"),
                 plotOutput("prob_plot", height = "400px")
               )
        )
      ),

      fluidRow(
        column(12,
               wellPanel(
                 h3("Current Sequence Context"),
                 verbatimTextOutput("sequence_summary")
               )
        )
      ),

      fluidRow(
        column(12,
               wellPanel(
                 h3("Historical Pitch Type Distribution"),
                 plotOutput("pitcher_distribution", height = "300px")
               )
        )
      )
    )
  )
)

# ============================================================================
# ZONE PLOT HELPER FUNCTION
# ============================================================================

build_zone_plot <- function(selected_zone) {
  
  zones_df <- data.frame(
    zone  = c(11, 12, 14, 13, 1, 2, 3, 4, 5, 6, 7, 8, 9),
    x     = c( 0,  4,  0,  4, 1, 2, 3, 1, 2, 3, 1, 2, 3),
    y     = c( 4,  4,  0,  0, 3, 3, 3, 2, 2, 2, 1, 1, 1),
    label = as.character(c(11, 12, 14, 13, 1:9)))
  
  zones_df <- zones_df %>%
    mutate(
      fill_color = ifelse(label == as.character(selected_zone), "#e74c3c", ifelse(zone %in% 1:9, "#bbdefb", "#e8f5e9")),
      xmin = x,
      xmax = x + 1,
      ymin = y,
      ymax = y + 1)
  
  ggplot(zones_df) +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill_color), color = "grey40", linewidth = 0.6) +
    geom_text(aes(x = xmin + 0.5, y = ymin + 0.5, label = label), size = 3.5, fontface = "bold", color = "grey20") +
    annotate("rect", xmin = 1, xmax = 4, ymin = 1, ymax = 4, fill = NA, color = "#1976d2", linewidth = 1.4) +
    scale_fill_identity() +
    coord_fixed(ratio = 1) +
    labs(x = NULL, y = NULL) +
    theme_void(base_size = 10)
}

# ============================================================================
# SHINY APP SERVER
# ============================================================================

server <- function(input, output, session) {

  output$zone_plot_sidebar <- renderPlot({
    req(input$prev_zone_1)
    build_zone_plot(input$prev_zone_1)
  }, bg = "transparent")
  
  pitcher_accuracy <- reactive({
    pitcher_name <- input$pitcher
    if (pitcher_name %in% names(model_evaluations)) {
      model_evaluations[[pitcher_name]]$accuracy
    } else {
      NA
    }
  })
  
  pitcher_baseline <- reactive({
    pitcher_name <- input$pitcher
    pitcher_data <- pitch_data_features %>%
      filter(player_name == pitcher_name)
    
    if (nrow(pitcher_data) > 0) {
      most_common_count <- max(table(pitcher_data$pitch_type))
      return(most_common_count / nrow(pitcher_data))
    } else {
      return(NA)
    }
  })
  
  pitcher_improvement <- reactive({
    acc      <- pitcher_accuracy()
    baseline <- pitcher_baseline()
    if (!is.na(acc) && !is.na(baseline)) acc - baseline else NA
  })
  
  output$model_accuracy_text <- renderText({
    acc <- pitcher_accuracy()
    if (!is.na(acc)) paste0(round(acc * 100, 1), "%") else "N/A"
  })
  
  output$baseline_text <- renderText({
    baseline <- pitcher_baseline()
    if (!is.na(baseline)) paste0(round(baseline * 100, 1), "%") else "N/A"
  })
  
  output$improvement_text <- renderText({
    improvement <- pitcher_improvement()
    if (!is.na(improvement)) {
      sign <- ifelse(improvement >= 0, "+", "")
      paste0(sign, round(improvement * 100, 1), "%")
    } else {
      "N/A"
    }
  })
  
  # ---- Prediction ----
  prediction_result <- eventReactive(input$predict, {
    
    pitcher_name <- input$pitcher
    
    if (!pitcher_name %in% names(pitcher_models)) {
      return(list(error = "No model available for this pitcher"))
    }
    
    prev_pitch_2 <- if (input$prev_pitch_2 == "") NA else input$prev_pitch_2
    prev_zone_2  <- if (input$prev_zone_2  == "") NA else input$prev_zone_2
    
    new_data <- data.frame(
      prev_pitch_type_1 = factor(input$prev_pitch_1, levels = levels(pitch_data_features$prev_pitch_type_1)),
      prev_zone_1       = factor(input$prev_zone_1,  levels = levels(pitch_data_features$prev_zone_1)),
      prev_pitch_type_2 = factor(prev_pitch_2,       levels = levels(pitch_data_features$prev_pitch_type_2)),
      prev_zone_2       = factor(prev_zone_2,         levels = levels(pitch_data_features$prev_zone_2)),
      balls             = factor(input$balls,         levels = levels(pitch_data_features$balls)),
      strikes           = factor(input$strikes,       levels = levels(pitch_data_features$strikes)),
      stand             = factor(input$stand,         levels = levels(pitch_data_features$stand))
    )
    
    tryCatch({
      predicted_class <- predict(pitcher_models[[pitcher_name]], newdata = new_data, type = "class")
      predicted_probs <- predict(pitcher_models[[pitcher_name]], newdata = new_data, type = "probs")
      
      prob_df <- data.frame(
        Pitch_Type  = names(predicted_probs),
        Probability = as.numeric(predicted_probs)
      ) %>% arrange(desc(Probability))
      
      list(
        predicted_pitch = as.character(predicted_class),
        probabilities   = prob_df,
        error           = NULL
      )
    }, error = function(e) {
      list(predicted_pitch = "Error", probabilities = NULL, error = e$message)
    })
  })
  
  output$predicted_pitch <- renderText({
    result <- prediction_result()
    if (!is.null(result$error)) return("Error in prediction")
    result$predicted_pitch
  })
  
  output$pitch_prob <- renderText({
    result <- prediction_result()
    if (!is.null(result$error) || is.null(result$probabilities)) return("")
    top_prob <- result$probabilities$Probability[1]
    paste0("Probability: ", round(top_prob * 100, 1), "%")
  })
  
  output$confidence_gauge <- renderPlot({
    result <- prediction_result()
    if (!is.null(result$error) || is.null(result$probabilities)) return(NULL)
    
    top_prob <- result$probabilities$Probability[1]
    
    ggplot(data.frame(x = 1, y = top_prob), aes(x = x, y = y)) +
      geom_bar(stat = "identity", fill = "#1976d2", width = 0.5) +
      coord_flip() +
      ylim(0, 1) +
      theme_void() +
      geom_text(aes(label = paste0(round(y * 100, 1), "%")),size = 6, fontface = "bold", hjust = -0.2) +
      theme(plot.margin = margin(5, 5, 5, 5))
  })
  
  output$prob_table <- renderTable({
    result <- prediction_result()
    if (!is.null(result$error) || is.null(result$probabilities)) {
      return(data.frame(Message = "No prediction available"))
    }
    result$probabilities %>%
      mutate(Probability = paste0(round(Probability * 100, 1), "%"))
  }, striped = TRUE, hover = TRUE)
  
  output$prob_plot <- renderPlot({
    result <- prediction_result()
    if (!is.null(result$error) || is.null(result$probabilities)) return(NULL)
    
    ggplot(result$probabilities, aes(x = reorder(Pitch_Type, Probability), y = Probability)) +
      geom_bar(stat = "identity", fill = "#1976d2", alpha = 0.8) +
      geom_text(aes(label = paste0(round(Probability * 100, 1), "%")), hjust = -0.1, size = 4) +
      coord_flip() +
      labs(x = "Pitch Type", y = "Probability", title = "") +
      theme_minimal(base_size = 12) +
      ylim(0, max(result$probabilities$Probability) * 1.15)
  })
  
  output$sequence_summary <- renderText({
    prev_1 <- paste0(input$prev_pitch_1, " in zone ", input$prev_zone_1)
    prev_2 <- if (input$prev_pitch_2 == "") "None" else paste0(input$prev_pitch_2, " in zone ", input$prev_zone_2)
    
    paste0(
      "Pitcher: ", input$pitcher, "\n",
      "Count: ", input$balls, "-", input$strikes, "\n",
      "Batter: ", ifelse(input$stand == "R", "Right-handed", "Left-handed"), "\n\n",
      "Pitch Sequence:\n",
      "Most Recent: ", prev_1, "\n",
      "2nd Previous: ", prev_2, "\n\n",
      "Model Features: Previous pitch types, zones, count, and batter handedness"
    )
  })
  
  output$pitcher_distribution <- renderPlot({
    pitcher_name <- input$pitcher
    pitcher_data <- pitch_data_features %>%
      filter(player_name == pitcher_name)
    
    if (nrow(pitcher_data) == 0) return(NULL)
    
    pitch_counts <- pitcher_data %>%
      group_by(pitch_type) %>%
      summarise(count = n()) %>%
      mutate(percentage = count / sum(count))
    
    ggplot(pitch_counts, aes(x = reorder(pitch_type, -percentage), y = percentage)) +
      geom_bar(stat = "identity", fill = "#388e3c", alpha = 0.8) +
      geom_text(aes(label = paste0(round(percentage * 100, 1), "%")), vjust = -0.5, size = 4) +
      labs(x = "Pitch Type", y = "Percentage of Pitches", title = paste0("Historical pitch distribution for ", pitcher_name)) +
      theme_minimal(base_size = 12) +
      ylim(0, max(pitch_counts$percentage) * 1.15)
  })
}

# Run the app
shinyApp(ui = ui, server = server)
