-- ============================================================================
-- SEED DE DATOS OFICIALES PARA PÓLIZA Y REPORTE DE INGRESOS (29/10/2026)
-- Datos reales extraídos de la hoja oficial de caja TecNM Campus Monclova
-- ============================================================================

BEGIN;

-- 1. Insertar alumnos correspondientes si no existen
INSERT INTO alumnos (matricula, nombre_completo, id_carrera, carrera, semestre, turno, estatus, tiene_beca, porcentaje_beca)
VALUES
('24050101', 'URQUIETA TOVAR JESUS SEBASTIAN', 67, 'Ing. Industrial', 3, 'Matutino', 'Inscrito', false, 0),
('24050102', 'DE LA ROSA FRANCO RAMON YAHIR', 67, 'Ing. Industrial', 3, 'Matutino', 'Inscrito', false, 0),
('24050103', 'FRANCO SANMIGUEL ANGELA FERNANDA', 70, 'Ing. Gestión Emp.', 3, 'Matutino', 'Inscrito', false, 0),
('23050677', 'GUZMAN GONZALEZ MIRANDA', 69, 'Ing. Informática', 4, 'Matutino', 'Inscrito', false, 0),
('00000001', 'ALUMNOS EN GENERAL', 67, 'Ing. Industrial', 1, 'Matutino', 'Inscrito', false, 0),
('21050410', 'GOMEZ LARA KEVIN ALBERTO', 65, 'Ing. Mecánica', 7, 'Matutino', 'Inscrito', false, 0),
('22050302', 'ALBA CHACON ENRIQUE JAVIER', 68, 'Ing. Electrónica', 5, 'Matutino', 'Inscrito', false, 0),
('22050119', 'DE LA CRUZ HERNANDEZ TANIA JOSELYN', 70, 'Ing. Gestión Emp.', 5, 'Matutino', 'Inscrito', false, 0),
('24050211', 'DURON OLVERA FERNANDA ANAHI', 70, 'Ing. Gestión Emp.', 2, 'Matutino', 'Inscrito', false, 0),
('23050412', 'CRUZ FACUNDO NAYELI ESTEFANIA', 69, 'Ing. Informática', 4, 'Matutino', 'Inscrito', false, 0),
('23050199', 'ORONA MARTINEZ OLIVER ALEXIS', 67, 'Ing. Industrial', 4, 'Matutino', 'Inscrito', false, 0),
('23050871', 'VILLALOBOS TAMEZ ANGEL JAIME', 68, 'Ing. Electrónica', 4, 'Matutino', 'Inscrito', false, 0),
('20050111', 'PADILLA VAZQUEZ HOMAR', 67, 'Ing. Industrial', 9, 'Matutino', 'Inscrito', false, 0),
('23050088', 'CONTRERAS RIVAS LIZETH AHANI', 70, 'Ing. Gestión Emp.', 4, 'Matutino', 'Inscrito', false, 0),
('21050219', 'QUIROZ SANCHEZ ORLANDO ANTONIO', 69, 'Ing. Informática', 7, 'Matutino', 'Inscrito', false, 0),
('22050998', 'PEREZ MARTINEZ ALEXIA MONSERRAT', 70, 'Ing. Gestión Emp.', 5, 'Matutino', 'Inscrito', false, 0),
('21050882', 'LEON DUARTE ERIK SEBASTIAN', 67, 'Ing. Industrial', 7, 'Matutino', 'Inscrito', false, 0),
('22050331', 'BENITEZ RODRIGUEZ LUIS PABLO', 65, 'Ing. Mecánica', 5, 'Matutino', 'Inscrito', false, 0),
('21050772', 'RAMOS RIVAS YESSENIA', 70, 'Ing. Gestión Emp.', 7, 'Matutino', 'Inscrito', false, 0),
('23050303', 'LOPEZ GONZALEZ ALONSO EMMANUEL', 68, 'Ing. Electrónica', 4, 'Matutino', 'Inscrito', false, 0),
('22050444', 'GONZALEZ REYES MARVYN JARETH', 69, 'Ing. Informática', 5, 'Matutino', 'Inscrito', false, 0),
('21050555', 'DE LA FUENTE CERNA NARDA GUADALUPE', 70, 'Ing. Gestión Emp.', 7, 'Matutino', 'Inscrito', false, 0),
('22050666', 'SIFUENTES JASSO CESAR ALEXANDRO', 67, 'Ing. Industrial', 5, 'Matutino', 'Inscrito', false, 0),
('23050777', 'OROZCO RANGEL DANIEL AZAEL', 68, 'Ing. Electrónica', 4, 'Matutino', 'Inscrito', false, 0),
('24050888', 'CAMARILLO PEREZ YAXENI SHECCID', 70, 'Ing. Gestión Emp.', 2, 'Matutino', 'Inscrito', false, 0),
('22050774', 'VALENCIANO LARA IDALIA JAQUELINE', 70, 'Ing. Gestión Emp.', 5, 'Matutino', 'Inscrito', false, 0)
ON CONFLICT (matricula) DO UPDATE SET
    nombre_completo = EXCLUDED.nombre_completo,
    estatus = 'Inscrito';

