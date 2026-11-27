# Plan de Continuidad y Recuperación ante Desastres (Disaster Recovery Plan - DRP)

**Tecnológico Nacional de México - Campus Monclova**  
**Materia:** Tópicos de Base de Datos (Clave: `IFF-1026`) / Fundamentos de Gestión de Servicios de TI (`IFE-1014`)  
**Módulo:** Control de Caja e Ingresos Universitarios (`TecNM_Incomes`)  
**Motor de Base de Datos:** PostgreSQL 17 (Instancia Contenerizada Docker)

---

## 1. Objetivos de Nivel de Servicio (SLA)

| Métrica | Definición | Valor Comprometido | Justificación Técnica |
| :--- | :--- | :---: | :--- |
| **Disponibilidad** | Tiempo en línea del servicio de base de datos | **99.0%** | Arquitectura contenerizada con reinicio automático (`restart: unless-stopped`) y volumen persistente. |
| **RPO** *(Recovery Point Objective)* | Máxima pérdida de datos tolerable ante fallo | **< 15 minutos** | Respaldos diarios completos combinados con deltas incrementales y bitácora activa `audit_logs`. |
| **RTO** *(Recovery Time Objective)* | Tiempo máximo para restaurar el servicio | **< 20 minutos** | Procedimiento automatizado de restauración con imágenes Docker y `pg_restore` binario optimizado. |

---

## 2. Sistema Activo de Bitácora y Auditoría de Transacciones

En cumplimiento con el requerimiento de auditoría de transacciones, la base de datos cuenta con la tabla inmutable `audit_logs` (expuesta en español como `bitacora_auditoria`) y la función trigger `fn_audit_trail_logger()`.

### 2.1. Estructura de la Bitácora
```sql
CREATE TABLE audit_logs (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name        VARCHAR(50) NOT NULL,
    operation         VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id         VARCHAR(100),
    performed_by      VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
    performed_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    client_ip         INET,
    old_values        JSONB,
    new_values        JSONB,
    changed_fields    TEXT[]
);
```

### 2.2. Entidades Críticas Auditadas
1. **`receipts` (`recibos`):** Auditoría total ante emisión, cancelación o modificación de recibos.
2. **`student_debts` (`adeudos`):** Auditoría ante asignación, liquidación o condonación de adeudos.
3. **`payment_concepts` (`conceptos_cobro`):** Registro de cambios en cuotas y cuentas contables.
4. **`payment_transactions` (`movimientos_pago`):** Auditoría de formas de pago y referencias bancarias.

---

## 3. Estrategia y Políticas de Respaldos

### 3.1. Respaldo Completo (Full Backup)
- **Herramienta:** `pg_dump` con compresión binaria (`-F c`) y volcado SQL (`.sql`).
- **Frecuencia:** Diario a las 23:00 hrs.
- **Ubicación:** `backups/completos/cajadb_full_YYYY-MM-DD_HH-MM-SS.dump`
- **Script Windows:** `scripts\backup\backup_completo.bat`
- **Script Linux/Docker:** `scripts/backup/backup_completo.sh`

### 3.2. Respaldo Incremental / Delta
- **Frecuencia:** Cada 4 horas durante horario operativo de ventanilla.
- **Contenido:** Exportación delta de recibos, pagos y bitácora de auditoría generados en las últimas 24 horas.
- **Ubicación:** `backups/incrementales/`
- **Script Windows:** `scripts\backup\backup_incremental.bat`
- **Script Linux/Docker:** `scripts/backup/backup_incremental.sh`

---

## 4. Procedimiento de Simulación de Recuperación ante Desastres (Fase 3 TecNM)

### Escenario de Desastre Simulado:
Corrupción total de datos o eliminación accidental del contenedor de base de datos.

### Pasos de Recuperación:

1. **Asegurar Contenedor Activo:**
   ```bash
   docker-compose up -d db
   ```

2. **Ejecutar Restauración Automatizada:**
   - **En Windows:**
     ```cmd
     scripts\backup\restore.bat backups\completos\cajadb_full_YYYY-MM-DD_HH-MM-SS.dump
     ```
   - **En Linux / Bash:**
     ```bash
     ./scripts/backup/restore.sh backups/completos/cajadb_full_YYYY-MM-DD_HH-MM-SS.dump
     ```

3. **Verificación de Integridad:**
   ```sql
   -- Validar conteo de recibos y auditoría restaurados
   SELECT COUNT(*) FROM receipts;
   SELECT COUNT(*) FROM audit_logs;
   SELECT * FROM vw_daily_cash_cut LIMIT 5;
   ```

4. **Reinicio de Servicios Conectados:**
   ```bash
   docker-compose restart backend frontend
   ```
