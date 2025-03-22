#!/bin/bash

echo "Waiting for Kafka Connect to start..."
while ! curl -s http://localhost:8083/connectors/; do
    sleep 1
done

echo "Creating Postgres connector..."
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "name": "postgres-connector",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "dev",
      "database.password": "dev123",
      "database.dbname": "testdb",
      "database.server.name": "postgres",
      "topic.prefix": "postgres",
      "schema.include.list": "public",
      "plugin.name": "pgoutput",
      "tombstones.on.delete": "false",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter"
    }
  }' \
  http://localhost:8083/connectors/

echo "Connector created."
