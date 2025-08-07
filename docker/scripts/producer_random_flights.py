import json
import random
import time
from kafka import KafkaProducer

N = 10  # Nombre de vols à générer
KAFKA_TOPIC = "flights_topic"
KAFKA_BOOTSTRAP = "localhost:9092"

origins = ["CDG", "LHR", "ATL", "FRA"]
dests = ["JFK", "CDG", "LAX", "MIA"]
carriers = ["AF", "BA", "DL", "LH"]

flights = []
for i in range(N):
    flight = {
        "flight_id": f"FL{i+1:03d}",
        "carrier": random.choice(carriers),
        "origin": random.choice(origins),
        "dest": random.choice(dests),
        "dep_delay": round(random.uniform(-10, 30), 1),
        "arr_delay": round(random.uniform(-10, 30), 1)
    }
    flights.append(flight)

producer = KafkaProducer(
    bootstrap_servers=[KAFKA_BOOTSTRAP],
    value_serializer=lambda v: json.dumps(v).encode("utf-8")
)

for flight in flights:
    producer.send(KAFKA_TOPIC, flight)
    print(f"Envoyé: {flight}")
    time.sleep(0.5)  # Pour simuler du "live"

producer.flush()
print("Tous les vols ont été envoyés.")