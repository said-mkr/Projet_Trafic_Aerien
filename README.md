# ✈️ Air Traffic Data Pipeline
**Projet académique — École IPSI**

## 📌 Présentation
Ce projet consiste à concevoir un pipeline Big Data temps réel simulant le trafic aérien.  
L’objectif est de mettre en place une architecture capable de gérer un flux continu de données, depuis leur génération jusqu’à leur visualisation.

Ce projet reproduit un cas concret de Data Engineering avec ingestion, traitement en streaming, stockage distribué et restitution via un dashboard interactif.

## 🧠 Architecture
Le pipeline suit les étapes suivantes :  
Data Generator → Kafka → Spark Streaming → HDFS → Synchronisation → Dashboard

## ⚙️ Technologies utilisées
Python · Apache Kafka · Spark Streaming · Hadoop HDFS · Docker · R Shiny · SQLite

## 🔄 Fonctionnement
- Des données de vols sont simulées en continu (format JSON)
- Ces données sont envoyées vers Kafka via un producteur
- Spark Streaming consomme les messages, les transforme et les stocke dans HDFS
- Un script récupère automatiquement les nouvelles données depuis HDFS vers un dossier local
- Le dashboard Shiny lit ces données et met à jour les visualisations en temps réel
- En cas d’absence de données, un fallback sur SQLite est utilisé

## 🚀 Démarrage
Lancer les services :
```bash
docker-compose up -d

## 📁 Organisation du projet
app/ : dashboard Shiny
docker/scripts/ : scripts de génération, ingestion et traitement
live_json/ : données synchronisées depuis HDFS
parquet_data/ : stockage Parquet (optionnel)
data/ : base SQLite de secours

## 📊 Fonctionnalités principales
Traitement de données en temps réel
Pipeline distribué basé sur Kafka et Spark
Stockage via HDFS
Synchronisation automatique des données
Visualisation dynamique avec Shiny

## ⚠️ Limites
Données simulées
Déploiement limité à un environnement local
Absence de monitoring avancé

## 👤 Auteur

Said Mekaouar
