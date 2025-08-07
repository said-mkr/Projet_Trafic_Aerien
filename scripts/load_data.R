library(DBI)
library(RSQLite)
library(nycflights13)
library(dplyr)
library(lubridate)

# === Connexion à SQLite ===
con <- dbConnect(SQLite(), "../data/flights.db")

# === Préparation flights ===
flights <- nycflights13::flights %>%
  mutate(sched_dep_datetime = make_datetime(year, month, day, hour = sched_dep_time %/% 100, min = sched_dep_time %% 100))

# === Écriture dans SQLite ===
dbWriteTable(con, "flights", flights, overwrite = TRUE)
dbWriteTable(con, "airlines", nycflights13::airlines, overwrite = TRUE)
dbWriteTable(con, "airports", nycflights13::airports, overwrite = TRUE)
dbWriteTable(con, "planes", nycflights13::planes, overwrite = TRUE)
dbWriteTable(con, "weather", nycflights13::weather, overwrite = TRUE)

cat("✅ Base flights.db créée avec", nrow(flights), "lignes.\n")

dbDisconnect(con)
