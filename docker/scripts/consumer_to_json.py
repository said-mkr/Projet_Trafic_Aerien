import json
import os
from kafka import KafkaConsumer

# Dossier où écrire le JSON (à adapter selon ton montage Docker)
OUTPUT_DIR = '/srv/shiny-server/live_json'
OUTPUT_FILE = os.path.join(OUTPUT_DIR, 'flight_live.json')

# Crée le dossier si besoin
os.makedirs(OUTPUT_DIR, exist_ok=True)

consumer = KafkaConsumer(
    'flights_topic',
    bootstrap_servers='kafka:9092',
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    auto_offset_reset='latest',
    enable_auto_commit=True
)

flights = []

print('🟢 Consumer JSON en écoute...')
for message in consumer:
    flight = message.value
    flights.append(flight)
    # On garde les 100 derniers vols pour ne pas surcharger le fichier
    flights = flights[-100:]
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(flights, f, indent=2)
    print(f'💾 Vol ajouté et JSON mis à jour ({len(flights)} vols)')
