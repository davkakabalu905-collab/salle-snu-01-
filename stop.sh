#!/bin/bash
# ═══════════════════════════════════════════════════
#   CLAUDIA — Script d'arrêt du projet SNU
# ═══════════════════════════════════════════════════

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}   CLAUDIA — Arrêt des services SNU                 ${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo ""

for SERVICE in "backend:.claudia_backend.pid:Backend Claudia" "http:.claudia_http.pid:Frontend iStudio"; do
    NAME=$(echo $SERVICE | cut -d: -f3)
    PID_FILE="$BACKEND_DIR/$(echo $SERVICE | cut -d: -f2)"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            kill "$PID" 2>/dev/null
            echo -e "  ${GREEN}✓ $NAME arrêté (PID $PID)${NC}"
        else
            echo -e "  ${YELLOW}⚠ $NAME déjà arrêté${NC}"
        fi
        rm -f "$PID_FILE"
    else
        echo -e "  ${YELLOW}⚠ $NAME — PID file introuvable${NC}"
    fi
done

# Libérer les ports par sécurité
for PORT in 5050 8080; do
    PID_ON_PORT=$(lsof -ti :$PORT 2>/dev/null)
    if [ -n "$PID_ON_PORT" ]; then
        kill -9 "$PID_ON_PORT" 2>/dev/null
        echo -e "  ${RED}✓ Port $PORT libéré de force (PID $PID_ON_PORT)${NC}"
    fi
done

echo ""
echo -e "${BOLD}  Tous les services sont arrêtés.${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo ""
