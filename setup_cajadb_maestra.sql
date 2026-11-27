-- ============================================================================
-- SCRIPT DEFINITIVO DE BASE DE DATOS: CAJADB UNIVERSITARIA
-- TecNM Campus Monclova
-- ============================================================================
-- Arquitectura de Base de Datos:
-- 1. Esquema Canónico Físico en INGLÉS (15 tablas con llaves primarias, foráneas, checks e índices).
-- 2. Datos institucionales en ESPAÑOL (Catálogo de 8 Carreras Oficiales, Conceptos de Cobro, Usuarios y Periodos).
-- 3. Reglas de negocio automatizadas: Trigger de reversión de adeudos al cancelar recibos.
-- 4. 6 Vistas analíticas administrativas en INGLÉS para auditoría contable.
-- 5. 14 Vistas de compatibilidad en ESPAÑOL (1:1 actualizables) para garantizar 
-- ============================================================================

ROLLBACK;

-- ----------------------------------------------------------------------------
-- 1. LIMPIEZA EN CASCADA DE OBJETOS PREVIOS
-- ----------------------------------------------------------------------------
-- Vistas en Español
DROP VIEW IF EXISTS migracion_incidencias CASCADE;
DROP VIEW IF EXISTS movimientos_pago CASCADE;
DROP VIEW IF EXISTS detalles_recibo CASCADE;
DROP VIEW IF EXISTS detalle_recibo CASCADE;
DROP VIEW IF EXISTS recibos CASCADE;
DROP VIEW IF EXISTS polizas_ingreso CASCADE;
DROP VIEW IF EXISTS folios CASCADE;
DROP VIEW IF EXISTS sesiones_caja CASCADE;
DROP VIEW IF EXISTS conceptos_cobro CASCADE;
DROP VIEW IF EXISTS adeudos CASCADE;
DROP VIEW IF EXISTS becas_descuentos CASCADE;
DROP VIEW IF EXISTS alumno_matriculas_historial CASCADE;
DROP VIEW IF EXISTS alumnos CASCADE;
DROP VIEW IF EXISTS periodos_academicos CASCADE;
DROP VIEW IF EXISTS carreras CASCADE;

-- Vistas en Inglés
DROP VIEW IF EXISTS vw_student_financial_kardex CASCADE;
DROP VIEW IF EXISTS vw_revenue_policies_summary CASCADE;
DROP VIEW IF EXISTS vw_bank_deposits_reconciliation CASCADE;
DROP VIEW IF EXISTS vw_student_debts CASCADE;
DROP VIEW IF EXISTS vw_receipt_details_report CASCADE;
DROP VIEW IF EXISTS vw_daily_cash_cut CASCADE;

-- Funciones y Triggers
DROP FUNCTION IF EXISTS fn_reverse_debt_on_cancellation CASCADE;
DROP FUNCTION IF EXISTS fn_revertir_adeudo_por_cancelacion CASCADE;

-- Tablas en Inglés
DROP TABLE IF EXISTS migration_issues CASCADE;
DROP TABLE IF EXISTS payment_transactions CASCADE;
DROP TABLE IF EXISTS receipt_items CASCADE;
DROP TABLE IF EXISTS receipts CASCADE;
DROP TABLE IF EXISTS revenue_policies CASCADE;
DROP TABLE IF EXISTS receipt_folios CASCADE;
DROP TABLE IF EXISTS cashier_sessions CASCADE;
DROP TABLE IF EXISTS payment_concepts CASCADE;
DROP TABLE IF EXISTS student_debts CASCADE;
DROP TABLE IF EXISTS scholarships CASCADE;
DROP TABLE IF EXISTS student_enrollment_history CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS academic_terms CASCADE;
DROP TABLE IF EXISTS careers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP SEQUENCE IF EXISTS receipt_number_seq CASCADE;
DROP SEQUENCE IF EXISTS recibos_numero_recibo_seq CASCADE;

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 2. TABLAS CANÓNICAS EN INGLÉS (DDL)
-- ----------------------------------------------------------------------------

