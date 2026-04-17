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

*StaRocs3.0+*

StarRocks can load data within seconds for near-real-time analytics. StarRocks' storage engine guarantees the atomicity, consistency, isolation, and durability (ACID) of each data ingestion operation. For a data loading transaction, the entire transaction either succeeds or fails. Concurrent transactions do not affect each other, providing transaction-level isolation.

Currently, StarRocks supports SELECT, INSERT, UPDATE, and DELETE statements in SQL transactions. UPDATE and DELETE are supported only in shared-data clusters from v4.0 onwards.

SELECT statements against the tables whose data have been changed in the same transaction are not allowed.

Multiple INSERT statements against the same table within a transaction are supported only in shared-data clusters from v4.0 onwards.

Within a transaction, you can only define one UPDATE or DELETE statement against each table, and it must precede the INSERT statements.

Subsequent DML statements cannot read the uncommitted changes brought by preceding statements within the same transaction. For example, the target table of the preceding INSERT statement cannot be the source table of subsequent statements. Otherwise, the system returns an error.

All target tables of the DML statements in a transaction must be within the same database. Cross-database operations are not allowed.

Currently, INSERT OVERWRITE is not supported.

Nesting transactions are not allowed. You cannot specify BEGIN WORK within a BEGIN-COMMIT/ROLLBACK pair.

If the session where an on-going transaction belongs is terminated or closed, the transaction is automatically rolled back.

StarRock only supports limited READ COMMITTED for Transaction Isolation Level as described above.

Write conflict checks are not supported. When two transactions write to the same table simultaneously, both transactions can be committed successfully. The visibility (order) of the data changes depends on the execution order of the COMMIT WORK statements.


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

#### Logging

https://github.com/StarRocks/starrocks/issues/52976



???
StarRocks can load data within seconds for near-real-time analytics. StarRocks' storage engine guarantees the atomicity, consistency, isolation, and durability (ACID) of each data ingestion operation. For a data loading transaction, the entire transaction either succeeds or fails. Concurrent transactions do not affect each other, providing transaction-level isolation.