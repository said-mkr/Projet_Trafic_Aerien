# app/app.R
library(shiny)
library(shinydashboard)
library(DBI)
library(RSQLite)
library(DT)
library(ggplot2)
library(dplyr)
library(jsonlite)

# répertoire local synchronisé avec HDFS (par sync_hdfs_json.sh)
json_dir <- "/srv/shiny-server/live_json"

cat("--- [DEBUG] Début app.R ---\n")

# connexion SQLite de secours (via scripts/db_connect.R)
flights_db <- NULL
try({
  source("scripts/db_connect.R")
  cat("--- [DEBUG] source db_connect.R OK ---\n")
}, silent = TRUE)


# fonction pour lire et concaténer tous les fichiers JSON du dossier
read_all_json <- function(dir) {
  files <- list.files(dir, pattern = "^part-.*\\.json$", full.names = TRUE)
  if (length(files) == 0) return(tibble())
  dfs <- lapply(files, function(f) {
    tryCatch(fromJSON(f, simplifyDataFrame=TRUE), error=function(e) NULL)
  })
  dfs <- dfs[!sapply(dfs,is.null)]
  if (length(dfs)==0) return(tibble())
  bind_rows(dfs)
}

ui <- dashboardPage(
  dashboardHeader(title="📊 Dashboard Trafic Aérien"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("JSON brut",      tabName="json_viz", icon=icon("file-code")),
      menuItem("Vue Globale",    tabName="global",   icon=icon("chart-bar")),
      menuItem("Retards",        tabName="delays",   icon=icon("clock")),
      menuItem("Par Compagnie",  tabName="by_carrier", icon=icon("plane")),
      menuItem("Tableau",        tabName="table",    icon=icon("table"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem("json_viz",
        fluidRow(
          box(title="Aperçu des JSON (live)", width=12, DTOutput("jsonRawDT"))
        )
      ),
      tabItem("global",
        fluidRow(
          box(title="Volume par destination", width=6, plotOutput("destPlot")),
          box(title="Résumé Stats",          width=6, verbatimTextOutput("stats"))
        )
      ),
      tabItem("delays",
        fluidRow(
      box(title="Retard moyen par compagnie", width=12, plotOutput("delayPlot")),
      box(title="Top 10 vols les plus retardés", width=12, plotOutput("topDelayFlightsPlot")),
      box(title="Histogramme des retards d'arrivée", width=12, plotOutput("delayHistPlot"))
        )
      ),
      # (onglet "Par Compagnie" retiré)
      tabItem("table",

        fluidRow(
          box(title="Tous les vols", width=12, DTOutput("flightTable"))
        )
      )
    )
  )
)

server <- function(input, output, session) {

  # réactive qui scrute le dossier toutes les 5s
  flights_json <- reactivePoll(
    5000, session,
    checkFunc = function() {
      # toute modification du listing de fichiers déclenche rafraîchissement
      list.files(json_dir, recursive=FALSE)
    },
    valueFunc = function() {
      read_all_json(json_dir)
    }
  )

  # fusion JSON vs SQLite (accepte JSON même si arr_delay absent)
  get_flights <- reactive({
    dfj <- flights_json()
    if (nrow(dfj)>0 && all(c("origin","dest","carrier","dep_delay") %in% colnames(dfj))) {
      cat("--- [DEBUG] JSON utilisé (", nrow(dfj), "lignes)\n")
      return(dfj)
    }
    if (!is.null(flights_db) && nrow(flights_db)>0) {
      cat("--- [DEBUG] SQLite DB utilisé (", nrow(flights_db), "lignes)\n")
      return(flights_db)
    }
    cat("--- [DEBUG] Pas de données dispo\n")
    tibble()
  })

  # JSON brut
  output$jsonRawDT <- renderDT({
    df <- get_flights()
    if (nrow(df)==0) {
      datatable(data.frame(Message="Aucune donnée JSON / DB"))
    } else {
      datatable(df, options=list(pageLength=10, scrollX=TRUE))
    }
  })

  # stats
  output$stats <- renderPrint({
    df <- get_flights()
    if (nrow(df)==0) return(cat("Aucune donnée."))
    summary(df)
  })

  # volume par dest
  output$destPlot <- renderPlot({
    df <- get_flights()
    if (nrow(df)==0) {
      plot.new(); title("Pas de données")
      return()
    }
    df %>%
      count(dest, name="vols") %>%
      top_n(15, vols) %>%
      ggplot(aes(reorder(dest, vols), vols)) +
        geom_col(fill="steelblue") + coord_flip() +
        labs(x="Destination", y="Nombre de vols")
  })

  # retard moyen par compagnie (affiche message si arr_delay absent)
  # retard moyen par compagnie (utilise dep_delay si arr_delay absent)
  output$delayPlot <- renderPlot({
    df <- get_flights()
    if (nrow(df)==0 || !"carrier"%in%colnames(df)) {
      plot.new(); title("Pas de données retards")
      return()
    }
    delay_col <- NULL
    if ("arr_delay" %in% colnames(df)) {
      delay_col <- "arr_delay"
      delay_label <- "Retard moyen à l'arrivée (min)"
    } else if ("dep_delay" %in% colnames(df)) {
      delay_col <- "dep_delay"
      delay_label <- "Retard moyen au départ (min)"
    } else {
      plot.new(); title("Aucune colonne de retard trouvée")
      return()
    }
    df %>%
      group_by(carrier) %>%
      summarise(retard=mean(.data[[delay_col]], na.rm=TRUE)) %>%
      top_n(10, retard) %>%
      ggplot(aes(reorder(carrier, retard), retard)) +
        geom_col(fill="tomato") + coord_flip() +
        labs(x="Compagnie", y=delay_label, title="Top 10 compagnies les plus en retard")
  })

  # top 10 vols les plus retardés
  output$topDelayFlightsPlot <- renderPlot({
    df <- get_flights()
    delay_col <- NULL
    delay_label <- NULL
    if (nrow(df)==0 || !"flight_id"%in%colnames(df)) {
      plot.new(); title("Pas de données ou colonne de retard absente")
      return()
    }
    if ("arr_delay" %in% colnames(df)) {
      delay_col <- "arr_delay"
      delay_label <- "Retard à l'arrivée (min)"
    } else if ("dep_delay" %in% colnames(df)) {
      delay_col <- "dep_delay"
      delay_label <- "Retard au départ (min)"
    } else {
      plot.new(); title("Aucune colonne de retard trouvée")
      return()
    }
    df %>%
      arrange(desc(.data[[delay_col]])) %>%
      head(10) %>%
      ggplot(aes(x=reorder(as.character(flight_id), .data[[delay_col]]), y=.data[[delay_col]], fill=carrier)) +
        geom_col() + coord_flip() +
        labs(x="ID Vol", y=delay_label, title="Top 10 vols les plus retardés")
  })

  # histogramme des retards d'arrivée
  output$delayHistPlot <- renderPlot({
    df <- get_flights()
    delay_col <- NULL
    delay_label <- NULL
    if (nrow(df)==0) {
      plot.new(); title("Pas de données")
      return()
    }
    if ("arr_delay" %in% colnames(df)) {
      delay_col <- "arr_delay"
      delay_label <- "Retard à l'arrivée (min)"
    } else if ("dep_delay" %in% colnames(df)) {
      delay_col <- "dep_delay"
      delay_label <- "Retard au départ (min)"
    } else {
      plot.new(); title("Aucune colonne de retard trouvée")
      return()
    }
    ggplot(df, aes(x=.data[[delay_col]])) +
      geom_histogram(bins=30, fill="skyblue", color="white") +
      labs(x=delay_label, y="Nombre de vols", title=paste("Distribution des", tolower(delay_label)))
  })

  # Nombre de vols par compagnie
  output$carrierPlot <- renderPlot({
    df <- get_flights()
    if (nrow(df)==0) {
      plot.new(); title("Pas de données")
      return()
    }
    df %>%
      count(carrier, name="vols") %>%
      ggplot(aes(reorder(carrier, vols), vols)) +
        geom_col(fill="darkgreen") + coord_flip() +
        labs(x="Compagnie", y="Nombre de vols", title="Nombre de vols par compagnie")
  })

  # tableau complet
  output$flightTable <- renderDT({
    df <- get_flights()
    if (nrow(df)==0) {
      datatable(data.frame(Message="Pas de données"))
    } else {
      datatable(df, options=list(pageLength=15, scrollX=TRUE))
    }
  })
}

cat("--- [DEBUG] Avant shinyApp() ---\n")
shinyApp(ui, server)
