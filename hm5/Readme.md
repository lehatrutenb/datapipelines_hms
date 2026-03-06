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

| Количество партиций | CPU time (user) | CPU time (sys) | CPU time (total) | Wall time |
| :------------------ | :-------------- | :------------- | :--------------- | :-------- |
| 13                  | 72.6 ms         | 30 ms          | 103 ms           | 2min 7s   |
| 50                  | 115 ms          | 40 ms          | 155 ms           | 1min 45s  |
| 100                 | 147 ms          | 30.7 ms        | 178 ms           | 1min 30s  |
| 200                 | 137 ms          | 57.4 ms        | 195 ms           | 1min 33s  |
| 500                 | 183 ms          | 54.6 ms        | 238 ms           | 1min 33s  |

### Java

| Количество партиций | CPU time (user) | CPU time (sys) | CPU time (total) | Wall time   |
| :------------------ | :-------------- | :------------- | :--------------- | :---------- |
| 13                  | 0.040 s         | 0.003 s        | 0.043 s          | 105.014 s   |
| 50                  | 0.020 s         | 0.003 s        | 0.023 s          | 95.121 s    |
| 100                 | 0.010 s         | 0.010 s        | 0.020 s          | 84.547 s    |
| 200                 | 0.030 s         | 0.002 s        | 0.032 s          | 64.836 s    |
| 500                 | 0.040 s         | -0.002 s*      | 0.038 s          | 97.721 s    |