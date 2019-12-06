#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyWidgets)
library(shinyjs)
library(tidyverse)
library(data.table)
source("source/update_prize_tent.R")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  shinyjs::useShinyjs(),
  shiny::includeCSS("www/animate.css"),

  tags$head(
    tags$link(href = "https://fonts.googleapis.com/css?family=Fjalla+One|Roboto+Slab:300,400&display=swap", rel = "stylesheet"),
    tags$link(href = "styles.css", rel = "stylesheet", type = "text/css")
  ),

  tags$div(
    class = "title",
    tags$br(),
    tags$h1("Balance Data Toolkit", class = "title"),
    tags$br(),

    tags$span(icon("bolt"), class = "main-icon")
  ),
  
  tags$style(HTML("
        .tabs-above > .nav > li[class=active] > a {
           background-color: #000;
           color: #FFF;
        }")),

  verticalTabsetPanel(
    verticalTabPanel("PrizeTent", fluid = TRUE, box_height = "70px", color = '#b2ba11',
      sidebarLayout(
        sidebarPanel(
          textInput("prize_tent.text.spreadsheet_name", "Spreadsheet Name", value = "(HS) Mysteryboxes"),
          selectInput("prize_tent.combobox.game_location", "Game Folder Name", choices = c("homestreet", "spark")),
          actionButton("prize_tent.button.update_prize_tent", "Update Prize Tent")
        ),
        mainPanel(
          shinyjs::hidden(
            div(
              id = "loading_page",
              class = "loading-content",
              h2(class = "animated infinite pulse", "Loading data..."),
              align = "center"
            )
          )
        )
      )
    )
  )
))
