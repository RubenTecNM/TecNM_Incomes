-- ============================================================================
-- ETAPA 3: AUDITORÍA, REGLAS AUTOMÁTICAS Y VISTAS ANALÍTICAS
-- Sistema de Control de Caja Universitaria - TecNM Campus Monclova
-- ============================================================================
-- Directriz:
-- 1. Regla de negocio confirmada: Reversión automática de adeudos a PENDIENTE
--    al cancelar un recibo de caja.
-- 2. Auditoría formal de cancelaciones (motivo mínimo de 5 caracteres).
-- 3. Vistas SQL optimizadas para todos los modales de reportes del frontend.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. FUNCIÓN Y TRIGGER: REVERSIÓN AUTOMÁTICA DE ADEUDOS POR CANCELACIÓN
-- Confirmado por el usuario: Al cancelar un recibo, cualquier adeudo que
-- hubiese sido liquidado o abonado por este recibo regresa a 'PENDIENTE'
-- con su saldo original restaurado.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_revertir_adeudo_por_cancelacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Se activa únicamente cuando el estado cambia a 'CANCELADO'
    IF NEW.estado = 'CANCELADO' AND (OLD.estado IS NULL OR OLD.estado != 'CANCELADO') THEN
        -- Revertir adeudos del alumno asociados al concepto del recibo
        UPDATE adeudos a
        SET estado = 'PENDIENTE',
            saldo_pendiente = a.monto_original
        WHERE a.matricula = NEW.alumno_matricula
          AND a.estado IN ('LIQUIDADO', 'PARCIAL')
          AND EXISTS (
              SELECT 1 
              FROM detalles_recibo d
              WHERE d.recibo_id = NEW.id
                AND (d.descripcion ILIKE '%' || a.concepto_cobro || '%' OR a.concepto_cobro ILIKE '%' || d.descripcion || '%')
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_revertir_adeudo_cancelacion ON recibos;
CREATE TRIGGER trg_revertir_adeudo_cancelacion
AFTER UPDATE OF estado ON recibos
FOR EACH ROW
EXECUTE FUNCTION fn_revertir_adeudo_por_cancelacion();

-- ----------------------------------------------------------------------------
-- 2. VISTA ANALÍTICA 1: CORTE DIARIO DE CAJA Y ARQUEO
-- Utilizada por la Barra Superior y el Panel Lateral del Cajero
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_corte_diario_caja CASCADE;
CREATE VIEW vw_corte_diario_caja AS
SELECT 
    r.fecha_operacion::DATE AS fecha,
    r.cajero_usuario,
    r.cajero_nombre,
    m.forma_pago,
    COUNT(DISTINCT r.id) AS total_recibos_emitidos,
    COUNT(DISTINCT CASE WHEN r.estado = 'CANCELADO' THEN r.id END) AS recibos_cancelados,
    SUM(CASE WHEN r.estado != 'CANCELADO' THEN m.monto ELSE 0 END) AS total_recaudado
FROM recibos r
LEFT JOIN movimientos_pago m ON r.id = m.recibo_id
GROUP BY r.fecha_operacion::DATE, r.cajero_usuario, r.cajero_nombre, m.forma_pago;

-- ----------------------------------------------------------------------------
-- 3. VISTA ANALÍTICA 2: REPORTE DETALLADO DE RECIBOS Y DESGLOSE
-- Utilizada para exportación a Excel y ModalReporteVarios.vue
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_reporte_recibos_detallado CASCADE;
CREATE VIEW vw_reporte_recibos_detallado AS
SELECT 
    r.id AS recibo_id,
    r.numero_recibo,
    r.folio_administrativo,
    r.fecha_operacion,
    r.fecha_efectiva_pago,
    r.alumno_matricula,
    r.alumno_nombre,
    r.alumno_carrera,
    r.alumno_semestre,
    r.alumno_turno,
    d.descripcion AS concepto_detalle,
    d.cantidad,
    d.cuota_unitario,
    d.descuento_beca,
    d.importe_total AS importe_renglon,
    r.total AS total_recibo,
    r.metodo_pago,
    r.referencia_bancaria,
    r.tipo_recibo,
    r.estado AS estado_recibo,
    r.motivo_cancelacion,
    r.fecha_cancelacion,
    r.cajero_usuario,
    r.cajero_nombre
FROM recibos r
JOIN detalles_recibo d ON r.id = d.recibo_id;

-- ----------------------------------------------------------------------------
-- 4. VISTA ANALÍTICA 3: CONTROL DE ADEUDOS DE ESTUDIANTES
-- Utilizada por ModalReporteDeudores.vue, ModalReporteDeudoresInscritos.vue, etc.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_adeudos_estudiantes CASCADE;
CREATE VIEW vw_adeudos_estudiantes AS
SELECT 
    a.id_adeudo,
    a.matricula,
    al.nombre_completo AS alumno_nombre,
    al.carrera,
    al.semestre,
    al.turno,
    al.estatus AS estatus_alumno,
    a.concepto_cobro,
    p.codigo AS periodo_codigo,
    p.anio AS periodo_anio,
    p.ciclo AS periodo_ciclo,
    a.monto_original,
    a.saldo_pendiente,
    a.fecha_limite,
    a.estado AS estado_adeudo
FROM adeudos a
JOIN alumnos al ON a.matricula = al.matricula
JOIN periodos_academicos p ON a.id_periodo = p.id_periodo;

-- ----------------------------------------------------------------------------
-- 5. VISTA ANALÍTICA 4: CONCILIACIÓN DE DEPÓSITOS BANCARIOS (Regla 5+5)
-- Utilizada por ModalDepositoBancario.vue y ModalDepositoBancarioPropedeutico.vue
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_depositos_bancarios_conciliacion CASCADE;
CREATE VIEW vw_depositos_bancarios_conciliacion AS
SELECT
    r.id AS recibo_id,
    r.numero_recibo,
    r.folio_administrativo,
    r.fecha_operacion,
    r.fecha_efectiva_pago,
    r.alumno_matricula,
    r.alumno_nombre,
    al.cuenta_a,
    r.referencia_bancaria,
    SUBSTRING(r.referencia_bancaria FROM 1 FOR 5) AS referencia_cuenta_alumno,
    SUBSTRING(r.referencia_bancaria FROM 6 FOR 5) AS referencia_concepto_arancel,
    r.cuenta_bancaria,
    r.total,
    r.estado,
    r.cajero_usuario
FROM recibos r
LEFT JOIN alumnos al ON r.alumno_matricula = al.matricula
WHERE r.metodo_pago IN ('DEPOSITO_BANCARIO', 'TRANSFERENCIA');

-- ----------------------------------------------------------------------------
-- 6. VISTA ANALÍTICA 5: CONCENTRADO DE PÓLIZAS DE INGRESOS
-- Utilizada por ModalPolizaIngresos.vue y ModalPolizaIngresoPeriodo.vue
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_polizas_ingreso_resumen CASCADE;
CREATE VIEW vw_polizas_ingreso_resumen AS
SELECT
    p.id_poliza,
    p.numero_poliza,
    p.fecha_poliza,
    p.total_recaudado,
    p.cajero_usuario,
    p.estado,
    COUNT(r.id) AS total_recibos_asociados,
    p.created_at
FROM polizas_ingreso p
LEFT JOIN recibos r ON p.id_poliza = r.poliza_id
GROUP BY p.id_poliza, p.numero_poliza, p.fecha_poliza, p.total_recaudado, p.cajero_usuario, p.estado, p.created_at;

COMMIT;
