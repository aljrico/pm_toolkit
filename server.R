#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    
    observeEvent(input$prize_tent.button.update_prize_tent, {
        shinyjs::show('loading_page')
        update_prize_tent()
        shinyjs::hide('loading_page')
        
        sendSweetAlert(
            session = session,
            title = "Done!",
            text = "Prize Tent Updated",
            type = "success"
        )
        
    })
})
