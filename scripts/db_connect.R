library(DBI)
library(RSQLite)

# Fonction pour établir la connexion avec SQLite
connect_db <- function(db_path = "../data/flights.db") {
  if (!file.exists(db_path)) {
    stop(paste("⚠️ Fichier SQLite non trouvé :", db_path))
  }
  con <- dbConnect(SQLite(), db_path)
  return(con)
}
