#!/bin/bash
# ════════════════════════════════════════════════════
#   CLAUDIA SNU — Script de démarrage
# ════════════════════════════════════════════════════

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/iStudio"
BACKEND_PORT=5050
HTTP_PORT=8080

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}   CLAUDIA — Salle du Numérique UNILU               ${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo ""

# Arrêter les anciens processus
for PID_FILE in "$BACKEND_DIR/.claudia_backend.pid" "$BACKEND_DIR/.claudia_http.pid"; do
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            echo -e "${YELLOW}  ↻ Arrêt PID $OLD_PID...${NC}"
            kill "$OLD_PID" 2>/dev/null
            sleep 1
        fi
        rm -f "$PID_FILE"
    fi
done

# Libérer les ports
for PORT in $BACKEND_PORT $HTTP_PORT; do
    PID_ON_PORT=$(lsof -ti :$PORT 2>/dev/null)
    if [ -n "$PID_ON_PORT" ]; then
        echo -e "${YELLOW}  ↻ Port $PORT occupé — libération...${NC}"
        kill -9 "$PID_ON_PORT" 2>/dev/null
        sleep 1
    fi
done

# 1. Backend Flask
echo -e "${BOLD}  [1/2] Démarrage du backend Claudia (port $BACKEND_PORT)...${NC}"
cd "$BACKEND_DIR" || { echo -e "${RED}  ✗ Dossier backend introuvable !${NC}"; exit 1; }

nohup python3 app.py > "$BACKEND_DIR/claudia_backend.log" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "$BACKEND_DIR/.claudia_backend.pid"

# Attendre Flask
READY=0
for i in $(seq 1 12); do
    sleep 1
    if curl -s "http://127.0.0.1:$BACKEND_PORT/claudia/status" > /dev/null 2>&1; then
        READY=1
        break
    fi
done

if [ $READY -eq 1 ]; then
    echo -e "${GREEN}  ✓ Backend Claudia en ligne (RAG actif, sans JWT)${NC}"
else
    echo -e "${RED}  ✗ Backend non démarré. Vérifiez : tail -f $BACKEND_DIR/claudia_backend.log${NC}"
fi

# 2. Frontend HTTP
echo -e "${BOLD}  [2/2] Démarrage du frontend iStudio (port $HTTP_PORT)...${NC}"
cd "$FRONTEND_DIR" || { echo -e "${RED}  ✗ Dossier iStudio introuvable !${NC}"; exit 1; }

nohup python3 -m http.server $HTTP_PORT > "$BACKEND_DIR/claudia_http.log" 2>&1 &
HTTP_PID=$!
echo $HTTP_PID > "$BACKEND_DIR/.claudia_http.pid"
sleep 1

if kill -0 "$HTTP_PID" 2>/dev/null; then
    echo -e "${GREEN}  ✓ Frontend iStudio en ligne${NC}"
else
    echo -e "${RED}  ✗ Frontend non démarré.${NC}"
fi

# Résumé
echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  PROJET ACTIF${NC}"
echo -e "  🤖 Backend  → ${GREEN}http://127.0.0.1:$BACKEND_PORT/claudia/status${NC}"
echo -e "  🌐 Site web → ${GREEN}http://localhost:$HTTP_PORT${NC}"
echo ""
echo -e "  Logs : tail -f $BACKEND_DIR/claudia_backend.log"
echo -e "  Stop : ${YELLOW}bash stop.sh${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
echo ""
