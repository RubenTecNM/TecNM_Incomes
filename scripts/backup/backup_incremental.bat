@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM SCRIPT DE RESPALDO INCREMENTAL / DELTA - PostgreSQL cajadb
REM Materia: Tópicos de Base de Datos (IFF-1026) / Proyecto Integrador TecNM
REM Extrae las transacciones, recibos y logs de auditoría generados recientemente
REM ============================================================================

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%

set BACKUP_DIR=backups\incrementales
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set BACKUP_FILE=%BACKUP_DIR%\cajadb_incremental_%TIMESTAMP%.sql

echo ========================================================================
echo INICIANDO RESPALDO INCREMENTAL (TRANSACCIONES Y AUDITORIA RECIENTES)...
echo Timestamp: %TIMESTAMP%
echo ========================================================================

REM Extrae recibos y bitácora de auditoría de las últimas 24 horas
docker exec -t tecnm_caja_db psql -U postgres -d cajadb -c "COPY (SELECT * FROM receipts WHERE issued_at >= CURRENT_DATE - INTERVAL '1 day') TO STDOUT WITH CSV HEADER;" > "%BACKUP_DIR%\receipts_delta_%TIMESTAMP%.csv"

docker exec -t tecnm_caja_db psql -U postgres -d cajadb -c "COPY (SELECT * FROM audit_logs WHERE performed_at >= CURRENT_DATE - INTERVAL '1 day') TO STDOUT WITH CSV HEADER;" > "%BACKUP_DIR%\audit_logs_delta_%TIMESTAMP%.csv"

docker exec -t tecnm_caja_db psql -U postgres -d cajadb -c "COPY (SELECT * FROM payment_transactions WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 day') TO STDOUT WITH CSV HEADER;" > "%BACKUP_DIR%\transactions_delta_%TIMESTAMP%.csv"

echo [OK] Delta de Recibos exportado: %BACKUP_DIR%\receipts_delta_%TIMESTAMP%.csv
echo [OK] Delta de Bitacora de Auditoria exportado: %BACKUP_DIR%\audit_logs_delta_%TIMESTAMP%.csv
echo [OK] Delta de Movimientos de Pago exportado: %BACKUP_DIR%\transactions_delta_%TIMESTAMP%.csv

echo ========================================================================
echo RESPALDO INCREMENTAL CONCLUIDO CON EXITO
echo ========================================================================
