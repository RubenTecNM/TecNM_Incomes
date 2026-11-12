-- ============================================================================
-- ETAPA 2: DATOS (MIGRACIÓN, LIMPIEZA, NORMALIZACIÓN Y POBLADO SEGURO)
-- Sistema de Control de Caja Universitaria - TecNM Campus Monclova
-- ============================================================================
-- Directriz: Migrar información, corregir duplicados/inconsistencias,
-- limpiar conceptos de pago, verificar relación de alumnos y matrículas,
-- validar movimientos históricos y registrar incidencias si las hubiera.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. CARGA DE CATÁLOGOS BASE INDEPENDIENTES
-- ----------------------------------------------------------------------------
INSERT INTO carreras (id_carrera, carrera, nombre_carrera, titulo, activo) VALUES
(64, 'Lic. Informática',          'LICENCIATURA EN INFORMATICA',          'LICENCIADO EN INFORMATICA', true),
(65, 'Ing. Mecánica',             'INGENIERIA MECANICA',                  'INGENIERO MECANICO', true),
(67, 'Ing. Industrial',           'INGENIERIA INDUSTRIAL',                'INGENIERO INDUSTRIAL', true),
(68, 'Ing. Electrónica',          'INGENIERIA ELECTRONICA',               'INGENIERO ELECTRONICO', true),
(69, 'Ing. Informática',          'INGENIERIA INFORMATICA',               'INGENIERO INFORMATICO', true),
(70, 'Ing. Gestión Emp.',         'INGENIERIA EN GESTION EMPRESARIAL',    'INGENIERO EN GESTION EMPRESARIAL', true),
(71, 'Ing. Energías Renovables',  'INGENIERIA EN ENERGIAS RENOVABLES',    'INGENIERO EN ENERGIAS RENOVABLES', true),
(74, 'Ing. Mecatrónica',          'INGENIERIA MECATRONICA',               'INGENIERO MECATRONICO', true)
ON CONFLICT (id_carrera) DO UPDATE SET
    carrera = EXCLUDED.carrera,
    nombre_carrera = EXCLUDED.nombre_carrera,
    titulo = EXCLUDED.titulo,
    activo = EXCLUDED.activo;

INSERT INTO periodos_academicos (codigo, descripcion, anio, ciclo, fecha_inicio, fecha_fin, activo) VALUES
('2012-1', 'SEMESTRE ENERO-JUNIO 2012',        2012, 'PRIMAVERA', '2012-01-09', '2012-06-30', false),
('2016-1', 'SEMESTRE ENERO-JUNIO 2016',        2016, 'PRIMAVERA', '2016-01-11', '2016-06-30', false),
('2016-2', 'SEMESTRE AGOSTO-ENERO 2016-2017',  2016, 'OTONO',     '2016-08-08', '2017-01-31', false),
('2024-2', 'SEMESTRE AGOSTO-DICIEMBRE 2024',   2024, 'OTONO',     '2024-08-12', '2024-12-20', false),
('2025-1', 'SEMESTRE ENERO-JUNIO 2025',        2025, 'PRIMAVERA', '2025-01-13', '2025-06-27', false),
('2025-2', 'SEMESTRE AGOSTO-DICIEMBRE 2025',   2025, 'OTONO',     '2025-08-11', '2025-12-19', false),
('2026-1', 'SEMESTRE ENERO-JUNIO 2026',        2026, 'PRIMAVERA', '2026-01-12', '2026-06-30', true)
ON CONFLICT (codigo) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    anio = EXCLUDED.anio,
    ciclo = EXCLUDED.ciclo,
    activo = EXCLUDED.activo;

