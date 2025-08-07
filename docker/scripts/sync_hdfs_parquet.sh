#!/bin/bash
# sync_hdfs_parquet.sh
# Synchronise les fichiers Parquet de HDFS vers le dossier local toutes les 30s

set -e
HDFS_PATH="/user/spark/parquet/"   # À adapter selon le chemin réel d'output Spark
LOCAL_PATH="/parquet_data"

while true; do
  echo "[hdfs-sync] Synchronisation des fichiers Parquet depuis HDFS..."
  hdfs dfs -get -f ${HDFS_PATH}/*.parquet ${LOCAL_PATH}/ || true
  sleep 30
done
