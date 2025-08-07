# Lecture et agrégation de tous les fichiers JSON du dossier live_json dans Shiny

library(jsonlite)
library(dplyr)

# Chemin du dossier JSON (dans le conteneur shiny)
live_json_dir <- "/srv/shiny-server/live_json"

# Fonction pour charger tous les JSON
load_json_data <- function(json_dir) {
  files <- list.files(json_dir, pattern = "\\.json$", full.names = TRUE)
  if (length(files) == 0) return(tibble())
  dfs <- lapply(files, function(f) {
    tryCatch({
      jsonlite::fromJSON(f) %>% as_tibble()
    }, error = function(e) NULL)
  })
  dfs <- dfs[!sapply(dfs, is.null)]
  if (length(dfs) == 0) return(tibble())
  bind_rows(dfs)
}

# Exemple d'utilisation dans Shiny :
# flights_json <- load_json_data(live_json_dir)
# print(head(flights_json))