-- ----------------------------------------------------------------------------
-- 2. USUARIOS Y PERSONAL DE VENTANILLA
-- Contraseña unificada predeterminada: Password123!
-- ----------------------------------------------------------------------------
INSERT INTO users (id, username, email, password, name, role, is_active) VALUES
('10000000-0000-4000-8000-000000000001', 'admin',   'admin@tecnm.local',   'AQAAAAIAAYagAAAAEPjbneKeORd2reFIG62af0ufOMPtwf64j0jpBznNBo3Y8K/BUoUW+IhJOm0b5iqWOg==', 'Administrador General', 'Admin',  true),
('10000000-0000-4000-8000-000000000002', 'cajero1', 'cajero1@tecnm.local', 'AQAAAAIAAYagAAAAECBhXWISKf+YayCz0xB8E4vyjO6chAfRLTq+f2eA4ztdtdDqA99jr+VsfZXUoKbfdQ==', 'Cajero Turno Matutino', 'Cajero', true),
('10000000-0000-4000-8000-000000000003', 'cajero2', 'cajero2@tecnm.local', 'AQAAAAIAAYagAAAAECBhXWISKf+YayCz0xB8E4vyjO6chAfRLTq+f2eA4ztdtdDqA99jr+VsfZXUoKbfdQ==', 'Cajero Turno Nocturno', 'Cajero', true),
('10000000-0000-4000-8000-000000000004', 'usuario', 'usuario@tecnm.local', 'AQAAAAIAAYagAAAAECBhXWISKf+YayCz0xB8E4vyjO6chAfRLTq+f2eA4ztdtdDqA99jr+VsfZXUoKbfdQ==', 'Usuario Operativo Demo', 'User',  true)
ON CONFLICT (username) DO UPDATE SET
    email = EXCLUDED.email,
    password = EXCLUDED.password,
    name = EXCLUDED.name,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active;

-- ----------------------------------------------------------------------------
-- 3. CONCEPTOS DE COBRO NORMALIZADOS (Sin periodos quemados en el nombre)
-- ----------------------------------------------------------------------------
INSERT INTO conceptos_cobro (id, clave, descripcion, cuota_base, orden, cuenta_referencia, aplica_beca, categoria, is_active) VALUES
('a0000000-0000-4000-8000-000000000001', '5200-001-002-004', 'Inscripción Semestral Regular',            1700.00, 1, '5200', true,  'Inscripción', true),
('a0000000-0000-4000-8000-000000000002', '5200-001-002-021', 'Reinscripción Semestral Tarifa A',         500.00, 2, '5200', true,  'Inscripción', true),
('a0000000-0000-4000-8000-000000000003', '5200-001-002-051', 'Reinscripción Semestral Tarifa B',         500.00, 3, '5200', true,  'Inscripción', true),
('a0000000-0000-4000-8000-000000000004', '5200-002-001-001', 'Inscripciones Generales Institucionales',  1350.00, 4, '5200', true,  'Inscripción', true),
('a0000000-0000-4000-8000-000000000005', 'INSC-VIG',         'Pago de Inscripción Periodo Vigente',       2600.00, 5, '5200', true,  'Inscripción', true),
('a0000000-0000-4000-8000-000000000006', 'INSC-ANT',         'Adeudo de Inscripción Periodos Anteriores', 2450.00, 6, '5200', false, 'Inscripción', true),
('a0000000-0000-4000-8000-000000000007', '5400-001-003-0001', 'Reinscripción Semestral Nivel 1',          520.00, 10, '5400', false, 'Inscripción', true),
('a0000000-0000-4000-8000-000000000008', '5400-001-003-0002', 'Reinscripción Semestral Nivel 2',          620.00, 11, '5400', false, 'Inscripción', true),
('a0000000-0000-4000-8000-000000000009', '5400-001-003-0003', 'Reinscripción Semestral Nivel 3',          620.00, 12, '5400', false, 'Inscripción', true),
('a0000000-0000-4000-8000-000000000010', '5400-001-003-0005', 'Reinscripción Semestral Nivel 5',          700.00, 13, '5400', false, 'Inscripción', true),
('a0000000-0000-4000-8000-000000000011', '5400-001-003-0006', 'Reinscripción Semestral Nivel 6',          700.00, 14, '5400', false, 'Inscripción', true),
('a0000000-0000-4000-8000-000000000012', '5400-001-002-0037', 'Inscripción Escolar Histórica',            1700.00, 20, '5400', true,  'Inscripción', true),
('a0000000-0000-4000-8000-000000000013', 'KARD',              'Kárdex Oficial de Calificaciones',          150.00, 30, '5200', false, 'Constancias',  true),
('a0000000-0000-4000-8000-000000000014', 'CONST',             'Constancia de Estudios con Calificaciones', 100.00, 31, '5200', false, 'Constancias',  true),
('a0000000-0000-4000-8000-000000000015', 'VERA',              'Curso de Verano (Por Asignatura)',         1200.00, 32, '5200', false, 'Cursos',       true),
('a0000000-0000-4000-8000-000000000016', 'TITU',              'Trámite de Titulación Integral y Cédula',  3800.00, 33, '5200', false, 'Otros',        true)
ON CONFLICT (clave) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    cuota_base = EXCLUDED.cuota_base,
    cuenta_referencia = EXCLUDED.cuenta_referencia,
    aplica_beca = EXCLUDED.aplica_beca,
    categoria = EXCLUDED.categoria,
    is_active = EXCLUDED.is_active;

