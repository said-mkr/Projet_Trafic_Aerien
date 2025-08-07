import json
import os
from kafka import KafkaConsumer

JSON_PATH = "data/flights_test.json"
KAFKA_TOPIC = "flights_topic"
KAFKA_BOOTSTRAP = "localhost:9092"

# Charger l'existant ou démarrer une liste vide
def load_flights():
    if os.path.exists(JSON_PATH):
        with open(JSON_PATH, "r") as f:
            try:
                return json.load(f)
            except Exception:
                return []
    return []

def save_flights(flights):
    with open(JSON_PATH, "w") as f:
        json.dump(flights, f, indent=2)

flights = load_flights()

consumer = KafkaConsumer(
    KAFKA_TOPIC,
    bootstrap_servers=[KAFKA_BOOTSTRAP],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

print("En attente de messages Kafka...")

for message in consumer:
    flight = message.value
    flights.append(flight)
    save_flights(flights)
    print(f"Ajouté: {flight}")
