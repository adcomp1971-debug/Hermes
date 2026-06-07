#!/usr/bin/env bash
#
# health-check.sh — hermes-box Service Health Check
# ==================================================
# Checks whether core services are responding and
# prints a formatted status table.
#
# Services checked:
#   - Ollama API    (port 11434)
#   - Open WebUI    (port 3000)
#   - Hermes Agent  (port 8787)
#   - Guardrails    (port 8001)
#   - Dashboard     (port 9119)
#
# Usage:
#   ./scripts/health-check.sh
#   ./scripts/health-check.sh --watch   # continuous monitoring
#   ./scripts/health-check.sh --json    # JSON output
#
set -euo pipefail

# ─── Constants ─────────────────────────────────────────
TIMEOUT=5  # seconds per check

# ─── Service definitions ──────────────────────────────
# Format: "NAME|URL|EXPECTED_STATUS_CODE"
SERVICES=(
  "Ollama API|http://localhost:11434|200"
  "Open WebUI|http://localhost:3000|200"
  "Hermes Agent|http://localhost:8787|200"
  "Guardrails|http://localhost:8001|200"
  "Dashboard|http://localhost:9119|200"
)

# ─── Flags ─────────────────────────────────────────────
WATCH_MODE=false
JSON_MODE=false

for arg in "$@"; do
  case "$arg" in
    --watch|-w) WATCH_MODE=true ;;
    --json|-j)  JSON_MODE=true ;;
    --help|-h)
      echo "Usage: $0 [--watch] [--json] [--help]"
      echo ""
      echo "  --watch, -w   Continuously monitor (Ctrl+C to stop)"
      echo "  --json, -j    Output JSON instead of table"
      echo "  --help, -h    Show this help"
      exit 0
      ;;
  esac
done

# ─── Colors ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Health Check Function ────────────────────────────
check_service() {
  local name="$1"
  local url="$2"
  local expected_code="$3"

  local http_code
  local elapsed
  local start_time
  local end_time

  start_time=$(date +%s%N 2>/dev/null || echo 0)

  # Capture HTTP status code and any error message
  http_code=$(curl -sf --max-time "$TIMEOUT" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

  end_time=$(date +%s%N 2>/dev/null || echo 0)

  if [ "$end_time" -ne 0 ] && [ "$start_time" -ne 0 ]; then
    elapsed=$(( (end_time - start_time) / 1000000 ))  # ms
  else
    elapsed="?"
  fi

  if [ "$http_code" = "$expected_code" ]; then
    echo "UP|${name}|${http_code}|${elapsed}ms|${GREEN}✓${NC}"
  elif [ "$http_code" = "000" ]; then
    echo "DOWN|${name}|N/A|${elapsed}ms|${RED}✗${NC}"
  else
    echo "DEGRADED|${name}|${http_code}|${elapsed}ms|${YELLOW}~${NC}"
  fi
}

# ─── Table Output ──────────────────────────────────────
print_table() {
  local results=("$@")

  printf "\n${BOLD}┌─────────────────────────────────────────────────────────┐${NC}\n"
  printf "${BOLD}│${NC}  ${CYAN}hermes-box — Service Health Check${NC}"
  printf "          ${BOLD}│${NC}\n"
  printf "${BOLD}├──────┬──────────────────┬──────┬──────────┬──────────┤${NC}\n"
  printf "${BOLD}│${NC} ${BOLD}Status${NC} │ ${BOLD}Service${NC}          │ ${BOLD}Code${NC}  │ ${BOLD}Response${NC}  │ ${BOLD}Indicator${NC} ${BOLD}│${NC}\n"
  printf "${BOLD}├──────┼──────────────────┼──────┼──────────┼──────────┤${NC}\n"

  local up_count=0
  local total=${#results[@]}

  for result in "${results[@]}"; do
    IFS='|' read -r status name code response_time indicator <<< "$result"
    printf "${BOLD}│${NC} %-4s │ %-16s │ %-4s │ %-8s │  %-6s  ${BOLD}│${NC}\n" \
      "$status" "$name" "$code" "$response_time" "$indicator"
    if [ "$status" = "UP" ]; then
      ((up_count++))
    fi
  done

  printf "${BOLD}├──────┴──────────────────┴──────┴──────────┴──────────┤${NC}\n"

  if [ "$up_count" -eq "$total" ]; then
    printf "${BOLD}│${NC}  ${GREEN}✓ All ${total}/${total} services healthy${NC}"
    printf "                      ${BOLD}│${NC}\n"
  elif [ "$up_count" -ge $(( (total + 1) / 2)) ]; then
    printf "${BOLD}│${NC}  ${YELLOW}~ ${up_count}/${total} services healthy${NC}"
    printf "                      ${BOLD}│${NC}\n"
  else
    printf "${BOLD}│${NC}  ${RED}✗ ${up_count}/${total} services healthy${NC}"
    printf "                      ${BOLD}│${NC}\n"
  fi

  printf "${BOLD}└─────────────────────────────────────────────────────────┘${NC}\n"
  echo ""
}

# ─── JSON Output ───────────────────────────────────────
print_json() {
  local results=("$@")
  local first=true

  printf "{\n"
  printf '  "timestamp": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '  "services": [\n'

  for result in "${results[@]}"; do
    IFS='|' read -r status name code response_time _ <<< "$result"
    if [ "$first" = true ]; then
      first=false
    else
      printf ",\n"
    fi
    printf '    { "name": "%s", "status": "%s", "http_code": "%s", "response_time_ms": "%s" }' \
      "$name" "$status" "$code" "$response_time"
  done

  printf "\n  ]\n"
  printf "}\n"
}

# ─── Main ──────────────────────────────────────────────
if [ "$WATCH_MODE" = true ]; then
  header() { printf "\n${BOLD}━━━ [%s] ━━━${NC}\n" "$(date '+%Y-%m-%d %H:%M:%S')"; }
  while true; do
    clear 2>/dev/null || true
    header
    results=()
    for svc in "${SERVICES[@]}"; do
      IFS='|' read -r name url expected <<< "$svc"
      result=$(check_service "$name" "$url" "$expected")
      results+=("$result")
    done
    print_table "${results[@]}"
    sleep 5
  done
elif [ "$JSON_MODE" = true ]; then
  results=()
  for svc in "${SERVICES[@]}"; do
    IFS='|' read -r name url expected <<< "$svc"
    result=$(check_service "$name" "$url" "$expected")
    results+=("$result")
  done
  print_json "${results[@]}"
else
  results=()
  for svc in "${SERVICES[@]}"; do
    IFS='|' read -r name url expected <<< "$svc"
    result=$(check_service "$name" "$url" "$expected")
    results+=("$result")
  done
  print_table "${results[@]}"
fi
