@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM SCRIPT DE RESPALDO COMPLETO (FULL BACKUP) - PostgreSQL cajadb
REM Materia: Tópicos de Base de Datos (IFF-1026) / Proyecto Integrador TecNM
REM ============================================================================

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%

set BACKUP_DIR=backups\completos
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set BACKUP_FILE=%BACKUP_DIR%\cajadb_full_%TIMESTAMP%.dump
set BACKUP_SQL=%BACKUP_DIR%\cajadb_full_%TIMESTAMP%.sql

echo ========================================================================
echo INICIANDO RESPALDO COMPLETO DE cajadb...
echo Timestamp: %TIMESTAMP%
echo ========================================================================

REM 1. Respaldo en formato binario comprimido nativo de PostgreSQL (recomendado para restauración rápida)
docker exec -t tecnm_caja_db pg_dump -U postgres -d cajadb -F c -b -v > "%BACKUP_FILE%"

if %ERRORLEVEL% equ 0 (
    echo [OK] Respaldo binario generado: %BACKUP_FILE%
) else (
    echo [ERROR] Fallo al generar el respaldo binario.
    exit /b %ERRORLEVEL%
)

REM 2. Respaldo en texto plano SQL (para inspección y portabilidad)
docker exec -t tecnm_caja_db pg_dump -U postgres -d cajadb --clean --if-exists > "%BACKUP_SQL%"
if %ERRORLEVEL% equ 0 (
    echo [OK] Respaldo SQL generado: %BACKUP_SQL%
)

echo.
echo ========================================================================
echo RESPALDO COMPLETO CONCLUIDO CON EXITO
echo ========================================================================