-- 1. Careers (Official Degree Programs)
CREATE TABLE careers (
    career_id       INT PRIMARY KEY,
    career_name     VARCHAR(50) NOT NULL,        -- Official abbreviation
    full_name       VARCHAR(150) NOT NULL,       -- Institutional full denomination
    degree_title    VARCHAR(150),                -- Academic title granted
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Academic Terms
CREATE TABLE academic_terms (
    term_id      SERIAL PRIMARY KEY,
    code         VARCHAR(30) UNIQUE NOT NULL,
    description  VARCHAR(150),
    year         SMALLINT NOT NULL,
    cycle        VARCHAR(20) NOT NULL CHECK (cycle IN ('PRIMAVERA', 'OTONO', 'VERANO', 'VERANILLO')),
    start_date   DATE,
    end_date     DATE,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Users (System Staff & Roles)
CREATE TABLE users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username       VARCHAR(64) UNIQUE NOT NULL,
    email          VARCHAR(254) UNIQUE NOT NULL,
    password       VARCHAR(512) NOT NULL,
    name           VARCHAR(160) NOT NULL,
    role           VARCHAR(20) NOT NULL DEFAULT 'Cajero' CHECK (role IN ('Admin', 'User', 'Cajero', 'Auditor')),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Students (Master Student Registry)
CREATE TABLE students (
    student_id              VARCHAR(20) PRIMARY KEY,
    full_name               VARCHAR(160) NOT NULL,
    first_name              VARCHAR(100),
    last_name               VARCHAR(100),
    gender                  CHAR(1) CHECK (gender IN ('M', 'F') OR gender IS NULL),
    career_id               INT REFERENCES careers(career_id) ON DELETE SET NULL,
    career_name             VARCHAR(150) NOT NULL DEFAULT 'Sin Asignar',
    semester                INTEGER NOT NULL DEFAULT 1 CHECK (semester >= 1 AND semester <= 35),
    shift                   VARCHAR(20) NOT NULL DEFAULT 'Matutino' CHECK (shift IN ('Matutino', 'Nocturno', 'Vespertino', 'Sabatino')),
    admission_ticket_number VARCHAR(30),
    internal_account_number INT,
    academic_status         VARCHAR(30) NOT NULL DEFAULT 'Inscrito' CHECK (academic_status IN ('Inscrito', 'No Inscrito', 'Baja Temporal', 'Baja Definitiva', 'Egresado')),
    has_scholarship         BOOLEAN NOT NULL DEFAULT FALSE,
    scholarship_percentage  NUMERIC(5, 2) NOT NULL DEFAULT 0.00 CHECK (scholarship_percentage >= 0 AND scholarship_percentage <= 100),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_students_name ON students(full_name);
CREATE INDEX idx_students_career ON students(career_id);
CREATE INDEX idx_students_status ON students(academic_status);
CREATE INDEX idx_students_account ON students(internal_account_number);

-- 5. Student Enrollment History
CREATE TABLE student_enrollment_history (
    history_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id           VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    previous_student_id  VARCHAR(30) NOT NULL,
    term_id              INT REFERENCES academic_terms(term_id) ON DELETE RESTRICT,
    registered_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_reason        TEXT
);

CREATE INDEX idx_hist_student_id ON student_enrollment_history(student_id);
CREATE INDEX idx_hist_prev_id ON student_enrollment_history(previous_student_id);

-- 6. Scholarships & Discounts
CREATE TABLE scholarships (
    scholarship_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id       VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    term_id          INT NOT NULL REFERENCES academic_terms(term_id) ON DELETE RESTRICT,
    scholarship_type VARCHAR(50) NOT NULL DEFAULT 'ACADEMICA',
    percentage       NUMERIC(5, 2) DEFAULT 0.00 CHECK (percentage BETWEEN 0 AND 100),
    fixed_amount     NUMERIC(12, 4) DEFAULT 0.00 CHECK (fixed_amount >= 0),
    reason           VARCHAR(250),
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scholarships_student ON scholarships(student_id);

-- 7. Student Debts
CREATE TABLE student_debts (
    debt_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id       VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    concept_name     VARCHAR(100) NOT NULL,
    term_id          INT NOT NULL REFERENCES academic_terms(term_id) ON DELETE RESTRICT,
    original_amount  NUMERIC(12, 4) NOT NULL CHECK (original_amount >= 0),
    pending_balance  NUMERIC(12, 4) NOT NULL CHECK (pending_balance >= 0),
    due_date         DATE,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PARTIAL', 'SETTLED', 'CONDONED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_debts_student ON student_debts(student_id);
CREATE INDEX idx_debts_term ON student_debts(term_id);
CREATE INDEX idx_debts_status ON student_debts(status);

-- 8. Payment Concepts
CREATE TABLE payment_concepts (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                 VARCHAR(30) UNIQUE NOT NULL,
    description          VARCHAR(200) NOT NULL,
    base_fee             NUMERIC(12, 4) NOT NULL CHECK (base_fee >= 0),
    display_order        INT DEFAULT 0,
    ledger_account_code  VARCHAR(30),
    allows_scholarship   BOOLEAN NOT NULL DEFAULT FALSE,
    category             VARCHAR(50) NOT NULL DEFAULT 'Inscripción',
    is_active            BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_concepts_code ON payment_concepts(code);
CREATE INDEX idx_concepts_category ON payment_concepts(category);
CREATE INDEX idx_concepts_active ON payment_concepts(is_active);

-- 9. Cashier Sessions (Single-Window Operational Model)
CREATE TABLE cashier_sessions (
    session_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cashier_username VARCHAR(64) NOT NULL REFERENCES users(username) ON DELETE RESTRICT,
    cashier_name     VARCHAR(160) NOT NULL,
    opened_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    initial_cash     NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    closed_at        TIMESTAMPTZ,
    system_total     NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    counted_total    NUMERIC(12, 4),
    difference       NUMERIC(12, 4) DEFAULT 0.00,
    status           VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED', 'AUDITED')),
    notes            TEXT
);

CREATE INDEX idx_sessions_cashier ON cashier_sessions(cashier_username);
CREATE INDEX idx_sessions_status ON cashier_sessions(status);

-- 10. Receipt Folios
CREATE TABLE receipt_folios (
    folio_number    BIGINT PRIMARY KEY,
    series          VARCHAR(10) NOT NULL DEFAULT 'A',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes           TEXT
);

-- 11. Revenue Policies
CREATE TABLE revenue_policies (
    policy_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    policy_number    VARCHAR(50) UNIQUE NOT NULL,
    policy_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    total_collected  NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    cashier_username VARCHAR(64) NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CONSOLIDATED', 'CANCELLED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_policies_date ON revenue_policies(policy_date);

-- 12. Receipts
CREATE SEQUENCE receipt_number_seq START WITH 128450;

CREATE TABLE receipts (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number          BIGINT NOT NULL DEFAULT nextval('receipt_number_seq') UNIQUE,
    folio_number            VARCHAR(50) NOT NULL,
    issued_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_payment_date  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    student_id              VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    student_name            VARCHAR(160) NOT NULL,
    student_career          VARCHAR(150) NOT NULL,
    student_semester        INTEGER NOT NULL,
    student_shift           VARCHAR(20) NOT NULL,
    payment_method          VARCHAR(30) NOT NULL,
    bank_reference          VARCHAR(50),
    bank_account            VARCHAR(50),
    bank_transaction_date   TIMESTAMPTZ,
    subtotal                NUMERIC(12, 4) NOT NULL,
    discount_total          NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    total                   NUMERIC(12, 4) NOT NULL,
    status_code             SMALLINT NOT NULL DEFAULT 1,
    status                  VARCHAR(20) NOT NULL DEFAULT 'REGISTRADO',
    receipt_type            VARCHAR(20) NOT NULL DEFAULT 'DEFINITIVO',
    is_locked               BOOLEAN NOT NULL DEFAULT FALSE,
    session_id              UUID REFERENCES cashier_sessions(session_id) ON DELETE SET NULL,
    policy_id               BIGINT REFERENCES revenue_policies(policy_id) ON DELETE SET NULL,
    cancellation_reason     VARCHAR(500),
    cancelled_at            TIMESTAMPTZ,
    cashier_username        VARCHAR(64) NOT NULL,
    cashier_name            VARCHAR(160) NOT NULL
);

CREATE INDEX idx_receipts_number ON receipts(receipt_number);
CREATE INDEX idx_receipts_folio ON receipts(folio_number);
CREATE INDEX idx_receipts_student ON receipts(student_id);
CREATE INDEX idx_receipts_reference ON receipts(bank_reference);
CREATE INDEX idx_receipts_date ON receipts(issued_at);
CREATE INDEX idx_receipts_status ON receipts(status);

-- 13. Receipt Items
CREATE TABLE receipt_items (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_id            UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
    concept_id            UUID REFERENCES payment_concepts(id) ON DELETE SET NULL,
    description           VARCHAR(200) NOT NULL,
    quantity              INTEGER NOT NULL CHECK (quantity > 0),
    unit_price            NUMERIC(12, 4) NOT NULL,
    scholarship_discount  NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    total_amount          NUMERIC(12, 4) NOT NULL,
    academic_term         VARCHAR(20)
);

CREATE INDEX idx_items_receipt ON receipt_items(receipt_id);
CREATE INDEX idx_items_concept ON receipt_items(concept_id);

-- 14. Payment Transactions
CREATE TABLE payment_transactions (
    transaction_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_id       UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
    payment_method   VARCHAR(30) NOT NULL,
    reference_number VARCHAR(100),
    amount           NUMERIC(12, 4) NOT NULL CHECK (amount > 0),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cashier_username VARCHAR(64) NOT NULL
);

CREATE INDEX idx_transactions_receipt ON payment_transactions(receipt_id);
CREATE INDEX idx_transactions_method ON payment_transactions(payment_method);

-- 15. Migration Issues
CREATE TABLE migration_issues (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_table      VARCHAR(50) NOT NULL,
    record_identifier VARCHAR(100),
    detected_issue    TEXT NOT NULL,
    logged_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_resolved       BOOLEAN NOT NULL DEFAULT FALSE,
    resolution_notes  TEXT
);

-- 16. Audit Log (Tópicos de Base de Datos - Bitácora de Transacciones Activa)
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

CREATE INDEX idx_audit_table_op ON audit_logs(table_name, operation);
CREATE INDEX idx_audit_record_id ON audit_logs(record_id);
CREATE INDEX idx_audit_performed_at ON audit_logs(performed_at DESC);

-- ----------------------------------------------------------------------------
-- 3. POBLACIÓN DE CATÁLOGOS BASE (DATOS INSTITUCIONALES EN ESPAÑOL)
-- ----------------------------------------------------------------------------

-- Las 8 Carreras Oficiales
INSERT INTO careers (career_id, career_name, full_name, degree_title, is_active) VALUES
(64, 'Lic. Informática',         'LICENCIATURA EN INFORMATICA',          'LICENCIADO EN INFORMATICA', true),
(65, 'Ing. Mecánica',            'INGENIERIA MECANICA',                  'INGENIERO MECANICO', true),
(67, 'Ing. Industrial',          'INGENIERIA INDUSTRIAL',                'INGENIERO INDUSTRIAL', true),
(68, 'Ing. Electrónica',         'INGENIERIA ELECTRONICA',               'INGENIERO ELECTRONICO', true),
(69, 'Ing. Informática',         'INGENIERIA INFORMATICA',               'INGENIERO INFORMATICO', true),
(70, 'Ing. Gestión Emp.',        'INGENIERIA EN GESTION EMPRESARIAL',    'INGENIERO EN GESTION EMPRESARIAL', true),
(71, 'Ing. Energías Renovables', 'INGENIERIA EN ENERGIAS RENOVABLES',    'INGENIERO EN ENERGIAS RENOVABLES', true),
(74, 'Ing. Mecatrónica',         'INGENIERIA MECATRONICA',               'INGENIERO MECATRONICO', true);

-- Periodos Académicos
INSERT INTO academic_terms (code, description, year, cycle, start_date, end_date, is_active) VALUES
('2012-1', 'SEMESTRE ENERO-JUNIO 2012',        2012, 'PRIMAVERA', '2012-01-09', '2012-06-30', false),
('2016-1', 'SEMESTRE ENERO-JUNIO 2016',        2016, 'PRIMAVERA', '2016-01-11', '2016-06-30', false),
('2016-2', 'SEMESTRE AGOSTO-ENERO 2016-2017',  2016, 'OTONO',     '2016-08-08', '2017-01-31', false),
('2024-2', 'SEMESTRE AGOSTO-DICIEMBRE 2024',   2024, 'OTONO',     '2024-08-12', '2024-12-20', false),
('2025-1', 'SEMESTRE ENERO-JUNIO 2025',        2025, 'PRIMAVERA', '2025-01-13', '2025-06-27', false),
('2025-2', 'SEMESTRE AGOSTO-DICIEMBRE 2025',   2025, 'OTONO',     '2025-08-11', '2025-12-19', false),
('2026-1', 'SEMESTRE ENERO-JUNIO 2026',        2026, 'PRIMAVERA', '2026-01-12', '2026-06-30', true);

-- Usuarios de Sistema
INSERT INTO users (id, username, email, password, name, role, is_active) VALUES
('10000000-0000-4000-8000-000000000001', 'admin',   'admin@tecnm.local',   'AQAAAAIAAYagAAAAEPjbneKeORd2reFIG62af0ufOMPtwf64j0jpBznNBo3Y8K/BUoUW+IhJOm0b5iqWOg==', 'Administrador General', 'Admin',  true),
('10000000-0000-4000-8000-000000000002', 'cajero1', 'cajero1@tecnm.local', 'AQAAAAIAAYagAAAAECBhXWISKf+YayCz0xB8E4vyjO6chAfRLTq+f2eA4ztdtdDqA99jr+VsfZXUoKbfdQ==', 'Cajero Turno Matutino', 'Cajero', true),
('10000000-0000-4000-8000-000000000003', 'cajero2', 'cajero2@tecnm.local', 'AQAAAAIAAYagAAAAECBhXWISKf+YayCz0xB8E4vyjO6chAfRLTq+f2eA4ztdtdDqA99jr+VsfZXUoKbfdQ==', 'Cajero Turno Nocturno', 'Cajero', true),
('10000000-0000-4000-8000-000000000004', 'usuario', 'usuario@tecnm.local', 'AQAAAAIAAYagAAAAECBhXWISKf+YayCz0xB8E4vyjO6chAfRLTq+f2eA4ztdtdDqA99jr+VsfZXUoKbfdQ==', 'Usuario Operativo Demo', 'User',  true);

-- 62 Conceptos Oficiales de Cobro
INSERT INTO payment_concepts (code, description, base_fee, display_order, ledger_account_code, allows_scholarship, category, is_active) VALUES
  ('5200-001-002-004', 'INSCRIPCION SEM. AGO 2012-ENERO 2013', 1700.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-001-002-021', 'REINSCRIPCION SEM. AGOSTO 2022-ENERO 2023', 500.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-001-002-051', 'REINSCRIPCION SEM. AGOSTO 2025-ENERO 2026', 500.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-001-002-082', 'REINSCRIPCION SEM FEB-JUL 2023', 500.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-001-002-115', 'INSCRIPCION FEB 2006', 1450.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-002-001-001', 'INSCRIPCIONES', 1350.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-002-001-009', 'INSCRIPCION AGO-05', 1400.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-002-004-011', 'REINSCRIPCION SEM. FEBRERO-JULIO 2024', 500.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-004-009-023', 'INSCRIPCION AGO-2006', 1450.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-004-009-028', 'Inscripción Feb-Jul-2007', 1500.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-004-009-029', 'RECARGOS POR INSCRIPCION', 200.00, NULL, '5200', false, 'Recargos', true),
  ('5200-004-009-058', 'INSCRIPCION AGO-ENERO 2007', 1525.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-005-001-001', 'INSCRIPCION AGO-DIC-04 NVO. ING.', 1650.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-005-001-003', 'INSCRIPCION NVO. INGRESO', 1700.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-005-001-004', 'INSCRIPCION FEBRERO-JULIO 2008', 1550.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-005-001-013', 'INSCRIPCION SEM-FEB-JULIO-2009', 1600.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-005-001-017', 'INSCRIPCION SEM-AGOSTO 08-ENERO 09', 1550.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-006-001-0040', 'INSCRIPCION SEM. FEB-JUL 2010', 1600.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-006-001-035', 'INSCRIPCION SEM. AGO 09-ENE 10', 1600.00, NULL, '5200', true, 'Inscripción', true),
  ('5200-006-001-036', 'REINSCRIPCION SEM. FEBRERO-JULIO 2026', 800.00, NULL, '5200', true, 'Inscripción', true),
  ('5400-001-002-0016', 'INSCRIPCION FEBRERO-JULIO 2011', 1600.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0028', 'INSCRIPCION AGOSTO 2011-ENERO 2012', 1600.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0037', 'INSCRIPCION SEM. FEB-JUL 2012', 1700.00, 20, '5400', true, 'Inscripción', true),
  ('5400-001-002-0063', 'REINSCRIPCION SEM. AGOSTO 2023-ENERO 2024', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0071', 'INSCRIPCION SEM. FEB/JUL 2013', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0079', 'INSCRIPCION SEM. AGO. 2013-ENE. 2014', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0097', 'REINSCRIPCION SEM. FEBRERO-JULIO 2025', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0098', 'INSCRIPCION SEM FEB-JUL 2014', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0123', 'INSCRIPCION SEM. AGOSTO 2014-ENERO 2015', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0125', 'INSCRIPCION SEM. FEBRERO-JULIO 2015', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0143', 'INSCRIPCION SEM. AGOSTO 2015-ENERO 2016', 1700.00, 1, '5400', true, 'Inscripción', true),
  ('5400-001-002-0147', 'INSCRIPCION SEM. FEBRERO-JULIO 2016', 1700.00, 2, '5400', true, 'Inscripción', true),
  ('5400-001-002-0156', 'INSCRIPCION POSGRADO', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0160', 'INSCRIPCION SEM. AGOSTO 2017-ENERO 2018', 1700.00, 4, '5400', true, 'Inscripción', true),
  ('5400-001-002-0163', 'INSCRIPCIÓN SEM. FEBRERO-JULIO 2018', 1700.00, 5, '5400', true, 'Inscripción', true),
  ('5400-001-002-0224', 'INSCRIPCION NVO. INGRESO SEM. AGO 2019-ENERO 2020', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-002-0225', 'REINSCRIPCION SEM. FEB-JUL 2020', 500.00, 10, '5400', true, 'Inscripción', true),
  ('5400-001-002-0231', 'REINSCRIPCION AGOSTO 2020 - ENERO 2021', 500.00, 11, '5400', true, 'Inscripción', true),
  ('5400-001-002-0236', 'REINSCRIPCION FEB-JUL 2021', 500.00, 12, '5400', true, 'Inscripción', true),
  ('5400-001-002-0242', 'REINSCRIPCION AGOSTO 2021-ENERO 2022', 500.00, 13, '5400', true, 'Inscripción', true),
  ('5400-001-002-0249', 'REINSCRIPCION SEM. FEB-JUL 2022', 500.00, 14, '5400', true, 'Inscripción', true),
  ('5400-001-002-0259', 'REINSCRIPCION SEM. AGOSTO-DICIEMBRE 2024', 500.00, 15, '5400', true, 'Inscripción', true),
  ('5400-001-003-0001', 'INSCRIPCION SEM. AGOSTO 2018-ENERO 2019', 1700.00, 6, '5400', true, 'Inscripción', true),
  ('5400-001-003-0008', 'INSCRIPCION SEM. FEBRERO-JULIO 2019', 1700.00, 7, '5400', true, 'Inscripción', true),
  ('5400-001-003-0011', 'INSCRIPCION AGO-DIC 2003', 1300.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0016', 'INSCRIPCION FEBRERO-JULIO 2004', 1300.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0022', 'INSCRIPCION ENERO-JUNIO 2017', 1700.00, 3, '5400', true, 'Inscripción', true),
  ('5400-001-003-0030', 'REINSCRIPCION SEM. FEBRERO-JULIO 2024', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0043', 'REINSCRIPCION SEM. FEB-JUL 2022', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0050', 'INSCRIPCIONES DE MAESTRIA', 2300.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0055', 'REINSCRIPCION SEM. AGOSTO 2024-ENERO 2025', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0063', 'REINSCRIPCION SEM. AGOSTO 2023-ENERO 2024', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0068', 'REINSCRIPCION SEM. FEBRERO-JULIO 2023', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-003-0081', 'INSCRIPCION NVO. ING. SEM. AGOSTO-DICIEMBRE 2024', 2000.00, 16, '5400', true, 'Inscripción', true),
  ('5400-001-003-0097', 'REINSCRIPCION SEM. FEBRERO-JULIO 2025', 500.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-005-0001', 'INSCRIPCION ENERO-JUNIO 2005', 1350.00, NULL, '5400', true, 'Inscripción', true),
  ('5400-001-005-0013', 'INSCRIPCION SEM. AGOSTO 2016-ENERO 2017', 1700.00, NULL, '5400', true, 'Inscripción', true),
  ('INSC-VIG', 'CUOTA DE INSCRIPCION VIGENTE', 1700.00, 1, '5400', true, 'Inscripción', true),
  ('KARD', 'EXPEDICION DE KARDEX OFICIAL', 100.00, 2, '5400', false, 'Constancias', true),
  ('CONST', 'CONSTANCIA DE ESTUDIOS CON CALIFICACIONES', 80.00, 3, '5400', false, 'Constancias', true),
  ('TITU', 'TRAMITE INTEGRAL DE TITULACION', 3500.00, 4, '5400', false, 'Titulación', true),
  ('VERA', 'CURSO DE VERANO POR MATERIA', 1200.00, 5, '5400', false, 'Cursos', true)
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. TRIGGER: REVERSIÓN AUTOMÁTICA DE ADEUDOS POR CANCELACIÓN
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reverse_debt_on_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('CANCELLED', 'CANCELADO') AND (OLD.status IS NULL OR OLD.status NOT IN ('CANCELLED', 'CANCELADO')) THEN
        UPDATE student_debts sd
        SET status = 'PENDING',
            pending_balance = sd.original_amount
        WHERE sd.student_id = NEW.student_id
          AND sd.status IN ('SETTLED', 'PARTIAL', 'LIQUIDADO')
          AND EXISTS (
              SELECT 1 
              FROM receipt_items ri
              WHERE ri.receipt_id = NEW.id
                AND (ri.description ILIKE '%' || sd.concept_name || '%' OR sd.concept_name ILIKE '%' || ri.description || '%')
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reverse_debt_cancellation ON receipts;
CREATE TRIGGER trg_reverse_debt_cancellation
AFTER UPDATE OF status ON receipts
FOR EACH ROW
EXECUTE FUNCTION fn_reverse_debt_on_cancellation();

-- ----------------------------------------------------------------------------
-- 4.1. FUNCIÓN Y TRIGGERS DE AUDITORÍA ACTIVA (TÓPICOS DE BASE DE DATOS)
-- Registra usuario, fecha/hora, operación (INSERT, UPDATE, DELETE) y detalle
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit_trail_logger()
RETURNS TRIGGER AS $$
DECLARE
    v_user VARCHAR(50);
    v_record_id VARCHAR(100);
    v_old JSONB := NULL;
    v_new JSONB := NULL;
    v_changed TEXT[] := ARRAY[]::TEXT[];
    v_key TEXT;
BEGIN
    -- Determinar el usuario que realizó la acción
    IF TG_OP = 'DELETE' THEN
        v_user := COALESCE(
            NULLIF(current_setting('app.current_user', true), ''),
            CASE WHEN TG_TABLE_NAME = 'receipts' THEN OLD.cashier_username ELSE CURRENT_USER END
        );
        v_record_id := CASE 
            WHEN TG_TABLE_NAME = 'receipts' THEN OLD.id::TEXT
            WHEN TG_TABLE_NAME = 'student_debts' THEN OLD.debt_id::TEXT
            WHEN TG_TABLE_NAME = 'payment_concepts' THEN OLD.id::TEXT
            WHEN TG_TABLE_NAME = 'payment_transactions' THEN OLD.transaction_id::TEXT
            ELSE NULL
        END;
        v_old := to_jsonb(OLD);
    ELSIF TG_OP = 'UPDATE' THEN
        v_user := COALESCE(
            NULLIF(current_setting('app.current_user', true), ''),
            CASE WHEN TG_TABLE_NAME = 'receipts' THEN COALESCE(NEW.cashier_username, OLD.cashier_username) ELSE CURRENT_USER END
        );
        v_record_id := CASE 
            WHEN TG_TABLE_NAME = 'receipts' THEN NEW.id::TEXT
            WHEN TG_TABLE_NAME = 'student_debts' THEN NEW.debt_id::TEXT
            WHEN TG_TABLE_NAME = 'payment_concepts' THEN NEW.id::TEXT
            WHEN TG_TABLE_NAME = 'payment_transactions' THEN NEW.transaction_id::TEXT
            ELSE NULL
        END;
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);

        -- Calcular campos modificados
        FOR v_key IN SELECT jsonb_object_keys(v_new)
        LOOP
            IF (v_old -> v_key) IS DISTINCT FROM (v_new -> v_key) THEN
                v_changed := array_append(v_changed, v_key);
            END IF;
        END LOOP;
    ELSIF TG_OP = 'INSERT' THEN
        v_user := COALESCE(
            NULLIF(current_setting('app.current_user', true), ''),
            CASE WHEN TG_TABLE_NAME = 'receipts' THEN NEW.cashier_username ELSE CURRENT_USER END
        );
        v_record_id := CASE 
            WHEN TG_TABLE_NAME = 'receipts' THEN NEW.id::TEXT
            WHEN TG_TABLE_NAME = 'student_debts' THEN NEW.debt_id::TEXT
            WHEN TG_TABLE_NAME = 'payment_concepts' THEN NEW.id::TEXT
            WHEN TG_TABLE_NAME = 'payment_transactions' THEN NEW.transaction_id::TEXT
            ELSE NULL
        END;
        v_new := to_jsonb(NEW);
    END IF;

    -- Insertar en la bitácora activa
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        performed_by,
        performed_at,
        client_ip,
        old_values,
        new_values,
        changed_fields
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        v_record_id,
        v_user,
        CURRENT_TIMESTAMP,
        inet_client_addr(),
        v_old,
        v_new,
        v_changed
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Triggers de auditoría para entidades críticas
DROP TRIGGER IF EXISTS trg_audit_receipts ON receipts;
CREATE TRIGGER trg_audit_receipts
AFTER INSERT OR UPDATE OR DELETE ON receipts
FOR EACH ROW
EXECUTE FUNCTION fn_audit_trail_logger();

DROP TRIGGER IF EXISTS trg_audit_student_debts ON student_debts;
CREATE TRIGGER trg_audit_student_debts
AFTER INSERT OR UPDATE OR DELETE ON student_debts
FOR EACH ROW
EXECUTE FUNCTION fn_audit_trail_logger();

DROP TRIGGER IF EXISTS trg_audit_payment_concepts ON payment_concepts;
CREATE TRIGGER trg_audit_payment_concepts
AFTER INSERT OR UPDATE OR DELETE ON payment_concepts
FOR EACH ROW
EXECUTE FUNCTION fn_audit_trail_logger();

DROP TRIGGER IF EXISTS trg_audit_payment_transactions ON payment_transactions;
CREATE TRIGGER trg_audit_payment_transactions
AFTER INSERT OR UPDATE OR DELETE ON payment_transactions
FOR EACH ROW
EXECUTE FUNCTION fn_audit_trail_logger();

-- ----------------------------------------------------------------------------
-- 5. VISTAS ANALÍTICAS EN INGLÉS (REPORTES FORMALES)
-- ----------------------------------------------------------------------------
CREATE VIEW vw_daily_cash_cut AS
SELECT 
    r.issued_at::DATE AS cut_date,
    r.cashier_username,
    r.cashier_name,
    pt.payment_method,
    COUNT(DISTINCT r.id) AS total_receipts_issued,
    COUNT(DISTINCT CASE WHEN r.status IN ('CANCELLED', 'CANCELADO') THEN r.id END) AS cancelled_receipts,
    SUM(CASE WHEN r.status NOT IN ('CANCELLED', 'CANCELADO') THEN pt.amount ELSE 0 END) AS total_collected
FROM receipts r
LEFT JOIN payment_transactions pt ON r.id = pt.receipt_id
GROUP BY r.issued_at::DATE, r.cashier_username, r.cashier_name, pt.payment_method;

CREATE VIEW vw_receipt_details_report AS
SELECT 
    r.id AS receipt_id,
    r.receipt_number,
    r.folio_number,
    r.issued_at,
    r.effective_payment_date,
    r.student_id,
    r.student_name,
    r.student_career,
    r.student_semester,
    r.student_shift,
    ri.description AS item_description,
    ri.quantity,
    ri.unit_price,
    ri.scholarship_discount,
    ri.total_amount AS item_total,
    r.total AS receipt_total,
    r.payment_method,
    r.bank_reference,
    r.receipt_type,
    r.status AS receipt_status,
    r.cancellation_reason,
    r.cancelled_at,
    r.cashier_username,
    r.cashier_name
FROM receipts r
JOIN receipt_items ri ON r.id = ri.receipt_id;

CREATE VIEW vw_student_debts AS
SELECT 
    sd.debt_id,
    sd.student_id,
    s.full_name AS student_name,
    s.career_name,
    s.semester,
    s.shift,
    s.academic_status,
    sd.concept_name,
    at.code AS term_code,
    at.year AS term_year,
    at.cycle AS term_cycle,
    sd.original_amount,
    sd.pending_balance,
    sd.due_date,
    sd.status AS debt_status
FROM student_debts sd
JOIN students s ON sd.student_id = s.student_id
JOIN academic_terms at ON sd.term_id = at.term_id;

CREATE VIEW vw_bank_deposits_reconciliation AS
SELECT
    r.id AS receipt_id,
    r.receipt_number,
    r.folio_number,
    r.issued_at,
    r.effective_payment_date,
    r.student_id,
    r.student_name,
    s.internal_account_number,
    r.bank_reference,
    SUBSTRING(r.bank_reference FROM 1 FOR 5) AS student_account_prefix,
    SUBSTRING(r.bank_reference FROM 6 FOR 5) AS concept_code_suffix,
    r.bank_account,
    r.total,
    r.status,
    r.cashier_username
FROM receipts r
LEFT JOIN students s ON r.student_id = s.student_id
WHERE r.payment_method IN ('DEPOSITO_BANCARIO', 'TRANSFERENCIA');

CREATE VIEW vw_revenue_policies_summary AS
SELECT
    rp.policy_id,
    rp.policy_number,
    rp.policy_date,
    rp.total_collected,
    rp.cashier_username,
    rp.status,
    COUNT(r.id) AS associated_receipts_count,
    rp.created_at
FROM revenue_policies rp
LEFT JOIN receipts r ON rp.policy_id = r.policy_id
GROUP BY rp.policy_id, rp.policy_number, rp.policy_date, rp.total_collected, rp.cashier_username, rp.status, rp.created_at;

CREATE VIEW vw_student_financial_kardex AS
SELECT
    r.student_id,
    r.student_name,
    r.student_career,
    r.receipt_number,
    r.folio_number,
    r.issued_at,
    ri.description AS concept_description,
    ri.quantity,
    ri.unit_price,
    ri.scholarship_discount,
    ri.total_amount,
    r.payment_method,
    r.status AS receipt_status,
    r.cashier_name
FROM receipts r
JOIN receipt_items ri ON r.id = ri.receipt_id;

-- ----------------------------------------------------------------------------
-- 6. VISTAS DE COMPATIBILIDAD EN ESPAÑOL (ACTUALIZABLES PARA BACKEND Y FRONTEND)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW carreras AS
SELECT 
    career_id       AS id_carrera,
    career_name     AS carrera,
    full_name       AS nombre_carrera,
    degree_title    AS titulo,
    is_active       AS activo
FROM careers;

CREATE OR REPLACE VIEW periodos_academicos AS
SELECT
    term_id      AS id_periodo,
    code         AS codigo,
    description  AS descripcion,
    year         AS anio,
    cycle        AS ciclo,
    start_date   AS fecha_inicio,
    end_date     AS fecha_fin,
    is_active    AS activo
FROM academic_terms;

CREATE OR REPLACE VIEW alumnos AS
SELECT
    student_id              AS matricula,
    full_name               AS nombre_completo,
    first_name              AS nombres,
    last_name               AS apellidos,
    gender                  AS sexo,
    career_id               AS id_carrera,
    career_name             AS carrera,
    semester                AS semestre,
    shift                   AS turno,
    admission_ticket_number AS numero_ficha,
    internal_account_number AS cuenta_a,
    academic_status         AS estatus,
    has_scholarship         AS tiene_beca,
    scholarship_percentage  AS porcentaje_beca,
    created_at
FROM students;

CREATE OR REPLACE VIEW alumno_matriculas_historial AS
SELECT
    history_id          AS id_historial,
    student_id          AS matricula_alumno,
    previous_student_id AS matricula_previa,
    term_id             AS id_periodo,
    registered_at       AS fecha_registro,
    change_reason       AS motivo_cambio
FROM student_enrollment_history;

CREATE OR REPLACE VIEW becas_descuentos AS
SELECT
    scholarship_id   AS id_beca,
    student_id       AS matricula,
    term_id          AS id_periodo,
    scholarship_type AS tipo_beca,
    percentage       AS porcentaje,
    fixed_amount     AS monto_fijo,
    reason           AS motivo,
    is_active        AS activa,
    created_at
FROM scholarships;

CREATE OR REPLACE VIEW adeudos AS
SELECT
    debt_id          AS id_adeudo,
    student_id       AS matricula,
    concept_name     AS concepto_cobro,
    term_id          AS id_periodo,
    original_amount  AS monto_original,
    pending_balance  AS saldo_pendiente,
    due_date         AS fecha_limite,
    status           AS estado,
    created_at
FROM student_debts;

CREATE OR REPLACE VIEW conceptos_cobro AS
SELECT
    id,
    code                AS clave,
    description         AS descripcion,
    base_fee            AS cuota_base,
    display_order       AS orden,
    ledger_account_code AS cuenta_referencia,
    allows_scholarship  AS aplica_beca,
    category            AS categoria,
    is_active
FROM payment_concepts;

CREATE OR REPLACE VIEW sesiones_caja AS
SELECT
    session_id       AS id_sesion,
    cashier_username AS usuario_cajero,
    cashier_name     AS nombre_cajero,
    opened_at        AS fecha_apertura,
    initial_cash     AS monto_inicial,
    closed_at        AS fecha_cierre,
    system_total     AS total_sistema,
    counted_total    AS total_arqueo,
    difference       AS diferencia,
    status           AS estado,
    notes            AS observaciones
FROM cashier_sessions;

CREATE OR REPLACE VIEW folios AS
SELECT
    folio_number AS numero_folio,
    series       AS serie,
    created_at   AS fecha_creacion,
    notes        AS observaciones
FROM receipt_folios;

CREATE OR REPLACE VIEW polizas_ingreso AS
SELECT
    policy_id        AS id_poliza,
    policy_number    AS numero_poliza,
    policy_date      AS fecha_poliza,
    total_collected  AS total_recaudado,
    cashier_username AS cajero_usuario,
    status           AS estado,
    created_at
FROM revenue_policies;

CREATE OR REPLACE VIEW recibos AS
SELECT
    id,
    receipt_number          AS numero_recibo,
    folio_number            AS folio_administrativo,
    issued_at               AS fecha_operacion,
    effective_payment_date  AS fecha_efectiva_pago,
    student_id              AS alumno_matricula,
    student_name            AS alumno_nombre,
    student_career          AS alumno_carrera,
    student_semester        AS alumno_semestre,
    student_shift           AS alumno_turno,
    payment_method          AS metodo_pago,
    bank_reference          AS referencia_bancaria,
    bank_account            AS cuenta_bancaria,
    bank_transaction_date   AS fecha_bancaria,
    subtotal,
    discount_total          AS descuento_total,
    total,
    status_code             AS status,
    status                  AS estado,
    receipt_type            AS tipo_recibo,
    is_locked,
    session_id              AS sesion_id,
    policy_id               AS poliza_id,
    cancellation_reason     AS motivo_cancelacion,
    cancelled_at            AS fecha_cancelacion,
    cashier_username        AS cajero_usuario,
    cashier_name            AS cajero_nombre
FROM receipts;

CREATE OR REPLACE VIEW detalles_recibo AS
SELECT
    id,
    receipt_id           AS recibo_id,
    concept_id           AS concepto_id,
    description          AS descripcion,
    quantity             AS cantidad,
    unit_price           AS cuota_unitario,
    scholarship_discount AS descuento_beca,
    total_amount         AS importe_total,
    academic_term        AS periodo_ano
FROM receipt_items;

CREATE OR REPLACE VIEW movimientos_pago AS
SELECT
    transaction_id   AS id_movimiento,
    receipt_id       AS recibo_id,
    payment_method   AS forma_pago,
    reference_number AS referencia_bancaria,
    amount           AS monto,
    transaction_date AS fecha_movimiento,
    cashier_username AS cajero_usuario
FROM payment_transactions;

CREATE OR REPLACE VIEW migracion_incidencias AS
SELECT
    id,
    source_table      AS tabla_origen,
    record_identifier AS identificador_registro,
    detected_issue    AS incidencia_detectada,
    logged_at         AS fecha_registro,
    is_resolved       AS resuelta,
    resolution_notes  AS notas_resolucion
FROM migration_issues;

CREATE OR REPLACE VIEW bitacora_auditoria AS
SELECT
    id,
    table_name        AS tabla_afectada,
    operation         AS operacion,
    record_id         AS id_registro,
    performed_by      AS realizado_por,
    performed_at      AS fecha_hora,
    client_ip         AS ip_cliente,
    old_values        AS valores_anteriores,
    new_values        AS valores_nuevos,
    changed_fields    AS campos_modificados
FROM audit_logs;

COMMIT;
