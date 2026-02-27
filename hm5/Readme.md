Данные были взяты с https://www.kaggle.com/datasets/amineipad/cic-iomt-dataset-2024?select=train_iomt.csv

(чтобы аналогично протестировать - положите в папку hm2 этот датасет с именем с data.csv)

# Результаты сравнения

## Mean

### Python

#### RDD 
[Stage 6:====================================================>    (12 + 1) / 13]

CPU times: user 23.9 ms, sys: 10.7 ms, total: 34.6 ms

Wall time: 22.8 s

#### Dataframes
[Stage 9:================================================>        (11 + 2) / 13]
CPU times: user 11.5 ms, sys: 6.33 ms, total: 17.8 ms
Wall time: 3.07 s

### Java

#### RDD
CPU times: user 0.030 s, sys -0.013 s, total 0.017 s

Wall time: 7.739 s

#### Dataframes
CPU times: user 0.190 s, sys 0.004 s, total 0.194 sWall time: 3.034 s


## Sort

### Python

13 partitions: 

CPU times: user 72.6 ms, sys: 30 ms, total: 103 ms
Wall time: 2min 7s
200 partitions: 

CPU times: user 137 ms, sys: 57.4 ms, total: 195 ms
Wall time: 1min 33s

50 partitions: 

CPU times: user 115 ms, sys: 40 ms, total: 155 ms
Wall time: 1min 45s
100 partitions: 

CPU times: user 147 ms, sys: 30.7 ms, total: 178 ms
Wall time: 1min 30s

500 partitions:
CPU times: user 183 ms, sys: 54.6 ms, total: 238 ms
Wall time: 1min 33s

### Java

13 partitions:

CPU times: 

user 0.040 s, sys 0.003 s, total 0.043 s

Wall time: 105.014 s

200 partitions: 

CPU times: 

user 0.030 s, sys 0.002 s, total 0.032 s

Wall time: 64.836 s

50 partitions: 

CPU times: 

user 0.020 s, sys 0.003 s, total 0.023 s

Wall time: 95.121 s

100 partitions: 

CPU times: 

user 0.010 s, sys 0.010 s, total 0.020 s

Wall time: 84.547 s

500 partitions: 

CPU times:

user 0.040 s, sys -0.002 s, total 0.038 s

Wall time: 97.721 s
