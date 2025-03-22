# HOW TO RUN

```shell
docker-compose up -d
```

```shell
./register-connector.sh
```

```shell
docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic postgres.public.[table_name] --from-beginning
```