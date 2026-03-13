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

## (1.7gb + 3.7 gb)
### (only 3.7gb)


### Размер


## Файл 3.7 gb
### Whole read (.count() at end)


### Select by id

                                                                                

### Select by 3 ids

                                                                                

### Select by range ids



### Select by range ids & get sum on another col

### Append (3.6 gb) to (3.7 gb)