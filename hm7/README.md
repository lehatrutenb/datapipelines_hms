# Hudi

## базовая запись всего файла (1.7gb)
### 8 workerов по 4gb worker mem 8gb dr 4gb dr&work overhead

CPU times: user 309 ms, sys: 324 ms, total: 633 ms
Wall time: 4min 41s


### 4 workerов по 6gb worker mem 8gb dr 4gb dr&work overhead

CPU times: user 148 ms, sys: 47.4 ms, total: 195 ms
Wall time: 2min 28s

### Размер (1.7gb)

0.33 GB

## (1.7gb + 3.7 gb)
### 4 workerов по 6gb worker mem 8gb dr 4gb dr&work overhead (only 3.7gb)

CPU times: user 207 ms, sys: 90.5 ms, total: 298 ms
Wall time: 3min 13s

### Размер

1.76 GB

## Файл 3.7 gb
### Whole write (.count() at end)
COPY_ON_WRITE

CPU times: user 127 ms, sys: 53.6 ms, total: 180 ms
Wall time: 2min 27s

MERGE_ON_READ

26/06/10 14:11:34 WARN TaskSetManager: Lost task 1.0 in stage 76.1 (TID 894) (172.24.0.8 executor 4): TaskKilled (Stage finished)
CPU times: user 173 ms, sys: 862 ms, total: 1.04 s
Wall time: 3min 8s

### Whole read (.count() at end)

CPU times: user 8.28 ms, sys: 546 µs, total: 8.83 ms
Wall time: 3.83 s

### Select by id

CPU times: user 8.32 ms, sys: 1.19 ms, total: 9.51 ms
Wall time: 2.09 s
                                                                                

### Select by 3 ids

CPU times: user 7.64 ms, sys: 2.26 ms, total: 9.9 ms
Wall time: 1.54 s
                                                                                

### Select by range ids

CPU times: user 5.66 ms, sys: 597 µs, total: 6.25 ms
Wall time: 1.7 s


### Select by range ids & get sum on another col

CPU times: user 18.2 ms, sys: 8.13 ms, total: 26.4 ms
Wall time: 1.29 s

### Append (3.6 gb) to (3.7 gb)

CPU times: user 205 ms, sys: 691 ms, total: 897 ms
Wall time: 5min 4s

# Iceberg

### Размер (1.7gb)
0.11 GB

### 8 workerов по 4gb worker mem 8gb dr 4gb dr&work overhead

CPU times: user 21.3 ms, sys: 0 ns, total: 21.3 ms
Wall time: 18.7 s

### 4 workerов по 6gb worker mem 8gb dr 4gb dr&work overhead

CPU times: user 20.1 ms, sys: 3.56 ms, total: 23.6 ms
Wall time: 19.4 s

## (1.7gb + 3.7 gb)
### (only 3.7gb)




## Файл 3.7 gb
### Whole read (.count() at end)

CPU times: user 22.3 ms, sys: 5.37 ms, total: 27.7 ms
Wall time: 10.7 s

### Whole write

CPU times: user 17.6 ms, sys: 11.2 ms, total: 28.8 ms
Wall time: 19.4 s
                   
### Размер

1.35 GB

### Select by id

CPU times: user 728 µs, sys: 3.49 ms, total: 4.22 ms
Wall time: 725 ms

                                                                                

### Select by 3 ids

CPU times: user 3.88 ms, sys: 1.45 ms, total: 5.33 ms
Wall time: 669 ms

                                                                                

### Select by range ids

CPU times: user 4.06 ms, sys: 0 ns, total: 4.06 ms
Wall time: 606 ms

### Select by range ids & get sum on another col

CPU times: user 2.43 ms, sys: 1.2 ms, total: 3.63 ms
Wall time: 428 ms

### Append (3.6 gb) to (3.7 gb)

CPU times: user 20.9 ms, sys: 7.35 ms, total: 28.3 ms
Wall time: 15.2 s