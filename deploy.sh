#!/usr/bin/env bash
set -euo pipefail

readonly COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
readonly APP_DIR="${APP_DIR:-/opt/app}"
readonly HEALTH_URL="${APP_URL:-http://localhost:3000}/health"
readonly HEALTH_RETRIES=12
readonly HEALTH_INTERVAL=5

err() { echo "error: $*" >&2; exit 1; }

deploy() {
    cd "$APP_DIR"
    docker compose -f "$COMPOSE_FILE" pull
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    docker system prune -f
}

rollback() {
    local tag="${1:?missing image tag}"
    cd "$APP_DIR"
    IMAGE_TAG="$tag" docker compose -f "$COMPOSE_FILE" up -d app
}

health() {
    local i=0
    until curl -sf "$HEALTH_URL" &>/dev/null; do
        i=$((i + 1))
        [ "$i" -ge "$HEALTH_RETRIES" ] && err "health check timed out after $((HEALTH_RETRIES * HEALTH_INTERVAL))s"
        sleep "$HEALTH_INTERVAL"
    done
    echo "healthy"
}

case "${1:-deploy}" in
    deploy)   deploy; health ;;
    rollback) rollback "${2:-}" ;;
    health)   health ;;
    *)        err "usage: $0 {deploy|rollback <tag>|health}" ;;
esac
