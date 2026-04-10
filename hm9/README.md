1. Бенчмарки

Я видел тесты на hive, но тогда повторяться не буду



2. Ключевые различия

### Lineage

*Star rocks*

на самом деле есть, есть таблицы с выполненными sql запросами - так что можно из них брать и использовать внешние движки для этого.

Так же если использовать dbt - то в целом у starrcoks есть community библиотека.

Но по всему этому lineage строится только верхнеуровневый - по-объектный путь нужно самим стараться реализовать, либо использовать commerical SQLFlow.

*Trino*

он поддержан вообще без телодвижений.


### ACID

*StaRocs*

StarRocks can load data within seconds for near-real-time analytics. StarRocks' storage engine guarantees the atomicity, consistency, isolation, and durability (ACID) of each data ingestion operation. For a data loading transaction, the entire transaction either succeeds or fails. Concurrent transactions do not affect each other, providing transaction-level isolation.

*Trino*

не гарантирует ACID - ему нужна прослойка , например iceberg


### HA

Starrocks из коробки его имеет, с trino нужны свои надстройки

### Already existing table structures

*Star rocks*

Легко, удобно без лишних приведаний можно сразу читать сщуествующие файлы и как-то их двигать

*Trino*

Не легко работать с чему-то уже существующим напрямую - нужен например тот же iceberg

3. Анализ рисков внедрения

Почему у starrokcs 0 звёзд на dockerhub и нет верифицированных аккаунтов:)

4. Итоговое решение





???
StarRocks can load data within seconds for near-real-time analytics. StarRocks' storage engine guarantees the atomicity, consistency, isolation, and durability (ACID) of each data ingestion operation. For a data loading transaction, the entire transaction either succeeds or fails. Concurrent transactions do not affect each other, providing transaction-level isolation.