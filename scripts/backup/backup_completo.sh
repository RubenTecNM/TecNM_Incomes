#!/bin/bash
# ============================================================================
# SCRIPT DE RESPALDO COMPLETO (FULL BACKUP) - PostgreSQL cajadb
# Materia: Tópicos de Base de Datos (IFF-1026) / Proyecto Integrador TecNM
# ============================================================================

set -e

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="backups/completos"
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/cajadb_full_${TIMESTAMP}.dump"
BACKUP_SQL="$BACKUP_DIR/cajadb_full_${TIMESTAMP}.sql"

echo "========================================================================"
echo "INICIANDO RESPALDO COMPLETO DE cajadb..."
echo "Timestamp: $TIMESTAMP"
echo "========================================================================"

# 1. Respaldo en formato binario comprimido
docker exec -t tecnm_caja_db pg_dump -U postgres -d cajadb -F c -b -v > "$BACKUP_FILE"
echo "[OK] Respaldo binario generado: $BACKUP_FILE"

# 2. Respaldo en texto plano SQL
docker exec -t tecnm_caja_db pg_dump -U postgres -d cajadb --clean --if-exists > "$BACKUP_SQL"
echo "[OK] Respaldo SQL generado: $BACKUP_SQL"

echo "========================================================================"
echo "RESPALDO COMPLETO CONCLUIDO CON EXITO"
echo "========================================================================"
