#!/bin/bash
# ============================================================================
# SCRIPT DE RESTAURACIÓN / DISASTER RECOVERY - PostgreSQL cajadb
# Materia: Tópicos de Base de Datos (IFF-1026) / Proyecto Integrador TecNM
# ============================================================================

set -e

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "[ERROR] Debe indicar la ruta del archivo de respaldo."
    echo "Ejemplo: ./scripts/backup/restore.sh backups/completos/cajadb_full_2026-11-27_09-00-00.dump"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "[ERROR] El archivo de respaldo no existe: $BACKUP_FILE"
    exit 1
fi

echo "========================================================================"
echo "INICIANDO RESTAURACION DE BASE DE DATOS cajadb..."
echo "Archivo: $BACKUP_FILE"
echo "========================================================================"

if [[ "$BACKUP_FILE" == *.dump ]]; then
    echo "[INFO] Restaurando archivo binario con pg_restore..."
    docker exec -i tecnm_caja_db pg_restore -U postgres -d cajadb --clean --if-exists -v < "$BACKUP_FILE"
else
    echo "[INFO] Restaurando archivo SQL con psql..."
    docker exec -i tecnm_caja_db psql -U postgres -d cajadb < "$BACKUP_FILE"
fi

echo "========================================================================"
echo "PROCESO DE RESTAURACION CONCLUIDO"
echo "========================================================================"
