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
                flights = json.load(f)
                if not isinstance(flights, list):
                    print("[ERREUR] Le fichier JSON n'est pas un tableau.")
                    return []
                return flights
            except Exception as e:
                print(f"[ERREUR] Lecture JSON: {e}")
                return []
    return []

def save_flights(flights):
    try:
        with open(JSON_PATH, "w") as f:
            json.dump(flights, f, indent=2)
        # Vérification immédiate
        with open(JSON_PATH, "r") as f:
            json.load(f)
        print(f"[OK] {len(flights)} vols enregistrés dans {JSON_PATH}")
    except Exception as e:
        print(f"[ERREUR] Sauvegarde ou format JSON: {e}")

flights = load_flights()

consumer = KafkaConsumer(
    KAFKA_TOPIC,
    bootstrap_servers=[KAFKA_BOOTSTRAP],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

print("En attente de messages Kafka...")

for message in consumer:
    flight = message.value
    print(f"[Kafka] Reçu: {flight}")
    flights.append(flight)
    save_flights(flights)
