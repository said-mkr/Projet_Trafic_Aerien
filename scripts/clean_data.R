library(DBI)
library(RSQLite)
library(dplyr)

con <- dbConnect(SQLite(), "../data/flights.db")

# Charger données
flights <- dbReadTable(con, "flights")

# Nettoyage
na_summary <- sapply(flights, function(x) sum(is.na(x)))
print(na_summary)

flights_clean <- flights %>%
  filter(!is.na(dep_delay), !is.na(arr_delay), !is.na(sched_dep_datetime)) %>%
  distinct()

# Sauvegarde
dbWriteTable(con, "flights", flights_clean, overwrite = TRUE)
cat("✅ Données nettoyées :", nrow(flights_clean), "lignes.\n")

dbDisconnect(con)