-- ----------------------------------------------------------------------------
-- 4. PADRÓN DE ALUMNOS (Depurado y Desduplicado)
-- ----------------------------------------------------------------------------
INSERT INTO alumnos (matricula, nombre_completo, nombres, apellidos, sexo, id_carrera, carrera, semestre, turno, numero_ficha, cuenta_a, estatus, tiene_beca, porcentaje_beca)
VALUES
    ('G2605048',  'MARTINEZ SILVA MARIA JOSE',           'MARIA JOSE',           'MARTINEZ SILVA',          'F', 70, 'Ing. Gestión Emp.',         1, 'Matutino',   'F-2026-001', 24468, 'Inscrito', false, 0.00),
    ('M2505057',  'PALOS DIAZ MARIA FERNADA',            'MARIA FERNANDA',       'PALOS DIAZ',              'F', 67, 'Ing. Industrial',           1, 'Matutino',   'F-2025-089', 23877, 'Inscrito', false, 0.00),
    ('N2305000',  'CHAPOY LIMON CARLOS',                 'CARLOS',               'CHAPOY LIMON',            'M', 67, 'Ing. Industrial',           7, 'Matutino',   'F-2023-014', 11670, 'Inscrito', false, 0.00),
    ('120050011', 'DE LA TORRE CAMPOS DANIEL ARTURO',    'DANIEL ARTURO',        'DE LA TORRE CAMPOS',      'M', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-050', 12121, 'Inscrito', false, 0.00),
    ('120050012', 'DEL TORO LIRA FERNANDA',              'FERNANDA',             'DEL TORO LIRA',           'F', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-051', 11671, 'Inscrito', false, 0.00),
    ('120050013', 'DIAZ COSTILLA ANGEL GABRIEL',         'ANGEL GABRIEL',        'DIAZ COSTILLA',           'M', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-052', 12122, 'Inscrito', false, 0.00),
    ('120050023', 'MARINES YAÑEZ MARIO CUAUHTEMOC',      'MARIO CUAUHTEMOC',     'MARINES YAÑEZ',           'M', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-053', 11672, 'Inscrito', false, 0.00),
    ('120050032', 'RAMIREZ GONZALEZ ESTEFANIA ARISBETH', 'ESTEFANIA ARISBETH',   'RAMIREZ GONZALEZ',        'F', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-054', 11673, 'Inscrito', false, 0.00),
    ('120050040', 'TORRES TREJO VICTORIA ALEJANDRA',     'VICTORIA ALEJANDRA',   'TORRES TREJO',            'F', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-055', 11674, 'Inscrito', false, 0.00),
    ('120050041', 'TOVAR COVARRUBIAS JARED ISRAEL',      'JARED ISRAEL',         'TOVAR COVARRUBIAS',       'M', 69, 'Ing. Informática',          8, 'Matutino',   'F-2020-056', 11675, 'Inscrito', false, 0.00),
    ('N13050045', 'PEREZ SIFUENTES ALDO ULISES',         'ALDO ULISES',          'PEREZ SIFUENTES',         'M', 67, 'Ing. Industrial',           6, 'Matutino',   'F-2019-112', NULL,  'Inscrito', false, 0.00),
    ('N13050041', 'ORTIZ DURON LUIS MANUEL',             'LUIS MANUEL',          'ORTIZ DURON',             'M', 67, 'Ing. Industrial',           6, 'Matutino',   'F-2019-110', NULL,  'Inscrito', false, 0.00),
    ('G13050156', 'DAVILA HERNANDEZ ANA PATRICIA',       'ANA PATRICIA',         'DAVILA HERNANDEZ',        'F', 70, 'Ing. Gestión Emp.',         5, 'Matutino',   'F-2019-215', NULL,  'Inscrito', false, 0.00),
    ('E15050004', 'REQUENA RODRIGUEZ NESTOR OMAR',       'NESTOR OMAR',          'REQUENA RODRIGUEZ',       'M', 68, 'Ing. Electrónica',          3, 'Nocturno',   'F-2021-004', NULL,  'Inscrito', false, 0.00),
    ('N12050104', 'BARRERA TOVAR JESUS ENRIQUE',         'JESUS ENRIQUE',        'BARRERA TOVAR',           'M', 67, 'Ing. Industrial',           8, 'Nocturno',   'F-2018-090', NULL,  'Inscrito', false, 0.00),
    ('G13050219', 'HERNANDEZ CASTILLO ARELY SARAHI',     'ARELY SARAHI',         'HERNANDEZ CASTILLO',      'F', 70, 'Ing. Gestión Emp.',         6, 'Matutino',   'F-2019-219', NULL,  'Inscrito', false, 0.00),
    ('G14050252', 'MUÑOZ DE LEON ILSE ARACELI',          'ILSE ARACELI',          'MUÑOZ DE LEON',           'F', 70, 'Ing. Gestión Emp.',         4, 'Matutino',   'F-2020-252', NULL,  'Inscrito', false, 0.00),
    ('N15050011', 'VILLASTRIGO GARCIA SABINO EMMANUEL',  'SABINO EMMANUEL',      'VILLASTRIGO GARCIA',      'M', 67, 'Ing. Industrial',           2, 'Matutino',   'F-2021-011', NULL,  'Inscrito', false, 0.00),
    ('G13050164', 'GUTIERREZ SALAZAR CLAUDIA MONSERRAT', 'CLAUDIA MONSERRAT',    'GUTIERREZ SALAZAR',       'F', 70, 'Ing. Gestión Emp.',         6, 'Matutino',   'F-2019-164', NULL,  'Inscrito', false, 0.00),
    ('N12050487', 'IBARRA MARTINEZ JULIO CESAR',         'JULIO CESAR',          'IBARRA MARTINEZ',         'M', 67, 'Ing. Industrial',           8, 'Nocturno',   'F-2018-487', NULL,  'Inscrito', false, 0.00),
    ('I11050186', 'GUZMAN GUAJARDO BRANDO ISRAEL',       'BRANDO ISRAEL',        'GUZMAN GUAJARDO',         'M', 69, 'Ing. Informática',          2, 'Matutino',   'F-2017-040', NULL,  'Inscrito', false, 0.00),
    ('I11050180', 'DELGADILLO GELACIO IRMA BERENICE',    'IRMA BERENICE',        'DELGADILLO GELACIO',      'F', 69, 'Ing. Informática',          1, 'Nocturno',   'F-2017-038', NULL,  'Inscrito', true,  50.00),
    ('I11050199', 'OROZCO ALVARADO KAREN',               'KAREN',                'OROZCO ALVARADO',         'F', 69, 'Ing. Informática',          1, 'Matutino',   'F-2017-062', NULL,  'Inscrito', true,  25.00),
    ('E11050286', 'MARTINEZ ALFARO LUIS ANGEL',          'LUIS ANGEL',           'MARTINEZ ALFARO',         'M', 68, 'Ing. Electrónica',          1, 'Matutino',   'F-2017-080', NULL,  'Baja Temporal', false, 0.00),
    ('E11050559', 'FLORES EVANGELISTA ESTEBAN DAMIAN',   'ESTEBAN DAMIAN',       'FLORES EVANGELISTA',      'M', 68, 'Ing. Electrónica',          1, 'Nocturno',   'F-2017-559', NULL,  'Inscrito', true,  25.00),
    ('23050243',  'ORTEGON HERNANDEZ KLEBER',            'KLEBER',               'ORTEGON HERNANDEZ',       'M', 67, 'Ing. Industrial',           4, 'Matutino',   'F-2023-243', 23050, 'Inscrito', false, 0.00),
    ('23050118',  'GARCIA ZAVALA LUIS FERNANDO',         'LUIS FERNANDO',        'GARCIA ZAVALA',           'M', 74, 'Ing. Mecatrónica',          3, 'Matutino',   'F-2023-118', 23051, 'Inscrito', false, 0.00),
    ('22050890',  'LOPEZ SANCHEZ MARIANA',               'MARIANA',              'LOPEZ SANCHEZ',           'F', 70, 'Ing. Gestión Emp.',         6, 'Matutino',   'F-2022-890', 22050, 'Inscrito', true,  50.00),
    ('24050012',  'RODRIGUEZ MORALES CARLOS',            'CARLOS',               'RODRIGUEZ MORALES',       'M', 69, 'Ing. Informática',          1, 'Vespertino', 'F-2024-012', 24050, 'Inscrito', false, 0.00),
    ('21050334',  'HERNANDEZ RAMIREZ SOFIA',             'SOFIA',                'HERNANDEZ RAMIREZ',       'F', 71, 'Ing. Energías Renovables',  8, 'Matutino',   'F-2021-334', 21050, 'Egresado', false, 0.00)
ON CONFLICT (matricula) DO UPDATE SET
    nombre_completo = EXCLUDED.nombre_completo,
    semestre = EXCLUDED.semestre,
    turno = EXCLUDED.turno,
    estatus = EXCLUDED.estatus,
    tiene_beca = EXCLUDED.tiene_beca,
    porcentaje_beca = EXCLUDED.porcentaje_beca;

-- ----------------------------------------------------------------------------
-- 5. HISTORIAL DE MATRÍCULAS (Mapeo de Alumnos con Cambio de Matrícula)
-- ----------------------------------------------------------------------------
INSERT INTO alumno_matriculas_historial (matricula_alumno, matricula_previa, id_periodo, motivo_cambio)
VALUES
    ('23050243', 'P23050243', (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2024-2'), 'Transición de matrícula de propedéutico a matrícula oficial'),
    ('22050890', 'G22050890', (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2025-1'), 'Regularización de expediente administrativo')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. BECAS Y ADEUDOS HISTÓRICOS
-- ----------------------------------------------------------------------------
INSERT INTO becas_descuentos (matricula, id_periodo, tipo_beca, porcentaje, monto_fijo, motivo, activa)
VALUES
    ('22050890', (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2026-1'), 'ACADEMICA', 50.00, 0.00, 'Promedio superior a 95', true),
    ('I11050180', (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2012-1'), 'APOYO_INSTITUCIONAL', 5.88, 100.00, 'Convenio sindical', true)
ON CONFLICT DO NOTHING;

INSERT INTO adeudos (matricula, concepto_cobro, id_periodo, monto_original, saldo_pendiente, fecha_limite, estado)
VALUES
    ('23050243', 'Pago de Inscripción', (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2025-2'), 2600.00, 2600.00, '2025-10-30', 'PENDIENTE'),
    ('23050243', 'Pago de Inscripción', (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2025-1'), 2450.00, 1000.00, '2025-04-30', 'PARCIAL'),
    ('N2305000', 'Curso de Verano',     (SELECT id_periodo FROM periodos_academicos WHERE codigo = '2024-2'), 1200.00, 1200.00, '2024-07-15', 'PENDIENTE')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. FOLIOS ADMINISTRATIVOS (Serie Unificada 'A')
-- ----------------------------------------------------------------------------
INSERT INTO folios (numero_folio, serie) VALUES
(1, 'A'), (2, 'A'), (3, 'A'), (4, 'A'), (5, 'A'), (9, 'A'), (10, 'A'), (12, 'A'), (14, 'A'), (18, 'A'),
(2922, 'A'), (3354, 'A'), (3661, 'A'), (3662, 'A'), (3692, 'A'),
(5001, 'A'), (5002, 'A'), (5003, 'A')
ON CONFLICT (numero_folio) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 8. PÓLIZAS DE INGRESO
-- ----------------------------------------------------------------------------
INSERT INTO polizas_ingreso (numero_poliza, fecha_poliza, total_recaudado, cajero_usuario, estado) VALUES
('POL-2016-06-001', '2016-06-07', 2880.00, 'cajero1', 'CONSOLIDADA'),
('POL-2016-06-002', '2016-06-08', 3260.00, 'cajero1', 'CONSOLIDADA'),
('POL-2012-01-001', '2012-01-23', 6500.00, 'cajero2', 'CONSOLIDADA')
ON CONFLICT (numero_poliza) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 9. RECIBOS HISTÓRICOS Y DESGLOSES
-- ----------------------------------------------------------------------------
INSERT INTO recibos (
    id, folio_administrativo, fecha_operacion, alumno_matricula, alumno_nombre, alumno_carrera, alumno_semestre, alumno_turno,
    metodo_pago, referencia_bancaria, subtotal, descuento_total, total, status, estado, tipo_recibo, cajero_usuario, cajero_nombre
) VALUES
('b0000000-0000-4000-8000-000000000001', '1',  '2016-06-07 08:30:00-06', 'N13050045', 'PEREZ SIFUENTES ALDO ULISES',         'Ing. Industrial',  6, 'Matutino', 'EFECTIVO', '0', 620.00, 0.00, 620.00, 1, 'PREVIO', 'PREVIO', 'cajero1', 'Cajero Turno Matutino'),
('b0000000-0000-4000-8000-000000000002', '2',  '2016-06-07 09:15:00-06', 'N13050041', 'ORTIZ DURON LUIS MANUEL',             'Ing. Industrial',  6, 'Matutino', 'EFECTIVO', '0', 620.00, 0.00, 620.00, 1, 'PREVIO', 'PREVIO', 'cajero1', 'Cajero Turno Matutino'),
('b0000000-0000-4000-8000-000000000003', '3',  '2016-06-07 10:00:00-06', 'G13050156', 'DAVILA HERNANDEZ ANA PATRICIA',       'Ing. Gestión Emp.', 5, 'Matutino', 'EFECTIVO', '0', 620.00, 0.00, 620.00, 1, 'PREVIO', 'PREVIO', 'cajero1', 'Cajero Turno Matutino'),
('b0000000-0000-4000-8000-000000000004', '4',  '2016-06-07 11:20:00-06', 'E15050004', 'REQUENA RODRIGUEZ NESTOR OMAR',       'Ing. Electrónica', 3, 'Nocturno', 'EFECTIVO', '0', 520.00, 0.00, 520.00, 1, 'PREVIO', 'PREVIO', 'cajero1', 'Cajero Turno Matutino'),
('b0000000-0000-4000-8000-000000000005', '5',  '2016-06-07 12:45:00-06', 'N12050104', 'BARRERA TOVAR JESUS ENRIQUE',         'Ing. Industrial',  8, 'Nocturno', 'EFECTIVO', '0', 520.00, 0.00, 520.00, 1, 'PREVIO', 'PREVIO', 'cajero1', 'Cajero Turno Matutino'),
('c0000000-0000-4000-8000-000000000001', '3692', '2012-01-23 10:00:00-06', 'I11050186', 'GUZMAN GUAJARDO BRANDO ISRAEL',        'Ing. Informática', 2, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2012-001', 1700.00,   0.00, 1700.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero2', 'Cajero Turno Nocturno'),
('c0000000-0000-4000-8000-000000000002', '3354', '2012-01-23 10:30:00-06', 'I11050180', 'DELGADILLO GELACIO IRMA BERENICE',     'Ing. Informática', 1, 'Nocturno', 'DEPOSITO_BANCARIO', 'REF-2012-002', 1700.00, 100.00, 1600.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero2', 'Cajero Turno Nocturno'),
('c0000000-0000-4000-8000-000000000003', '3661', '2012-01-23 11:00:00-06', 'I11050199', 'OROZCO ALVARADO KAREN',                'Ing. Informática', 1, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2012-003', 1700.00, 100.00, 1600.00, 1, 'REGISTRADO', 'DEFINITIVO', 'cajero2', 'Cajero Turno Nocturno'),
('c0000000-0000-4000-8000-000000000004', '2922', '2012-01-23 11:30:00-06', 'E11050286', 'MARTINEZ ALFARO LUIS ANGEL',           'Ing. Electrónica', 1, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2012-004', 1700.00, 100.00, 1600.00, 0, 'CANCELADO',  'DEFINITIVO', 'cajero1', 'Cajero Turno Matutino')
ON CONFLICT (id) DO NOTHING;

-- Detalle de partidas
INSERT INTO detalles_recibo (id, recibo_id, concepto_id, descripcion, cantidad, cuota_unitario, descuento_beca, importe_total, periodo_ano)
VALUES
('d0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', (SELECT id FROM conceptos_cobro WHERE clave = '5200-001-002-004'), 'Inscripción Semestral Regular', 1, 1700.00, 0.00, 1700.00, '2012-1'),
('d0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002', (SELECT id FROM conceptos_cobro WHERE clave = '5200-001-002-004'), 'Inscripción Semestral Regular', 1, 1700.00, 100.00, 1600.00, '2012-1'),
('d0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000003', (SELECT id FROM conceptos_cobro WHERE clave = '5200-001-002-004'), 'Inscripción Semestral Regular', 1, 1700.00, 100.00, 1600.00, '2012-1'),
('d0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004', (SELECT id FROM conceptos_cobro WHERE clave = '5200-001-002-004'), 'Inscripción Semestral Regular', 1, 1700.00, 100.00, 1600.00, '2012-1')
ON CONFLICT (id) DO NOTHING;

-- Movimientos de pago
INSERT INTO movimientos_pago (recibo_id, forma_pago, referencia_bancaria, monto, fecha_movimiento, cajero_usuario)
VALUES
('c0000000-0000-4000-8000-000000000001', 'DEPOSITO_BANCARIO', 'REF-2012-001', 1700.00, '2012-01-23 10:00:00-06', 'cajero2'),
('c0000000-0000-4000-8000-000000000002', 'DEPOSITO_BANCARIO', 'REF-2012-002', 1600.00, '2012-01-23 10:30:00-06', 'cajero2'),
('c0000000-0000-4000-8000-000000000003', 'DEPOSITO_BANCARIO', 'REF-2012-003', 1600.00, '2012-01-23 11:00:00-06', 'cajero2'),
('c0000000-0000-4000-8000-000000000004', 'DEPOSITO_BANCARIO', 'REF-2012-004', 1600.00, '2012-01-23 11:30:00-06', 'cajero1')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 10. VALIDACIÓN DE INTEGRIDAD Y REGISTRO EN BITÁCORA DE INCIDENCIAS
-- ----------------------------------------------------------------------------
-- Detectar posibles huérfanos o incongruencias y registrarlas en migracion_incidencias
INSERT INTO migracion_incidencias (origen_tabla, identificador_registro, error_detectado, resuelto, notas_resolucion)
SELECT 'alumnos_origen', matricula, 'Alumno sin carrera asignada en origen', true, 'Asignada carrera por defecto según plan escolar'
FROM alumnos WHERE id_carrera IS NULL;

COMMIT;
