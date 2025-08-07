#!/usr/bin/env bash
set -eux

HDFS_DIR="/user/spark/live_json"
LOCAL_DIR="/live_json"
mkdir -p "${LOCAL_DIR}"



while true; do
  # Suppression désactivée (conservé pour debug)

  echo "--- $(date): lister HDFS ${HDFS_DIR} ---"
  hdfs dfs -ls "${HDFS_DIR}" || echo "❗ impossible de lister ${HDFS_DIR}"

  echo "--- $(date): get vers ${LOCAL_DIR} ---"
  FILES=$(hdfs dfs -ls ${HDFS_DIR}/part-*.json 2>/dev/null | awk '{print $8}' || true)
  echo "Fichiers listés par HDFS :"
  echo "$FILES"
  if [ -z "$FILES" ]; then
    echo "❗ Aucun fichier à copier depuis HDFS"
  else
    for f in $FILES; do
      echo "Tentative de copie de $f"
      if hdfs dfs -get "$f" "${LOCAL_DIR}/"; then
        echo "✅ Copie réussie de $f"
      else
        echo "❗ Erreur de copie pour $f"
      fi
    done
  fi

  echo "--- $(date): écriture directe dans flights.ndjson ---"
  if ls "${LOCAL_DIR}"/part-*.json 1> /dev/null 2>&1; then
    for f in "${LOCAL_DIR}"/part-*.json; do
      if [ -f "$f" ]; then
        cat "$f" >> "${LOCAL_DIR}/flights.ndjson"
        echo >> "${LOCAL_DIR}/flights.ndjson"
        rm -f "$f"
        echo "Ajout et suppression de $f dans flights.ndjson"
      fi
    done
  else
    echo "(aucun fichier à traiter)"
  fi

  echo "--- $(date): contenu local ---"
  ls -l "${LOCAL_DIR}"/*.json "${LOCAL_DIR}/flights.ndjson" 2>&1 || echo "(aucun JSON)"

  sleep 10
done
