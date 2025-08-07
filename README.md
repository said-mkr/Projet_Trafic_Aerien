# Projet Trafic Aérien

## Présentation générale
Ce projet met en place un pipeline Big Data temps réel pour la collecte, le traitement, le stockage et la visualisation de données de trafic aérien. Il s’appuie sur Kafka, Spark, Hadoop HDFS, Docker, SQLite et Shiny pour fournir une solution robuste, automatisée et interactive.

---

## Architecture du pipeline

### 1. Génération et ingestion des données
- **data_generator.py** (dans `docker/scripts/`) : génère des données de vols simulées (format JSON).
- **producer.py** : envoie ces données dans un topic Kafka.

### 2. Pipeline de traitement temps réel
- **Kafka** : broker de messages pour la transmission des données.
- **Spark Streaming** (`consumer_spark.py`) : consomme les messages Kafka, les transforme et écrit des fichiers JSON (ou Parquet) sur HDFS.

### 3. Stockage distribué
- **HDFS** : stockage des fichiers produits par Spark (dossier `/user/spark/live_json/` pour JSON, `/user/spark/parquet/` pour Parquet).

### 4. Synchronisation automatique HDFS → local
- **sync_hdfs_json.sh** (dans `docker/scripts/`) : script qui tourne en boucle dans le conteneur `hdfs-sync` et copie automatiquement les nouveaux fichiers JSON depuis HDFS vers le dossier local `live_json/`.
- Les fichiers sont concaténés dans `flights.ndjson` (optionnel, selon le mode de visualisation).

### 5. Visualisation interactive
- **Shiny** (`app/app.R`) : dashboard web interactif qui lit dynamiquement tous les fichiers JSON présents dans `live_json/` et propose des tableaux, graphiques, statistiques, etc.
- Fallback automatique sur SQLite si les fichiers JSON/Parquet sont absents.

---

## Démarrage rapide

### Prérequis
- Docker et Docker Compose installés
- (Optionnel) R et RStudio pour développement local

### 1. Cloner le projet
```bash
git clone <URL_DU_REPO>
cd Projet_Trafic_Aerien
```

### 2. Lancer tous les services Docker
```bash
docker-compose up -d
```
Cela démarre : Kafka, Spark, HDFS (namenode/datanode), le producteur, le consommateur Spark, le synchroniseur HDFS, et Shiny.

### 3. Générer et injecter des données
Dans un terminal :
```bash
# Générer et envoyer des données dans Kafka
python docker/scripts/producer.py
```

### 4. Vérifier la synchronisation HDFS → local
- Les fichiers produits par Spark apparaissent dans HDFS (`/user/spark/live_json/`).
- Le conteneur `hdfs-sync` copie automatiquement ces fichiers dans le dossier local `live_json/`.
- Vérifiez le contenu avec :
```bash
ls live_json/
```

### 5. Accéder au dashboard Shiny
Ouvrez votre navigateur à l’adresse :
```
http://localhost:3838
```
Vous verrez les données s’afficher et se mettre à jour en temps réel.

---

## Détail des dossiers et scripts

- **app/** : code R du dashboard Shiny (`app.R`)
- **data/** : base SQLite de secours (`flights.db`)
- **docker/** : configuration Docker, scripts de synchronisation, fichiers de config Hadoop
- **docker/scripts/** : scripts Python (producteur, consommateur, data generator, sync)
- **scripts/** : scripts R pour le traitement, la génération de rapports, etc.
- **live_json/** : dossier local synchronisé avec HDFS (fichiers JSON copiés automatiquement)
- **parquet_data/** : (optionnel) pour les fichiers Parquet si utilisés

---

## Fonctionnement détaillé

### Pipeline automatique
1. **Le producteur Kafka** envoie des messages JSON.
2. **Spark Streaming** consomme ces messages et écrit des fichiers `part-*.json` sur HDFS.
3. **Le script `sync_hdfs_json.sh`** (dans le conteneur `hdfs-sync`) copie tous les nouveaux fichiers JSON depuis HDFS vers `live_json/` toutes les 10 secondes.
4. **Shiny** lit dynamiquement tous les fichiers présents dans `live_json/` et met à jour les visualisations.

### Visualisation
- Tableaux dynamiques, graphiques (retards, volume par destination, etc.), statistiques.
- Rafraîchissement automatique toutes les 5 secondes.
- Fallback sur SQLite si les fichiers JSON sont absents.

---

## Commandes utiles

- **Vérifier les fichiers sur HDFS** :
  ```bash
  docker exec -it hdfs-sync hdfs dfs -ls /user/spark/live_json/
  ```
- **Forcer la copie d’un fichier HDFS vers local** :
  ```bash
  docker exec -it hdfs-sync hdfs dfs -get /user/spark/live_json/part-00000-xxxx.json /live_json/
  ```
- **Voir les logs du synchroniseur** :
  ```bash
  docker logs -f hdfs-sync
  ```
- **Voir les logs de Shiny** :
  ```bash
  docker logs -f shiny
  ```

---

## Conseils & diagnostic
- Si le dashboard ne montre rien, vérifiez que des fichiers JSON sont bien présents dans `live_json/`.
- Consultez les logs des conteneurs pour diagnostiquer les erreurs.
- Les scripts et services sont pensés pour redémarrer automatiquement en cas de crash.

---

## Auteur
Projet développé par [Votre Nom].
