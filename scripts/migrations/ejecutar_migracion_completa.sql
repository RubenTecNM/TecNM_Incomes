-- ============================================================================
-- EJECUTOR MAESTRO DE MIGRACIÓN: SISTEMA DE CAJA UNIVERSITARIA
-- TecNM Campus Monclova
-- ============================================================================
-- Ejecuta en orden secuencial obligatorio:
--   1. Etapa 1: Estructura (DDL, Tablas, Constraints, Índices)
--   2. Etapa 2: Datos (Catálogos, Alumnos, Matrículas, Movimientos, Incidencias)
--   3. Etapa 3: Auditoría, Triggers de Negocio y Vistas Analíticas
-- ============================================================================

\ir 01_etapa1_estructura.sql
\ir 02_etapa2_datos.sql
\ir 03_etapa3_auditoria_y_vistas.sql

-- REPORTE FINAL DE VALIDACIÓN POST-MIGRACIÓN
SELECT 'carreras' AS tabla, COUNT(*) AS registros FROM carreras
UNION ALL SELECT 'periodos_academicos', COUNT(*) FROM periodos_academicos
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'alumnos', COUNT(*) FROM alumnos
UNION ALL SELECT 'alumno_matriculas_historial', COUNT(*) FROM alumno_matriculas_historial
UNION ALL SELECT 'becas_descuentos', COUNT(*) FROM becas_descuentos
UNION ALL SELECT 'adeudos', COUNT(*) FROM adeudos
UNION ALL SELECT 'conceptos_cobro', COUNT(*) FROM conceptos_cobro
UNION ALL SELECT 'folios', COUNT(*) FROM folios
UNION ALL SELECT 'polizas_ingreso', COUNT(*) FROM polizas_ingreso
UNION ALL SELECT 'recibos', COUNT(*) FROM recibos
UNION ALL SELECT 'detalles_recibo', COUNT(*) FROM detalles_recibo
UNION ALL SELECT 'movimientos_pago', COUNT(*) FROM movimientos_pago
UNION ALL SELECT 'migracion_incidencias', COUNT(*) FROM migracion_incidencias;
