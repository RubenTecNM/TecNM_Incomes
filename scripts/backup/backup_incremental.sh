#!/bin/bash
# ============================================================================
# SCRIPT DE RESPALDO INCREMENTAL / DELTA - PostgreSQL cajadb
# Materia: Tópicos de Base de Datos (IFF-1026) / Proyecto Integrador TecNM
# ============================================================================

set -e

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="backups/incrementales"
mkdir -p "$BACKUP_DIR"

echo "========================================================================"
echo "INICIANDO RESPALDO INCREMENTAL (TRANSACCIONES Y AUDITORIA RECIENTES)..."
echo "Timestamp: $TIMESTAMP"
echo "========================================================================"

docker exec -t tecnm_caja_db psql -U postgres -d cajadb -c "COPY (SELECT * FROM receipts WHERE issued_at >= CURRENT_DATE - INTERVAL '1 day') TO STDOUT WITH CSV HEADER;" > "$BACKUP_DIR/receipts_delta_${TIMESTAMP}.csv"
docker exec -t tecnm_caja_db psql -U postgres -d cajadb -c "COPY (SELECT * FROM audit_logs WHERE performed_at >= CURRENT_DATE - INTERVAL '1 day') TO STDOUT WITH CSV HEADER;" > "$BACKUP_DIR/audit_logs_delta_${TIMESTAMP}.csv"
docker exec -t tecnm_caja_db psql -U postgres -d cajadb -c "COPY (SELECT * FROM payment_transactions WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 day') TO STDOUT WITH CSV HEADER;" > "$BACKUP_DIR/transactions_delta_${TIMESTAMP}.csv"

echo "[OK] Delta de Recibos exportado: $BACKUP_DIR/receipts_delta_${TIMESTAMP}.csv"
echo "[OK] Delta de Bitacora de Auditoria exportado: $BACKUP_DIR/audit_logs_delta_${TIMESTAMP}.csv"
echo "[OK] Delta de Movimientos de Pago exportado: $BACKUP_DIR/transactions_delta_${TIMESTAMP}.csv"

echo "========================================================================"
echo "RESPALDO INCREMENTAL CONCLUIDO CON EXITO"
echo "========================================================================"
