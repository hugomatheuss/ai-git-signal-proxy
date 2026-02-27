#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/home/node/.openclaw/workspace/basis"
SCRIPTS_DIR="$BASE_DIR/scripts"
LOG_FILE="$SCRIPTS_DIR/commands.log"
FLAG_FILE="$BASE_DIR/restart_queue.flag"
DOCKER_BIN="${DOCKER_BIN:-/usr/bin/docker}"
DOCKER_API_VERSION="${DOCKER_API_VERSION:-1.44}"
QUEUE_NAME="${QUEUE_NAME:-emails}"
MAX_PENDING="${MAX_PENDING:-50}"
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"
CONTAINER_NAME="${CONTAINER_NAME:-laravel_eventos_app}"

log_cmd() {
  local cmd="$*"
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" "$cmd" >> "$LOG_FILE"
}

run_docker_exec() {
  local cmd=("$DOCKER_BIN" exec "$CONTAINER_NAME" "$@")
  log_cmd "DOCKER_API_VERSION=$DOCKER_API_VERSION ${cmd[*]}"
  DOCKER_API_VERSION="$DOCKER_API_VERSION" "${cmd[@]}"
}

check_business_hours() {
  local dia_semana
  local hora_atual
  dia_semana=$(TZ='America/Sao_Paulo' date +%u)
  hora_atual=$(TZ='America/Sao_Paulo' date +%H)

  if [ "$dia_semana" -gt 5 ] || [ "$hora_atual" -lt 09 ] || [ "$hora_atual" -ge 18 ]; then
    printf '[%s] [Monitor] Fora do horário/dia comercial. Suspendendo...\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" >> "$LOG_FILE"
    return 1
  fi
  return 0
}

while true; do
  if ! check_business_hours; then
    sleep "$CHECK_INTERVAL"
    continue
  fi

  echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Verificando fila $QUEUE_NAME (limite $MAX_PENDING)..."
  if ! run_docker_exec php artisan queue:monitor "$QUEUE_NAME" --max="$MAX_PENDING" >/tmp/monitor_worker.out 2>&1; then
    echo "  Fila excedeu o limite. Conteúdo do monitor:" "$(cat /tmp/monitor_worker.out)"
    if [ ! -f "$FLAG_FILE" ]; then
      echo "  Criando flag em $FLAG_FILE"
      touch "$FLAG_FILE"
    else
      echo "  Flag já existe, mantendo."
    fi
  else
    rm -f /tmp/monitor_worker.out
  fi
  sleep "$CHECK_INTERVAL"
done
