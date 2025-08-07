import json, time, random, datetime
from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers='localhost:9092',
                         value_serializer=lambda v: json.dumps(v).encode('utf-8'))

carriers = ["UA","AA","B6","DL","WN"]
destinations = ["MIA","LAX","ORD","SFO","ATL"]

while True:
    flight = {
        "sched_dep_datetime": str(datetime.datetime.utcnow()),
        "dep_delay": random.randint(-5,120),
        "arr_delay": random.randint(-10,180),
        "carrier": random.choice(carriers),
        "dest": random.choice(destinations),
        "distance": random.randint(300,5000)
    }
    producer.send("flights_topic", flight)
    print("✈️ Nouveau vol envoyé :", flight)
    time.sleep(60)  # envoie toutes les minutes
