-- ============================================================================
-- STAGE 2: DATA POPULATION & SEEDING - ENGLISH TABLES
-- University Cash Register Management System - TecNM Campus Monclova
-- ============================================================================
-- Design rules:
-- 1. 'careers' populated with full_name ONLY (no short_name).
-- 2. 'payment_concepts' preserve original institutional descriptions in Spanish.
-- 3. 'students' associated with official careers and historical IDs.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. CAREERS (Full Institutional Names Only)
-- ----------------------------------------------------------------------------
INSERT INTO careers (career_id, full_name, degree_title, is_active) VALUES
(64, 'LICENCIATURA EN INFORMATICA',          'LICENCIADO EN INFORMATICA', true),
(65, 'INGENIERIA MECANICA',                  'INGENIERO MECANICO', true),
(67, 'INGENIERIA INDUSTRIAL',                'INGENIERO INDUSTRIAL', true),
(68, 'INGENIERIA ELECTRONICA',               'INGENIERO ELECTRONICO', true),
(69, 'INGENIERIA INFORMATICA',               'INGENIERO INFORMATICO', true),
(70, 'INGENIERIA EN GESTION EMPRESARIAL',    'INGENIERO EN GESTION EMPRESARIAL', true),
(71, 'INGENIERIA EN ENERGIAS RENOVABLES',    'INGENIERO EN ENERGIAS RENOVABLES', true),
(74, 'INGENIERIA MECATRONICA',               'INGENIERO MECATRONICO', true)
ON CONFLICT (career_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    degree_title = EXCLUDED.degree_title,
    is_active = EXCLUDED.is_active;

-- ----------------------------------------------------------------------------
-- 2. ACADEMIC TERMS
-- ----------------------------------------------------------------------------
INSERT INTO academic_terms (code, description, year, cycle, start_date, end_date, is_active) VALUES
('2012-1', 'SEMESTRE ENERO-JUNIO 2012',        2012, 'PRIMAVERA', '2012-01-09', '2012-06-30', false),
('2016-1', 'SEMESTRE ENERO-JUNIO 2016',        2016, 'PRIMAVERA', '2016-01-11', '2016-06-30', false),
('2016-2', 'SEMESTRE AGOSTO-ENERO 2016-2017',  2016, 'OTONO',     '2016-08-08', '2017-01-31', false),
('2024-2', 'SEMESTRE AGOSTO-DICIEMBRE 2024',   2024, 'OTONO',     '2024-08-12', '2024-12-20', false),
('2025-1', 'SEMESTRE ENERO-JUNIO 2025',        2025, 'PRIMAVERA', '2025-01-13', '2025-06-27', false),
('2025-2', 'SEMESTRE AGOSTO-DICIEMBRE 2025',   2025, 'OTONO',     '2025-08-11', '2025-12-19', false),
('2026-1', 'SEMESTRE ENERO-JUNIO 2026',        2026, 'PRIMAVERA', '2026-01-12', '2026-06-30', true)
ON CONFLICT (code) DO UPDATE SET
    description = EXCLUDED.description,
    year = EXCLUDED.year,
    cycle = EXCLUDED.cycle,
    is_active = EXCLUDED.is_active;

-- ----------------------------------------------------------------------------
-- 3. SYSTEM USERS
-- Default password: Password123!
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
-- 4. PAYMENT CONCEPTS (Descriptions kept EXACTLY as original in Spanish)
-- ----------------------------------------------------------------------------
INSERT INTO payment_concepts (code, description, base_fee, display_order, ledger_account_code, allows_scholarship, category, is_active) VALUES
('5200-001-002-004', 'INSCRIPCION SEM. AGO 2012-ENERO 2013',        1700.00, 1, '5200', true,  'Inscripción', true),
('5200-001-002-021', 'REINSCRIPCION SEM. AGOSTO 2022-ENERO 2023',    500.00, 2, '5200', true,  'Inscripción', true),
('5200-001-002-051', 'REINSCRIPCION SEM. AGOSTO 2025-ENERO 2026',    500.00, 3, '5200', true,  'Inscripción', true),
('5200-001-002-082', 'REINSCRIPCION SEM FEB-JUL 2023',               500.00, 4, '5200', true,  'Inscripción', true),
('5200-002-001-001', 'INSCRIPCIONES GENERALES',                      1350.00, 5, '5200', true,  'Inscripción', true),
('INSC-VIG',         'Pago de Inscripción (Periodo Vigente 2026)',   2600.00, 6, '5200', true,  'Inscripción', true),
('INSC-ANT',         'Adeudo Inscripción Periodos Anteriores',       2450.00, 7, '5200', false, 'Inscripción', true),
('5400-001-003-0001', 'REINSCRIPCION SEMESTRAL TARIFA 1',             520.00, 10, '5400', false, 'Inscripción', true),
('5400-001-003-0002', 'REINSCRIPCION SEMESTRAL TARIFA 2',             620.00, 11, '5400', false, 'Inscripción', true),
('5400-001-003-0003', 'REINSCRIPCION SEMESTRAL TARIFA 3',             620.00, 12, '5400', false, 'Inscripción', true),
('5400-001-003-0005', 'REINSCRIPCION SEMESTRAL TARIFA 5',             700.00, 13, '5400', false, 'Inscripción', true),
('5400-001-003-0006', 'REINSCRIPCION SEMESTRAL TARIFA 6',             700.00, 14, '5400', false, 'Inscripción', true),
('5400-001-002-0037', 'INSCRIPCION SEMESTRAL 2012',                  1700.00, 20, '5400', true,  'Inscripción', true),
('5400-001-002-0038', 'DESCUENTO DE INSCRIPCION',                    -100.00, 21, '5400', false, 'Descuentos',  true),
('KARD',              'KARDEX OFICIAL',                               150.00, 30, '5200', false, 'Constancias',  true),
('CONST',             'Constancia de Estudios con Calificaciones',    100.00, 31, '5200', false, 'Constancias',  true),
('VERA',              'Curso de Verano (Por Asignatura)',            1200.00, 32, '5200', false, 'Cursos',       true),
('TITU',              'Trámite de Titulación Integral y Cédula',     3800.00, 33, '5200', false, 'Otros',        true)
ON CONFLICT (code) DO UPDATE SET
    description = EXCLUDED.description,
    base_fee = EXCLUDED.base_fee,
    ledger_account_code = EXCLUDED.ledger_account_code,
    allows_scholarship = EXCLUDED.allows_scholarship,
    category = EXCLUDED.category,
    is_active = EXCLUDED.is_active;

-- ----------------------------------------------------------------------------
-- 5. STUDENTS (Populated with Career Full Names)
-- ----------------------------------------------------------------------------
INSERT INTO students (student_id, full_name, first_name, last_name, gender, career_id, career_name, semester, shift, admission_ticket_number, internal_account_number, academic_status, has_scholarship, scholarship_percentage)
VALUES
    ('G2605048',  'MARTINEZ SILVA MARIA JOSE',           'MARIA JOSE',           'MARTINEZ SILVA',          'F', 70, 'INGENIERIA EN GESTION EMPRESARIAL', 1, 'Matutino',   'F-2026-001', 24468, 'Inscrito', false, 0.00),
    ('M2505057',  'PALOS DIAZ MARIA FERNADA',            'MARIA FERNANDA',       'PALOS DIAZ',              'F', 67, 'INGENIERIA INDUSTRIAL',           1, 'Matutino',   'F-2025-089', 23877, 'Inscrito', false, 0.00),
    ('N2305000',  'CHAPOY LIMON CARLOS',                 'CARLOS',               'CHAPOY LIMON',            'M', 67, 'INGENIERIA INDUSTRIAL',           7, 'Matutino',   'F-2023-014', 11670, 'Inscrito', false, 0.00),
    ('120050011', 'DE LA TORRE CAMPOS DANIEL ARTURO',    'DANIEL ARTURO',        'DE LA TORRE CAMPOS',      'M', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-050', 12121, 'Inscrito', false, 0.00),
    ('120050012', 'DEL TORO LIRA FERNANDA',              'FERNANDA',             'DEL TORO LIRA',           'F', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-051', 11671, 'Inscrito', false, 0.00),
    ('120050013', 'DIAZ COSTILLA ANGEL GABRIEL',         'ANGEL GABRIEL',        'DIAZ COSTILLA',           'M', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-052', 12122, 'Inscrito', false, 0.00),
    ('120050023', 'MARINES YAÑEZ MARIO CUAUHTEMOC',      'MARIO CUAUHTEMOC',     'MARINES YAÑEZ',           'M', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-053', 11672, 'Inscrito', false, 0.00),
    ('120050032', 'RAMIREZ GONZALEZ ESTEFANIA ARISBETH', 'ESTEFANIA ARISBETH',   'RAMIREZ GONZALEZ',        'F', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-054', 11673, 'Inscrito', false, 0.00),
    ('120050040', 'TORRES TREJO VICTORIA ALEJANDRA',     'VICTORIA ALEJANDRA',   'TORRES TREJO',            'F', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-055', 11674, 'Inscrito', false, 0.00),
    ('120050041', 'TOVAR COVARRUBIAS JARED ISRAEL',      'JARED ISRAEL',         'TOVAR COVARRUBIAS',       'M', 69, 'INGENIERIA INFORMATICA',          8, 'Matutino',   'F-2020-056', 11675, 'Inscrito', false, 0.00),
    ('N13050045', 'PEREZ SIFUENTES ALDO ULISES',         'ALDO ULISES',          'PEREZ SIFUENTES',         'M', 67, 'INGENIERIA INDUSTRIAL',           6, 'Matutino',   'F-2019-112', NULL,  'Inscrito', false, 0.00),
    ('N13050041', 'ORTIZ DURON LUIS MANUEL',             'LUIS MANUEL',          'ORTIZ DURON',             'M', 67, 'INGENIERIA INDUSTRIAL',           6, 'Matutino',   'F-2019-110', NULL,  'Inscrito', false, 0.00),
    ('G13050156', 'DAVILA HERNANDEZ ANA PATRICIA',       'ANA PATRICIA',         'DAVILA HERNANDEZ',        'F', 70, 'INGENIERIA EN GESTION EMPRESARIAL', 5, 'Matutino',   'F-2019-215', NULL,  'Inscrito', false, 0.00),
    ('E15050004', 'REQUENA RODRIGUEZ NESTOR OMAR',       'NESTOR OMAR',          'REQUENA RODRIGUEZ',       'M', 68, 'INGENIERIA ELECTRONICA',          3, 'Nocturno',   'F-2021-004', NULL,  'Inscrito', false, 0.00),
    ('N12050104', 'BARRERA TOVAR JESUS ENRIQUE',         'JESUS ENRIQUE',        'BARRERA TOVAR',           'M', 67, 'INGENIERIA INDUSTRIAL',           8, 'Nocturno',   'F-2018-090', NULL,  'Inscrito', false, 0.00),
    ('G13050219', 'HERNANDEZ CASTILLO ARELY SARAHI',     'ARELY SARAHI',         'HERNANDEZ CASTILLO',      'F', 70, 'INGENIERIA EN GESTION EMPRESARIAL', 6, 'Matutino',   'F-2019-219', NULL,  'Inscrito', false, 0.00),
    ('G14050252', 'MUÑOZ DE LEON ILSE ARACELI',          'ILSE ARACELI',          'MUÑOZ DE LEON',           'F', 70, 'INGENIERIA EN GESTION EMPRESARIAL', 4, 'Matutino',   'F-2020-252', NULL,  'Inscrito', false, 0.00),
    ('N15050011', 'VILLASTRIGO GARCIA SABINO EMMANUEL',  'SABINO EMMANUEL',      'VILLASTRIGO GARCIA',      'M', 67, 'INGENIERIA INDUSTRIAL',           2, 'Matutino',   'F-2021-011', NULL,  'Inscrito', false, 0.00),
    ('G13050164', 'GUTIERREZ SALAZAR CLAUDIA MONSERRAT', 'CLAUDIA MONSERRAT',    'GUTIERREZ SALAZAR',       'F', 70, 'INGENIERIA EN GESTION EMPRESARIAL', 6, 'Matutino',   'F-2019-164', NULL,  'Inscrito', false, 0.00),
    ('N12050487', 'IBARRA MARTINEZ JULIO CESAR',         'JULIO CESAR',          'IBARRA MARTINEZ',         'M', 67, 'INGENIERIA INDUSTRIAL',           8, 'Nocturno',   'F-2018-487', NULL,  'Inscrito', false, 0.00),
    ('I11050186', 'GUZMAN GUAJARDO BRANDO ISRAEL',       'BRANDO ISRAEL',        'GUZMAN GUAJARDO',         'M', 69, 'INGENIERIA INFORMATICA',          2, 'Matutino',   'F-2017-040', NULL,  'Inscrito', false, 0.00),
    ('I11050180', 'DELGADILLO GELACIO IRMA BERENICE',    'IRMA BERENICE',        'DELGADILLO GELACIO',      'F', 69, 'INGENIERIA INFORMATICA',          1, 'Nocturno',   'F-2017-038', NULL,  'Inscrito', true,  50.00),
    ('I11050199', 'OROZCO ALVARADO KAREN',               'KAREN',                'OROZCO ALVARADO',         'F', 69, 'INGENIERIA INFORMATICA',          1, 'Matutino',   'F-2017-062', NULL,  'Inscrito', true,  25.00),
    ('E11050286', 'MARTINEZ ALFARO LUIS ANGEL',          'LUIS ANGEL',           'MARTINEZ ALFARO',         'M', 68, 'INGENIERIA ELECTRONICA',          1, 'Matutino',   'F-2017-080', NULL,  'Baja Temporal', false, 0.00),
    ('E11050559', 'FLORES EVANGELISTA ESTEBAN DAMIAN',   'ESTEBAN DAMIAN',       'FLORES EVANGELISTA',      'M', 68, 'INGENIERIA ELECTRONICA',          1, 'Nocturno',   'F-2017-559', NULL,  'Inscrito', true,  25.00),
    ('23050243',  'ORTEGON HERNANDEZ KLEBER',            'KLEBER',               'ORTEGON HERNANDEZ',       'M', 67, 'INGENIERIA INDUSTRIAL',           4, 'Matutino',   'F-2023-243', 23050, 'Inscrito', false, 0.00),
    ('23050118',  'GARCIA ZAVALA LUIS FERNANDO',         'LUIS FERNANDO',        'GARCIA ZAVALA',           'M', 74, 'INGENIERIA MECATRONICA',          3, 'Matutino',   'F-2023-118', 23051, 'Inscrito', false, 0.00),
    ('22050890',  'LOPEZ SANCHEZ MARIANA',               'MARIANA',              'LOPEZ SANCHEZ',           'F', 70, 'INGENIERIA EN GESTION EMPRESARIAL', 6, 'Matutino',   'F-2022-890', 22050, 'Inscrito', true,  50.00),
    ('24050012',  'RODRIGUEZ MORALES CARLOS',            'CARLOS',               'RODRIGUEZ MORALES',       'M', 69, 'INGENIERIA INFORMATICA',          1, 'Vespertino', 'F-2024-012', 24050, 'Inscrito', false, 0.00),
    ('21050334',  'HERNANDEZ RAMIREZ SOFIA',             'SOFIA',                'HERNANDEZ RAMIREZ',       'F', 71, 'INGENIERIA EN ENERGIAS RENOVABLES', 8, 'Matutino',   'F-2021-334', 21050, 'Egresado', false, 0.00)
ON CONFLICT (student_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    career_name = EXCLUDED.career_name,
    semester = EXCLUDED.semester,
    shift = EXCLUDED.shift,
    academic_status = EXCLUDED.academic_status;

-- ----------------------------------------------------------------------------
-- 6. HISTORICAL STUDENT IDS
-- ----------------------------------------------------------------------------
INSERT INTO student_enrollment_history (student_id, previous_student_id, term_id, change_reason)
VALUES
    ('23050243', 'P23050243', (SELECT term_id FROM academic_terms WHERE code = '2024-2'), 'Transición de matrícula de propedéutico a matrícula oficial'),
    ('22050890', 'G22050890', (SELECT term_id FROM academic_terms WHERE code = '2025-1'), 'Regularización de expediente administrativo')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. SCHOLARSHIPS & STUDENT DEBTS
-- ----------------------------------------------------------------------------
INSERT INTO scholarships (student_id, term_id, scholarship_type, percentage, fixed_amount, reason, is_active)
VALUES
    ('22050890', (SELECT term_id FROM academic_terms WHERE code = '2026-1'), 'ACADEMICA', 50.00, 0.00, 'Promedio superior a 95', true),
    ('I11050180', (SELECT term_id FROM academic_terms WHERE code = '2012-1'), 'APOYO_INSTITUCIONAL', 5.88, 100.00, 'Convenio sindical', true)
ON CONFLICT DO NOTHING;

INSERT INTO student_debts (student_id, concept_name, term_id, original_amount, pending_balance, due_date, status)
VALUES
    ('23050243', 'Pago de Inscripción', (SELECT term_id FROM academic_terms WHERE code = '2025-2'), 2600.00, 2600.00, '2025-10-30', 'PENDING'),
    ('23050243', 'Pago de Inscripción', (SELECT term_id FROM academic_terms WHERE code = '2025-1'), 2450.00, 1000.00, '2025-04-30', 'PARTIAL'),
    ('N2305000', 'Curso de Verano',     (SELECT term_id FROM academic_terms WHERE code = '2024-2'), 1200.00, 1200.00, '2024-07-15', 'PENDING')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 8. RECEIPT FOLIOS
-- ----------------------------------------------------------------------------
INSERT INTO receipt_folios (folio_number, series) VALUES
(1, 'A'), (2, 'A'), (3, 'A'), (4, 'A'), (5, 'A'), (9, 'A'), (10, 'A'), (12, 'A'), (14, 'A'), (18, 'A'),
(2922, 'A'), (3354, 'A'), (3661, 'A'), (3662, 'A'), (3692, 'A'),
(5001, 'A'), (5002, 'A'), (5003, 'A')
ON CONFLICT (folio_number) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 9. REVENUE POLICIES
-- ----------------------------------------------------------------------------
INSERT INTO revenue_policies (policy_number, policy_date, total_collected, cashier_username, status) VALUES
('POL-2016-06-001', '2016-06-07', 2880.00, 'cajero1', 'CONSOLIDATED'),
('POL-2016-06-002', '2016-06-08', 3260.00, 'cajero1', 'CONSOLIDATED'),
('POL-2012-01-001', '2012-01-23', 6500.00, 'cajero2', 'CONSOLIDATED')
ON CONFLICT (policy_number) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 10. RECEIPTS & ITEMS
-- ----------------------------------------------------------------------------
INSERT INTO receipts (
    id, folio_number, issued_at, student_id, student_name, student_career, student_semester, student_shift,
    payment_method, bank_reference, subtotal, discount_total, total, status_code, status, receipt_type, cashier_username, cashier_name
) VALUES
('b0000000-0000-4000-8000-000000000001', '1',  '2016-06-07 08:30:00-06', 'N13050045', 'PEREZ SIFUENTES ALDO ULISES',         'INGENIERIA INDUSTRIAL',  6, 'Matutino', 'EFECTIVO', '0', 620.00, 0.00, 620.00, 1, 'PROVISIONAL', 'PROVISIONAL', 'cajero1', 'Cajero Turno Matutino'),
('b0000000-0000-4000-8000-000000000002', '2',  '2016-06-07 09:15:00-06', 'N13050041', 'ORTIZ DURON LUIS MANUEL',             'INGENIERIA INDUSTRIAL',  6, 'Matutino', 'EFECTIVO', '0', 620.00, 0.00, 620.00, 1, 'PROVISIONAL', 'PROVISIONAL', 'cajero1', 'Cajero Turno Matutino'),
('b0000000-0000-4000-8000-000000000003', '3',  '2016-06-07 10:00:00-06', 'G13050156', 'DAVILA HERNANDEZ ANA PATRICIA',       'INGENIERIA EN GESTION EMPRESARIAL', 5, 'Matutino', 'EFECTIVO', '0', 620.00, 0.00, 620.00, 1, 'PROVISIONAL', 'PROVISIONAL', 'cajero1', 'Cajero Turno Matutino'),
('c0000000-0000-4000-8000-000000000001', '3692', '2012-01-23 10:00:00-06', 'I11050186', 'GUZMAN GUAJARDO BRANDO ISRAEL',        'INGENIERIA INFORMATICA', 2, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2012-001', 1700.00,   0.00, 1700.00, 1, 'REGISTERED', 'FINAL', 'cajero2', 'Cajero Turno Nocturno'),
('c0000000-0000-4000-8000-000000000002', '3354', '2012-01-23 10:30:00-06', 'I11050180', 'DELGADILLO GELACIO IRMA BERENICE',     'INGENIERIA INFORMATICA', 1, 'Nocturno', 'DEPOSITO_BANCARIO', 'REF-2012-002', 1700.00, 100.00, 1600.00, 1, 'REGISTERED', 'FINAL', 'cajero2', 'Cajero Turno Nocturno'),
('c0000000-0000-4000-8000-000000000004', '2922', '2012-01-23 11:30:00-06', 'E11050286', 'MARTINEZ ALFARO LUIS ANGEL',           'INGENIERIA ELECTRONICA', 1, 'Matutino', 'DEPOSITO_BANCARIO', 'REF-2012-004', 1700.00, 100.00, 1600.00, 0, 'CANCELLED',  'FINAL', 'cajero1', 'Cajero Turno Matutino')
ON CONFLICT (id) DO NOTHING;

INSERT INTO receipt_items (id, receipt_id, concept_id, description, quantity, unit_price, scholarship_discount, total_amount, academic_term)
VALUES
('d0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', (SELECT id FROM payment_concepts WHERE code = '5200-001-002-004'), 'INSCRIPCION SEM. AGO 2012-ENERO 2013', 1, 1700.00, 0.00, 1700.00, '2012-1'),
('d0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002', (SELECT id FROM payment_concepts WHERE code = '5200-001-002-004'), 'INSCRIPCION SEM. AGO 2012-ENERO 2013', 1, 1700.00, 100.00, 1600.00, '2012-1'),
('d0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000004', (SELECT id FROM payment_concepts WHERE code = '5200-001-002-004'), 'INSCRIPCION SEM. AGO 2012-ENERO 2013', 1, 1700.00, 100.00, 1600.00, '2012-1')
ON CONFLICT (id) DO NOTHING;

INSERT INTO payment_transactions (receipt_id, payment_method, reference_number, amount, transaction_date, cashier_username)
VALUES
('c0000000-0000-4000-8000-000000000001', 'DEPOSITO_BANCARIO', 'REF-2012-001', 1700.00, '2012-01-23 10:00:00-06', 'cajero2'),
('c0000000-0000-4000-8000-000000000002', 'DEPOSITO_BANCARIO', 'REF-2012-002', 1600.00, '2012-01-23 10:30:00-06', 'cajero2'),
('c0000000-0000-4000-8000-000000000004', 'DEPOSITO_BANCARIO', 'REF-2012-004', 1600.00, '2012-01-23 11:30:00-06', 'cajero1')
ON CONFLICT DO NOTHING;

COMMIT;
