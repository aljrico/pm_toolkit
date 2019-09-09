#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(data.table)
source('source/update_prize_tent.R')

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("PM Balance Data Toolkit"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            actionButton('button.update_prize_tent', 'Update Prize Tent')
        ),

        # Show a plot of the generated distribution
        mainPanel(
            "Hello World"
        )
    )
))