-- 2. Insertar Folios
INSERT INTO folios (numero_folio, serie)
SELECT s, 'A' FROM generate_series(128628, 128655) s
ON CONFLICT (numero_folio) DO NOTHING;

-- 3. Insertar Recibos del 29/10/2026
INSERT INTO recibos (
    numero_recibo, folio_administrativo, fecha_operacion, alumno_matricula, alumno_nombre,
    alumno_carrera, alumno_semestre, alumno_turno, metodo_pago, referencia_bancaria,
    cuenta_bancaria, subtotal, descuento_total, total, status, estado, tipo_recibo, cajero_usuario, cajero_nombre
) VALUES
(128628, '128628', '2026-10-29 09:00:00-06', '24050101', 'URQUIETA TOVAR JESUS SEBASTIAN', 'Ing. Industrial', 3, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-101', '5200-001-002-002', 100.00, 0, 100.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128629, '128629', '2026-10-29 09:10:00-06', '24050102', 'DE LA ROSA FRANCO RAMON YAHIR', 'Ing. Industrial', 3, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-102', '5200-001-002-002', 100.00, 0, 100.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128630, '128630', '2026-10-29 09:20:00-06', '24050103', 'FRANCO SANMIGUEL ANGELA FERNANDA', 'Ing. Gestión Emp.', 3, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-103', '5200-001-002-002', 100.00, 0, 100.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128631, '128631', '2026-10-29 09:30:00-06', '23050677', 'GUZMAN GONZALEZ MIRANDA', 'Ing. Informática', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-104', '5200-001-002-002', 100.00, 0, 100.00, 0, 'CANCELADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128632, '128632', '2026-10-29 09:35:00-06', '23050677', 'GUZMAN GONZALEZ MIRANDA', 'Ing. Informática', 4, 'Matutino', 'EFECTIVO', 'N/A', '5200-001-004-005', 500.00, 0, 500.00, 0, 'CANCELADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128633, '128633', '2026-10-29 09:40:00-06', '00000001', 'ALUMNOS EN GENERAL', 'Ing. Industrial', 1, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-105', '5200-001-002-002', 100.00, 0, 100.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128634, '128634', '2026-10-29 09:45:00-06', '00000001', 'ALUMNOS EN GENERAL', 'Ing. Industrial', 1, 'Matutino', 'EFECTIVO', 'N/A', '5200-001-004-005', 500.00, 0, 500.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128635, '128635', '2026-10-29 10:00:00-06', '21050410', 'GOMEZ LARA KEVIN ALBERTO', 'Ing. Mecánica', 7, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-106', '5200-005-001-020', 250.00, 0, 250.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128636, '128636', '2026-10-29 10:15:00-06', '22050302', 'ALBA CHACON ENRIQUE JAVIER', 'Ing. Electrónica', 5, 'Matutino', 'EFECTIVO', 'N/A', '5200-005-001-020', 500.00, 0, 500.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128637, '128637', '2026-10-29 10:30:00-06', '22050119', 'DE LA CRUZ HERNANDEZ TANIA JOSELYN', 'Ing. Gestión Emp.', 5, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-107', '5400-001-002-0149', 1200.00, 0, 1200.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128638, '128638', '2026-10-29 10:45:00-06', '24050211', 'DURON OLVERA FERNANDA ANAHI', 'Ing. Gestión Emp.', 2, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-108', '5400-001-002-0149', 1200.00, 0, 1200.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128639, '128639', '2026-10-29 11:00:00-06', '23050412', 'CRUZ FACUNDO NAYELI ESTEFANIA', 'Ing. Informática', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-109', '5400-001-002-0149', 1200.00, 0, 1200.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128640, '128640', '2026-10-29 11:15:00-06', '23050199', 'ORONA MARTINEZ OLIVER ALEXIS', 'Ing. Industrial', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-110', '5400-001-002-0149', 1200.00, 0, 1200.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128641, '128641', '2026-10-29 11:30:00-06', '23050871', 'VILLALOBOS TAMEZ ANGEL JAIME', 'Ing. Electrónica', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-111', '5400-001-002-0149', 1200.00, 0, 1200.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128642, '128642', '2026-10-29 11:45:00-06', '20050111', 'PADILLA VAZQUEZ HOMAR', 'Ing. Industrial', 9, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-112', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128643, '128643', '2026-10-29 12:00:00-06', '23050088', 'CONTRERAS RIVAS LIZETH AHANI', 'Ing. Gestión Emp.', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-113', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128644, '128644', '2026-10-29 12:15:00-06', '21050219', 'QUIROZ SANCHEZ ORLANDO ANTONIO', 'Ing. Informática', 7, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-114', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128645, '128645', '2026-10-29 12:30:00-06', '22050998', 'PEREZ MARTINEZ ALEXIA MONSERRAT', 'Ing. Gestión Emp.', 5, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-115', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128646, '128646', '2026-10-29 12:45:00-06', '21050882', 'LEON DUARTE ERIK SEBASTIAN', 'Ing. Industrial', 7, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-116', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128647, '128647', '2026-10-29 13:00:00-06', '22050331', 'BENITEZ RODRIGUEZ LUIS PABLO', 'Ing. Mecánica', 5, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-117', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128648, '128648', '2026-10-29 13:15:00-06', '21050772', 'RAMOS RIVAS YESSENIA', 'Ing. Gestión Emp.', 7, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-118', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128649, '128649', '2026-10-29 13:30:00-06', '23050303', 'LOPEZ GONZALEZ ALONSO EMMANUEL', 'Ing. Electrónica', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-119', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128650, '128650', '2026-10-29 13:45:00-06', '22050444', 'GONZALEZ REYES MARVYN JARETH', 'Ing. Informática', 5, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-120', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128651, '128651', '2026-10-29 14:00:00-06', '21050555', 'DE LA FUENTE CERNA NARDA GUADALUPE', 'Ing. Gestión Emp.', 7, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-121', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128652, '128652', '2026-10-29 14:15:00-06', '22050666', 'SIFUENTES JASSO CESAR ALEXANDRO', 'Ing. Industrial', 5, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-122', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128653, '128653', '2026-10-29 14:30:00-06', '23050777', 'OROZCO RANGEL DANIEL AZAEL', 'Ing. Electrónica', 4, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-123', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128654, '128654', '2026-10-29 14:45:00-06', '24050888', 'CAMARILLO PEREZ YAXENI SHECCID', 'Ing. Gestión Emp.', 2, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-124', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino'),
(128655, '128655', '2026-10-29 15:00:00-06', '22050774', 'VALENCIANO LARA IDALIA JAQUELINE', 'Ing. Gestión Emp.', 5, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2026-125', '5400-001-002-0261', 2000.00, 0, 2000.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino')
ON CONFLICT (numero_recibo) DO UPDATE SET
    folio_administrativo = EXCLUDED.folio_administrativo,
    fecha_operacion = EXCLUDED.fecha_operacion,
    alumno_matricula = EXCLUDED.alumno_matricula,
    alumno_nombre = EXCLUDED.alumno_nombre,
    metodo_pago = EXCLUDED.metodo_pago,
    subtotal = EXCLUDED.subtotal,
    total = EXCLUDED.total,
    estado = EXCLUDED.estado;

-- 4. Insertar Detalles de los Recibos
INSERT INTO detalles_recibo (recibo_id, descripcion, cantidad, cuota_unitario, descuento_beca, importe_total, periodo_ano)
SELECT r.id, 
  CASE 
    WHEN r.numero_recibo IN (128628, 128629, 128630, 128631, 128633) THEN 'CONSTANCIA DE ESTUDIOS'
    WHEN r.numero_recibo IN (128632, 128634) THEN 'CENTRO DE COMPUTO'
    WHEN r.numero_recibo IN (128635, 128636) THEN 'BAJA DEFINITIVA'
    WHEN r.numero_recibo BETWEEN 128637 AND 128641 THEN 'EXAMEN TOEFL (NUEVO)'
    ELSE 'CURSO DE TITULACION DE INGLES'
  END AS descripcion,
  1 AS cantidad,
  r.total AS cuota_unitario,
  0 AS descuento_beca,
  r.total AS importe_total,
  '2026-2' AS periodo_ano
FROM recibos r
WHERE r.numero_recibo BETWEEN 128628 AND 128655
AND NOT EXISTS (SELECT 1 FROM detalles_recibo d WHERE d.recibo_id = r.id);

COMMIT;
