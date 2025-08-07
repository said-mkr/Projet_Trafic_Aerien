library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "../data/flights.db")

# 1. Top 5 compagnies les plus ponctuelles
query1 <- "
SELECT carrier, AVG(dep_delay) AS avg_dep_delay
FROM flights
GROUP BY carrier
ORDER BY avg_dep_delay ASC
LIMIT 5;
"
print(dbGetQuery(con, query1))

# 2. Aéroports avec plus de retards
query2 <- "
SELECT origin, AVG(dep_delay) AS avg_delay
FROM flights
GROUP BY origin
ORDER BY avg_delay DESC;
"
print(dbGetQuery(con, query2))

# 3. Distribution des vols par mois
query3 <- "
SELECT strftime('%m', sched_dep_datetime) AS month, COUNT(*) AS total_vols
FROM flights
GROUP BY month;
"
print(dbGetQuery(con, query3))

dbDisconnect(con)
