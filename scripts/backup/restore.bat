@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM SCRIPT DE RESTAURACIÓN / DISASTER RECOVERY - PostgreSQL cajadb
REM Materia: Tópicos de Base de Datos (IFF-1026) / Proyecto Integrador TecNM
REM Uso: restore.bat [ruta_al_archivo_dump_o_sql]
REM ============================================================================

set BACKUP_FILE=%1

if "%BACKUP_FILE%"=="" (
    echo [ERROR] Debe indicar la ruta del archivo de respaldo.
    echo Ejemplo: scripts\backup\restore.bat backups\completos\cajadb_full_2026-11-27_09-00-00.dump
    echo O con archivo .sql: scripts\backup\restore.bat backups\completos\cajadb_full_2026-11-27_09-00-00.sql
    exit /b 1
)

if not exist "%BACKUP_FILE%" (
    echo [ERROR] El archivo de respaldo no existe: %BACKUP_FILE%
    exit /b 1
)

echo ========================================================================
echo INICIANDO RESTAURACION DE BASE DE DATOS cajadb...
echo Archivo: %BACKUP_FILE%
echo ========================================================================

REM Determinar si es dump binario o script SQL
if "%BACKUP_FILE:~-5%"==".dump" (
    echo [INFO] Restaurando archivo binario con pg_restore...
    type "%BACKUP_FILE%" | docker exec -i tecnm_caja_db pg_restore -U postgres -d cajadb --clean --if-exists -v
) else (
    echo [INFO] Restaurando archivo SQL con psql...
    type "%BACKUP_FILE%" | docker exec -i tecnm_caja_db psql -U postgres -d cajadb
)

if %ERRORLEVEL% equ 0 (
    echo [OK] Base de datos restaurada correctamente.
) else (
    echo [ADVERTENCIA] La restauracion finalizo con codigo %ERRORLEVEL% (verificar advertencias normales de objetos existentes).
)

echo ========================================================================
echo PROCESO DE RESTAURACION CONCLUIDO
echo ========================================================================
