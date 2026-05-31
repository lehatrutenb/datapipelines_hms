#!/usr/bin/env bash
set -euo pipefail

PROMETHEUS="http://localhost:30090"
GRAFANA="http://localhost:30300"
INSTALL_DIR="${HOME}/.local/bin"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; ERRORS=$((ERRORS+1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
info() { echo -e "      $*"; }

ERRORS=0

# ── 0. prerequisites ─────────────────────────────────────────────────────────
echo
echo "==> Checking prerequisites"

mkdir -p "$INSTALL_DIR"
export PATH="$INSTALL_DIR:$PATH"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GOARCH=amd64 ;;
  aarch64) GOARCH=arm64 ;;
  *)       GOARCH=$ARCH ;;
esac

install_kubectl() {
  echo "  Installing kubectl..."
  local ver
  ver=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSL "https://dl.k8s.io/release/${ver}/bin/linux/${GOARCH}/kubectl" \
    -o "${INSTALL_DIR}/kubectl"
  chmod +x "${INSTALL_DIR}/kubectl"
  ok "kubectl ${ver} installed to ${INSTALL_DIR}/kubectl"
}

install_k3d() {
  echo "  Installing k3d..."
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
    | USE_SUDO=false K3D_INSTALL_DIR="$INSTALL_DIR" bash
  ok "k3d installed to ${INSTALL_DIR}/k3d"
}

install_helm() {
  echo "  Installing helm..."
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | HELM_INSTALL_DIR="$INSTALL_DIR" USE_SUDO=false bash
  rm -rf "$tmp"
  ok "helm installed to ${INSTALL_DIR}/helm"
}

MISSING=0
for tool in kubectl k3d helm; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool found at $(command -v "$tool")"
  else
    warn "$tool not found — installing"
    case "$tool" in
      kubectl) install_kubectl ;;
      k3d)     install_k3d ;;
      helm)    install_helm ;;
    esac
    MISSING=$((MISSING+1))
  fi
done

if [[ $MISSING -gt 0 ]]; then
  info "Add ${INSTALL_DIR} to your PATH permanently:"
  info "  echo 'export PATH=\"\${HOME}/.local/bin:\${PATH}\"' >> ~/.bashrc"
  echo
fi

# ── 0b. cluster ───────────────────────────────────────────────────────────────
echo
echo "==> Checking k3d cluster"

CLUSTER_NAME="spark-metrics"
if k3d cluster list 2>/dev/null | grep -q "^${CLUSTER_NAME}"; then
  ok "cluster '${CLUSTER_NAME}' already exists"
else
  warn "Cluster '${CLUSTER_NAME}' not found — creating"
  k3d cluster create "$CLUSTER_NAME" \
    --port "30090:30090@loadbalancer" \
    --port "30300:30300@loadbalancer"
  ok "cluster '${CLUSTER_NAME}' created"
fi

# merge kubeconfig
k3d kubeconfig merge "$CLUSTER_NAME" --kubeconfig-merge-default &>/dev/null || true
export KUBECONFIG="${HOME}/.kube/config"

# ── 0c. spark operator ────────────────────────────────────────────────────────
echo
echo "==> Checking Spark operator"

helm repo add spark-operator https://kubeflow.github.io/spark-operator 2>/dev/null || true
helm repo update spark-operator 2>/dev/null

SPARK_OP_HELM_FLAGS=(
  --namespace spark-operator
  --create-namespace
  --set webhook.enable=true
  --set "spark.jobNamespaces[0]=spark"
  --wait
  --timeout 3m
)

if kubectl get deployment spark-operator -n spark-operator &>/dev/null; then
  # Check if it's already watching the right namespace
  if kubectl logs -n spark-operator deployment/spark-operator-controller 2>/dev/null \
      | grep -q "\-\-namespaces=spark"; then
    ok "Spark operator already installed and watching 'spark' namespace"
  else
    warn "Spark operator watching wrong namespace — upgrading"
    helm upgrade spark-operator spark-operator/spark-operator "${SPARK_OP_HELM_FLAGS[@]}"
    ok "Spark operator upgraded"
  fi
else
  warn "Spark operator not found — installing via Helm"
  helm install spark-operator spark-operator/spark-operator "${SPARK_OP_HELM_FLAGS[@]}"
  ok "Spark operator installed"
fi

# ── 1. apply ────────────────────────────────────────────────────────────────
echo
echo "==> Applying manifests"
kubectl apply -k "$(dirname "$0")"

# ── 2. wait for monitoring pods ──────────────────────────────────────────────
echo
echo "==> Waiting for Prometheus and Grafana (up to 90s)"
kubectl rollout status deployment/prometheus -n monitoring --timeout=90s && ok "Prometheus deployment ready" || fail "Prometheus deployment not ready"
kubectl rollout status deployment/grafana    -n monitoring --timeout=90s && ok "Grafana deployment ready"    || fail "Grafana deployment not ready"

