from kafka import KafkaProducer
import json, time, random

while True:
    try:
        producer = KafkaProducer(
            bootstrap_servers='kafka:9092',
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        print("✅ Connected to Kafka!")
        break
    except Exception as e:
        print(f"⏳ Kafka not ready, retrying... {e}")
        time.sleep(5)

while True:
    flight = {
        "flight_id": random.randint(1000, 9999),
        "carrier": random.choice(["AA", "DL", "UA", "B6"]),
        "origin": random.choice(["JFK", "LGA", "EWR"]),
        "dest": random.choice(["LAX", "MIA", "ORD"]),
        "dep_delay": round(random.uniform(-5, 120), 2),
        "arr_delay": round(random.uniform(-10, 180), 2),
        "distance": random.randint(300, 4000)
    }
    producer.send('flights_topic', flight)
    print(f"✈️ Sent: {flight}")
    time.sleep(2)
