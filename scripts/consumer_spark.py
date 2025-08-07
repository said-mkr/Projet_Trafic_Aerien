
# --- Spark consumer Kafka -> HDFS (format natif JSON, pas pyarrow) ---
import os
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, DoubleType, IntegerType
from pyspark.sql.functions import from_json, col

os.environ["HADOOP_USER_NAME"] = "root"

spark = SparkSession.builder \
    .appName("KafkaSparkConsumer") \
    .master("spark://spark-master:7077") \
    .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:8020") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")

df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("subscribe", "flights_topic") \
    .load()

schema = StructType() \
    .add("flight_id", StringType()) \
    .add("carrier", StringType()) \
    .add("origin", StringType()) \
    .add("dest", StringType()) \
    .add("dep_delay", DoubleType()) \
    .add("arr_delay", DoubleType()) \
    .add("distance", IntegerType())

parsed_df = df.selectExpr("CAST(value AS STRING)") \
    .select(from_json(col("value"), schema).alias("data")) \
    .select("data.*")

# --- Ecriture Spark native en JSON (un fichier par micro-batch) ---
query = parsed_df.writeStream \
    .format("json") \
    .option("path", "hdfs://namenode:8020/user/spark/live_json/") \
    .option("checkpointLocation", "hdfs://namenode:8020/user/spark/checkpoints/flights_json") \
    .outputMode("append") \
    .start()

query.awaitTermination()
