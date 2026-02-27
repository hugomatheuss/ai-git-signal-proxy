#!/usr/bin/env bash
set -euo pipefail

DOCKER_BIN="${DOCKER_BIN:-/usr/bin/docker}"
DOCKER_API_VERSION="${DOCKER_API_VERSION:-1.44}"
QUEUE_CONTAINER_CANDIDATES=("eventos-app" "laravel_eventos_app")

run_docker() {
  if DOCKER_API_VERSION="$DOCKER_API_VERSION" "$DOCKER_BIN" "$@"; then
    return 0
  fi

  status=$?
  # Retry as root if we hit a permission problem
  if [[ $status -eq 126 || $status -eq 13 || $status -eq 1 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo DOCKER_API_VERSION="$DOCKER_API_VERSION" "$DOCKER_BIN" "$@"
      return $?
    fi
  fi

  return $status
}

print_header() {
  printf '\n==== %s ====' "$1"
  printf '\n'
}

check_containers() {
  print_header "Docker Containers"
  run_docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

check_queue_worker() {
  print_header "Queue Worker (emails)"
  local found_container=false

  for container in "${QUEUE_CONTAINER_CANDIDATES[@]}"; do
    if run_docker ps --format '{{.Names}}' | grep -Fxq "$container"; then
      found_container=true
      echo "Checking container: $container"
      if run_docker exec "$container" pgrep -a "php" | grep -q "queue:work --queue=emails"; then
        run_docker exec "$container" pgrep -a "php" | grep "queue:work --queue=emails"
      else
        echo "No queue:work --queue=emails process running in $container"
      fi
      return
    fi
  done

  if [[ "$found_container" == false ]]; then
    echo "Nenhum container conhecido para o worker (eventos-app ou laravel_eventos_app) está em execução."
  fi
}

check_containers
check_queue_worker
