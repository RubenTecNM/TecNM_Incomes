-- ============================================================================
-- STAGE 1: STRUCTURE (DDL, PRIMARY KEYS, FOREIGN KEYS & INDEXES) - ENGLISH
-- University Cash Register Management System - TecNM Campus Monclova
-- ============================================================================
-- Design rules:
-- 1. Table and column names in standard English.
-- 2. 'careers' table has NO short_name; only 'full_name' for formal presentation.
-- 3. Strict foreign keys with ON DELETE RESTRICT on financial/academic records.
-- 4. Single-window operational model (cashier_sessions opening_balance = 0.00).
-- 5. Audit table 'migration_issues' for logging exceptions.
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 1. CAREERS (Official Degree Programs - Full Name Only)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS careers (
    career_id       INT PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,       -- Denominación institucional completa
    degree_title    VARCHAR(150),                -- Grado académico que otorga
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- ----------------------------------------------------------------------------
-- 2. ACADEMIC TERMS (Semesters for Billing, Debts & Validity)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS academic_terms (
    term_id      SERIAL PRIMARY KEY,
    code         VARCHAR(30) UNIQUE NOT NULL,    -- ej. '2012-1', '2025-2', '2026-1'
    description  VARCHAR(150),
    year         SMALLINT NOT NULL,
    cycle        VARCHAR(20) NOT NULL CHECK (cycle IN ('PRIMAVERA', 'OTONO', 'VERANO', 'VERANILLO')),
    start_date   DATE,
    end_date     DATE,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE
);

-- ----------------------------------------------------------------------------
-- 3. USERS & CASHIERS (System Authentication & Roles)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username       VARCHAR(64) UNIQUE NOT NULL,
    email          VARCHAR(254) UNIQUE NOT NULL,
    password       VARCHAR(512) NOT NULL,
    name           VARCHAR(160) NOT NULL,
    role           VARCHAR(20) NOT NULL DEFAULT 'Cajero' CHECK (role IN ('Admin', 'User', 'Cajero', 'Auditor')),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 4. STUDENTS (Master Student Registry)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    student_id              VARCHAR(20) PRIMARY KEY,     -- Matrícula institucional
    full_name               VARCHAR(160) NOT NULL,       -- Nombre completo
    first_name              VARCHAR(100),
    last_name               VARCHAR(100),
    gender                  CHAR(1) CHECK (gender IN ('M', 'F') OR gender IS NULL),
    career_id               INT REFERENCES careers(career_id) ON DELETE RESTRICT,
    career_name             VARCHAR(150) NOT NULL,       -- Denominación oficial completa
    semester                INTEGER NOT NULL CHECK (semester >= 1 AND semester <= 15),
    shift                   VARCHAR(20) NOT NULL CHECK (shift IN ('Matutino', 'Nocturno', 'Vespertino', 'Sabatino')),
    admission_ticket_number VARCHAR(30),
    internal_account_number INT,                         -- cuenta_a
    academic_status         VARCHAR(30) NOT NULL DEFAULT 'Inscrito' CHECK (academic_status IN ('Inscrito', 'No Inscrito', 'Baja Temporal', 'Baja Definitiva', 'Egresado')),
    has_scholarship         BOOLEAN NOT NULL DEFAULT FALSE,
    scholarship_percentage  NUMERIC(5, 2) NOT NULL DEFAULT 0.00 CHECK (scholarship_percentage >= 0 AND scholarship_percentage <= 100),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_students_name ON students(full_name);
CREATE INDEX IF NOT EXISTS idx_students_career ON students(career_id);
CREATE INDEX IF NOT EXISTS idx_students_status ON students(academic_status);
CREATE INDEX IF NOT EXISTS idx_students_account ON students(internal_account_number);

-- ----------------------------------------------------------------------------
-- 5. STUDENT ENROLLMENT HISTORY (Historical Student IDs / Matrículas)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_enrollment_history (
    history_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id           VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    previous_student_id  VARCHAR(30) NOT NULL,
    term_id              INT REFERENCES academic_terms(term_id) ON DELETE RESTRICT,
    registered_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_reason        TEXT
);

CREATE INDEX IF NOT EXISTS idx_hist_student_id ON student_enrollment_history(student_id);
CREATE INDEX IF NOT EXISTS idx_hist_prev_id ON student_enrollment_history(previous_student_id);

-- ----------------------------------------------------------------------------
-- 6. SCHOLARSHIPS & DISCOUNTS (Economic Benefits)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scholarships (
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

CREATE INDEX IF NOT EXISTS idx_scholarships_student ON scholarships(student_id);

-- ----------------------------------------------------------------------------
-- 7. STUDENT DEBTS (Institutional Pending Receivables)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_debts (
    debt_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id       VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    concept_name     VARCHAR(100) NOT NULL,
    term_id          INT NOT NULL REFERENCES academic_terms(term_id) ON DELETE RESTRICT,
    original_amount  NUMERIC(12, 4) NOT NULL CHECK (original_amount >= 0),
    pending_balance  NUMERIC(12, 4) NOT NULL CHECK (pending_balance >= 0),
    due_date         DATE,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PARTIAL', 'SETTLED', 'WAIVED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debts_student ON student_debts(student_id);
CREATE INDEX IF NOT EXISTS idx_debts_term ON student_debts(term_id);
CREATE INDEX IF NOT EXISTS idx_debts_status ON student_debts(status);

-- ----------------------------------------------------------------------------
-- 8. PAYMENT CONCEPTS (Tariff Catalog - Original Descriptions Intact)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_concepts (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                 VARCHAR(30) UNIQUE NOT NULL,
    description          VARCHAR(200) NOT NULL,       -- Mantenida exactamente igual en español
    base_fee             NUMERIC(12, 4) NOT NULL,
    display_order        INT DEFAULT 0,
    ledger_account_code  VARCHAR(30),
    allows_scholarship   BOOLEAN NOT NULL DEFAULT FALSE,
    category             VARCHAR(50) NOT NULL DEFAULT 'Inscripción',
    is_active            BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_concepts_code ON payment_concepts(code);
CREATE INDEX IF NOT EXISTS idx_concepts_category ON payment_concepts(category);

-- ----------------------------------------------------------------------------
-- 9. CASHIER SESSIONS (Single Window - Shift Openings & Closings)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cashier_sessions (
    session_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cashier_username VARCHAR(64) NOT NULL REFERENCES users(username) ON DELETE RESTRICT,
    cashier_name     VARCHAR(160) NOT NULL,
    opened_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    opening_balance  NUMERIC(12, 4) NOT NULL DEFAULT 0.00, -- Confirmado: $0.00 inicial
    closed_at        TIMESTAMPTZ,
    system_total     NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    counted_total    NUMERIC(12, 4),
    discrepancy      NUMERIC(12, 4) DEFAULT 0.00,
    status           VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED', 'AUDITED')),
    notes            TEXT
);

CREATE INDEX IF NOT EXISTS idx_sessions_cashier ON cashier_sessions(cashier_username);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON cashier_sessions(status);

-- ----------------------------------------------------------------------------
-- 10. RECEIPT FOLIOS (Single Unified Series 'A')
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS receipt_folios (
    folio_number    BIGINT PRIMARY KEY,
    series          VARCHAR(10) NOT NULL DEFAULT 'A',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes           TEXT
);

-- ----------------------------------------------------------------------------
-- 11. REVENUE POLICIES (Consolidated Accounting Policies)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS revenue_policies (
    policy_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    policy_number    VARCHAR(50) UNIQUE NOT NULL,
    policy_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    total_collected  NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    cashier_username VARCHAR(64) NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CONSOLIDATED', 'CANCELLED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_policies_date ON revenue_policies(policy_date);

-- ----------------------------------------------------------------------------
-- 12. RECEIPTS (Official Payment Receipts with Immutable Snapshot)
-- ----------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS receipt_number_seq START WITH 128450;

CREATE TABLE IF NOT EXISTS receipts (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number          BIGINT NOT NULL DEFAULT nextval('receipt_number_seq') UNIQUE,
    folio_number            VARCHAR(50) NOT NULL,
    issued_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_payment_date  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    student_id              VARCHAR(20) NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    student_name            VARCHAR(160) NOT NULL,
    student_career          VARCHAR(150) NOT NULL,       -- Denominación oficial completa
    student_semester        INTEGER NOT NULL,
    student_shift           VARCHAR(20) NOT NULL,
    payment_method          VARCHAR(30) NOT NULL CHECK (payment_method IN ('EFECTIVO', 'DEPOSITO_BANCARIO', 'TRANSFERENCIA', 'TARJETA_DEBITO', 'TARJETA_CREDITO')),
    bank_reference          VARCHAR(50),
    bank_account            VARCHAR(50),
    bank_transaction_date   TIMESTAMPTZ,
    subtotal                NUMERIC(12, 4) NOT NULL,
    discount_total          NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    total                   NUMERIC(12, 4) NOT NULL,
    status_code             SMALLINT NOT NULL DEFAULT 1 CHECK (status_code IN (0, 1)),
    status                  VARCHAR(20) NOT NULL DEFAULT 'REGISTERED' CHECK (status IN ('REGISTERED', 'PROVISIONAL', 'CANCELLED', 'LOCKED')),
    receipt_type            VARCHAR(20) NOT NULL DEFAULT 'FINAL' CHECK (receipt_type IN ('PROVISIONAL', 'FINAL')),
    is_locked               BOOLEAN NOT NULL DEFAULT FALSE,
    session_id              UUID REFERENCES cashier_sessions(session_id) ON DELETE SET NULL,
    policy_id               BIGINT REFERENCES revenue_policies(policy_id) ON DELETE SET NULL,
    cancellation_reason     VARCHAR(500),
    cancelled_at            TIMESTAMPTZ,
    cashier_username        VARCHAR(64) NOT NULL,
    cashier_name            VARCHAR(160) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_receipts_number ON receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_receipts_folio ON receipts(folio_number);
CREATE INDEX IF NOT EXISTS idx_receipts_student ON receipts(student_id);
CREATE INDEX IF NOT EXISTS idx_receipts_reference ON receipts(bank_reference);
CREATE INDEX IF NOT EXISTS idx_receipts_date ON receipts(issued_at);
CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);

-- ----------------------------------------------------------------------------
-- 13. RECEIPT ITEMS (Invoice Line Items)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS receipt_items (
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

CREATE INDEX IF NOT EXISTS idx_items_receipt ON receipt_items(receipt_id);
CREATE INDEX IF NOT EXISTS idx_items_concept ON receipt_items(concept_id);

-- ----------------------------------------------------------------------------
-- 14. PAYMENT TRANSACTIONS (Financial Incomes Breakdown)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_transactions (
    transaction_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_id       UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
    payment_method   VARCHAR(30) NOT NULL CHECK (payment_method IN ('EFECTIVO', 'DEPOSITO_BANCARIO', 'TRANSFERENCIA', 'TARJETA_DEBITO', 'TARJETA_CREDITO')),
    reference_number VARCHAR(100),
    amount           NUMERIC(12, 4) NOT NULL CHECK (amount > 0),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cashier_username VARCHAR(64) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_receipt ON payment_transactions(receipt_id);
CREATE INDEX IF NOT EXISTS idx_transactions_method ON payment_transactions(payment_method);

-- ----------------------------------------------------------------------------
-- 15. MIGRATION ISSUES (Audit Log of Migration Quality)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS migration_issues (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_table      VARCHAR(50) NOT NULL,
    record_identifier VARCHAR(100),
    detected_issue    TEXT NOT NULL,
    logged_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_resolved       BOOLEAN NOT NULL DEFAULT FALSE,
    resolution_notes  TEXT
);

COMMIT;