# ── 3. wait for spark driver pods ────────────────────────────────────────────
echo
echo "==> Waiting for Spark driver pods (init container downloads JMX jar, allow 3 min)"
for job in unstable-job memory-job; do
  echo "  waiting for $job driver..."
  for i in $(seq 1 36); do
    phase=$(kubectl get sparkapplication "$job" -n spark -o jsonpath='{.status.applicationState.state}' 2>/dev/null || true)
    if [[ "$phase" == "RUNNING" ]]; then
      ok "$job is RUNNING"
      break
    fi
    if [[ $i -eq 36 ]]; then
      warn "$job not yet RUNNING (state: ${phase:-unknown}) — may still be starting"
    fi
    sleep 5
  done
done

# ── 4. check executor pods exist ─────────────────────────────────────────────
echo
echo "==> Executor pods"
exec_pods=$(kubectl get pods -n spark -l spark-role=executor --no-headers 2>/dev/null | awk '{print $1}')
if [[ -z "$exec_pods" ]]; then
  warn "No executor pods yet — they may still be initialising"
else
  echo "$exec_pods" | while read -r pod; do
    state=$(kubectl get pod "$pod" -n spark -o jsonpath='{.status.phase}' 2>/dev/null)
    ok "Executor $pod ($state)"
  done
fi

# ── 5. scrape metrics from one executor ──────────────────────────────────────
echo
echo "==> Spot-checking JMX metrics on an executor"
EXEC_POD=$(kubectl get pods -n spark -l spark-role=executor --no-headers 2>/dev/null | awk 'NR==1{print $1}')
if [[ -n "$EXEC_POD" ]]; then
  # start port-forward in background, clean up on exit
  kubectl port-forward -n spark "$EXEC_POD" 18090:8090 &>/dev/null &
  PF_PID=$!
  trap 'kill $PF_PID 2>/dev/null || true' EXIT
  sleep 3

  check_metric() {
    local name=$1
    if curl -sf http://localhost:18090/metrics 2>/dev/null | grep -q "^${name}"; then
      ok "metric present: $name"
    else
      fail "metric missing:  $name"
    fi
  }

  check_metric spark_executor_threadpool_activetasks
  check_metric spark_executor_threadpool_completetasks
  check_metric spark_executor_diskbytesspilled
  check_metric spark_executor_jvm_heap_used
  check_metric jvm_gc_collection_seconds_count

  kill $PF_PID 2>/dev/null || true
  trap - EXIT
else
  warn "No executor pod available to spot-check metrics"
fi

# ── 6. check Prometheus targets ──────────────────────────────────────────────
echo
echo "==> Prometheus targets"
prom_health=$(curl -sf "${PROMETHEUS}/-/healthy" 2>/dev/null || true)
if [[ "$prom_health" == "Prometheus Server is Healthy." ]]; then
  ok "Prometheus is healthy"
else
  fail "Prometheus health check failed (is port 30090 exposed?)"
fi

targets=$(curl -sf "${PROMETHEUS}/api/v1/targets" 2>/dev/null || true)
for job in spark-executors spark-drivers; do
  count=$(echo "$targets" | python3 -c "
import sys, json
d = json.load(sys.stdin)
up = sum(1 for t in d['data']['activeTargets'] if t['labels'].get('job')=='${job}' and t['health']=='up')
print(up)
" 2>/dev/null || echo 0)
  if [[ "$count" -gt 0 ]]; then
    ok "Prometheus job '$job': $count target(s) UP"
  else
    warn "Prometheus job '$job': 0 targets UP (pods may still be starting)"
  fi
done

# ── 7. check Grafana ─────────────────────────────────────────────────────────
echo
echo "==> Grafana"
grafana_health=$(curl -sf "${GRAFANA}/api/health" 2>/dev/null || true)
if echo "$grafana_health" | grep -q '"database": "ok"'; then
  ok "Grafana is healthy"
else
  fail "Grafana health check failed (is port 30300 exposed?)"
fi

dashboard_count=$(curl -sf "${GRAFANA}/api/search?type=dash-db" 2>/dev/null \
  | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
if [[ "$dashboard_count" -ge 3 ]]; then
  ok "Grafana: $dashboard_count dashboards loaded"
else
  warn "Grafana: only $dashboard_count dashboards visible (sidecar may need up to 30s to sync)"
fi

# list dashboards
curl -sf "${GRAFANA}/api/search?type=dash-db" 2>/dev/null \
  | python3 -c "import sys,json; [print('      -', d['title']) for d in json.load(sys.stdin)]" 2>/dev/null || true

# ── 8. check alerts defined ──────────────────────────────────────────────────
echo
echo "==> Prometheus alert rules"
alert_count=$(curl -sf "${PROMETHEUS}/api/v1/rules?type=alert" 2>/dev/null \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
rules=[r for g in d['data']['groups'] for r in g['rules'] if r['type']=='alerting']
for r in rules: print('      -', r['name'], '('+r['state']+')')
print(len(rules))
" 2>/dev/null | tail -1 || echo 0)
if [[ "$alert_count" -ge 4 ]]; then
  ok "$alert_count alert rules loaded"
else
  warn "Expected 4 alert rules, got $alert_count"
fi

# ── summary ──────────────────────────────────────────────────────────────────
echo
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}All checks passed.${NC}"
  echo
  echo "  Prometheus : ${PROMETHEUS}"
  echo "  Grafana    : ${GRAFANA}  (anonymous admin, no login)"
else
  echo -e "${RED}${ERRORS} check(s) failed — see [FAIL] lines above.${NC}"
  exit 1
fi
