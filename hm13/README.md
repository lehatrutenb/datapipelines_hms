# Spark Metrics — k3d Monitoring Stack

Two PySpark jobs producing real failure and spill signals → Prometheus → Grafana.

---

## Architecture

```
┌─ k8s: namespace spark ──────────────────────────────────────────────────────┐
│                                                                               │
│  SparkApplication CRD                                                         │
│  (spark-operator watches)                                                     │
│        │                                                                      │
│        ▼                                                                      │
│  ┌─ Driver Pod ──────────────────────────────────────────────────────────┐   │
│  │  JVM process                                                           │   │
│  │   ├── SparkContext                                                     │   │
│  │   │    └── DAGScheduler ──► MBean: metrics/DAGScheduler.*,type=gauges │   │
│  │   └── Dropwizard MetricRegistry                                        │   │
│  │         └── JMX Reporter ──► MBeans exposed on JMX port               │   │
│  │                                      │                                 │   │
│  │  jmx_prometheus_javaagent-0.20.0.jar │  (init container downloads)    │   │
│  │   ├── reads MBeans via JMX           │                                 │   │
│  │   ├── applies regex rules from jmx_config.yaml                        │   │
│  │   └── exposes /metrics HTTP :8090 ◄──────── Prometheus scrape         │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌─ Executor Pod (×2 per job) ───────────────────────────────────────────┐   │
│  │  JVM process                                                           │   │
│  │   ├── ExecutorSource ──► MBeans: executor.{succeededTasks,            │   │
│  │   │                               threadpool.*, diskBytesSpilled, …}  │   │
│  │   └── JVM metrics ────► MBeans: jvm.heap.*, jvm.gc.Copy/             │   │
│  │                                  MarkSweepCompact.{count,time}        │   │
│  │                                      │                                 │   │
│  │  jmx_prometheus_javaagent-0.20.0.jar │                                │   │
│  │   └── /metrics HTTP :8090 ◄──────────────── Prometheus scrape (5 s   │   │
│  │                                              drivers / 15 s executors)│   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ConfigMap (spark-scripts-{unstable,memory})                                  │
│   ├── jmx_config.yaml   regex rules: MBean name → prometheus metric name     │
│   └── job.py            PySpark script (mounted at /opt/spark/scripts/)       │
└───────────────────────────────────────────────────────────────────────────────┘

┌─ k8s: namespace monitoring ─────────────────────────────────────────────────┐
│                                                                               │
│  Prometheus Deployment                     Service NodePort :30090           │
│   ├── kubernetes_sd (pod role, ns=spark)                                     │
│   │    ├── job: spark-drivers   keep spark-role=driver   scrape :8090        │
│   │    └── job: spark-executors keep spark-role=executor scrape :8090        │
│   ├── TSDB (emptyDir)                                                        │
│   └── alert rules (2 active)                                                 │
│                                                                               │
│  Grafana Deployment                        Service NodePort :30300           │
│   ├── grafana container (anon admin)                                         │
│   └── k8s-sidecar container                                                  │
│        watches ConfigMaps label grafana_dashboard=1                          │
│        copies *.json → /tmp/dashboards/ (shared emptyDir)                    │
│                                                                               │
│  ConfigMaps (grafana_dashboard=1): executor-overview, jobs-health, jvm-gc   │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## Jobs

| Job | Signal produced |
|-----|----------------|
| **unstable-job** | ~33% task failure rate (partition-level, `mapPartitions`); `maxFailures=4` → occasional stage aborts | task churn %, GC pressure |
| **memory-job** | alternates: 10K rows (normal) / 50M rows wide shuffle; `storageFraction=0.9` forces spill | disk spill, heap pressure |

Both loop every 10 s, restart forever. JMX JAR downloaded by busybox init container — no custom image.

---

## Dashboards · Alerts

| Dashboard | Key panels |
|-----------|-----------|
| Executor Overview | task rate, heap %, disk spill rate, GC % wall clock |
| Jobs Health | active/failed stages, cumulative failed task attempts, task failure %, churn rate |
| JVM GC Time | GC time rate (s/s by type), event rate, cumulative count, total GC % |

| Alert | Condition |
|-------|-----------|
| `SparkHighStageFailureRate` | `deriv(failedStages[5m]) > 0.1` for 1 m |
| `SparkHighGCTime` | GC % wall clock > 25 % for 1 m |
| `SparkHighTaskChurnRate` | `(completetasks − succeededtasks) / completetasks > 50 %` for 1 m |

---

## Quick start

```bash
# one-time: k3d cluster with NodePorts
k3d cluster create spark-metrics \
  --port "30090:30090@loadbalancer" --port "30300:30300@loadbalancer"

# deploy + verify (installs kubectl/k3d/helm if missing)
./test.sh

# or just apply
kubectl apply -k .
```

```
Prometheus  http://localhost:30090
Grafana     http://localhost:30300  (anonymous admin)
```
