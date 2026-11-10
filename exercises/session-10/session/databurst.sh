#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ensure_env() {
  if [[ ! -f .env ]]; then
    port=8080
    while lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; do port=$((port + 1)); done
    printf 'AIRFLOW_UID=%s\nFERNET_KEY=%s\nAIRFLOW_PORT=%s\nWAREHOUSE_PORT=5433\n' "$(id -u)" "$(openssl rand -base64 32 | tr '+/' '-_')" "$port" > .env
    echo "created .env (UI on port $port)"
  fi
  set -a; . ./.env; set +a
  PORT="${AIRFLOW_PORT:-8080}"
}

wait_healthy() {
  echo -n "waiting for webserver"
  for _ in $(seq 1 80); do
    if curl -fs http://localhost:$PORT/health >/dev/null 2>&1; then echo " ok"; return 0; fi
    echo -n "."; sleep 3
  done
  echo " TIMEOUT"; docker compose ps; return 1
}

verify() {
  echo "--- component health"
  curl -fs http://localhost:$PORT/health | python3 -c 'import json,sys; [print("  %-14s %s" % (k, (v or {}).get("status"))) for k, v in json.load(sys.stdin).items()]'
  echo "--- import errors (should be empty)"
  docker compose exec -T airflow-scheduler airflow dags list-import-errors
  echo "--- dags"
  docker compose exec -T airflow-scheduler airflow dags list -o table
  echo
  echo "UI:  http://localhost:$PORT   (airflow / airflow)   Airflow 2.9"
}

case "${1:-}" in
  up)
    ensure_env
    docker compose up -d
    wait_healthy
    verify
    ;;
  down)   docker compose down ;;
  reset)  docker compose down -v; rm -rf logs/* data/*; echo "metadata DB, warehouse and logs wiped" ;;
  logs)   docker compose logs -f --tail=100 "${@:2}" ;;
  verify) ensure_env; verify ;;
  cli)    docker compose exec airflow-scheduler airflow "${@:2}" ;;
  test)   docker compose exec airflow-scheduler airflow dags test "${2:?dag_id}" ;;
  unpause) docker compose exec -T airflow-scheduler bash -c 'for d in $(airflow dags list -o plain | tail -n +2 | awk "{print \$1}"); do airflow dags unpause "$d"; done' ;;
  *)
    cat <<USAGE
usage: ./databurst.sh <command>      (Airflow 2.9 stack)
  up         create .env if missing, start the stack, wait, verify
  down       stop the stack (keeps data)
  reset      stop and wipe metadata DB, warehouse and logs
  logs [svc] follow logs
  verify     health + import errors + dag list
  cli ...    run an airflow CLI command, e.g. ./databurst.sh cli dags list
  test <dag> run a DAG once in-process (airflow dags test)
  unpause    unpause every DAG
USAGE
    ;;
esac
