-- ============================================================================
-- STAGE 3: AUDIT, TRIGGERS & ANALYTICAL VIEWS - ENGLISH
-- University Cash Register Management System - TecNM Campus Monclova
-- ============================================================================
-- Features:
-- 1. Automatic debt reversal trigger on receipt cancellation (PostgreSQL engine).
-- 2. English analytical views for reporting.
-- 3. Transparent compatibility views for existing Backend (.NET 10) & Frontend (Vue 3).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. TRIGGER: AUTOMATIC DEBT REVERSAL ON RECEIPT CANCELLATION
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reverse_debt_on_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'CANCELLED' AND (OLD.status IS NULL OR OLD.status != 'CANCELLED') THEN
        UPDATE student_debts sd
        SET status = 'PENDING',
            pending_balance = sd.original_amount
        WHERE sd.student_id = NEW.student_id
          AND sd.status IN ('SETTLED', 'PARTIAL')
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
-- 2. ENGLISH ANALYTICAL VIEWS
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_daily_cash_cut CASCADE;
CREATE VIEW vw_daily_cash_cut AS
SELECT 
    r.issued_at::DATE AS cut_date,
    r.cashier_username,
    r.cashier_name,
    pt.payment_method,
    COUNT(DISTINCT r.id) AS total_receipts_issued,
    COUNT(DISTINCT CASE WHEN r.status = 'CANCELLED' THEN r.id END) AS cancelled_receipts,
    SUM(CASE WHEN r.status != 'CANCELLED' THEN pt.amount ELSE 0 END) AS total_collected
FROM receipts r
LEFT JOIN payment_transactions pt ON r.id = pt.receipt_id
GROUP BY r.issued_at::DATE, r.cashier_username, r.cashier_name, pt.payment_method;

DROP VIEW IF EXISTS vw_receipt_details_report CASCADE;
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

DROP VIEW IF EXISTS vw_student_debts CASCADE;
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

DROP VIEW IF EXISTS vw_bank_deposits_reconciliation CASCADE;
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

DROP VIEW IF EXISTS vw_revenue_policies_summary CASCADE;
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

-- ----------------------------------------------------------------------------
-- 3. SINCRONIZACIÓN DE COMPATIBILIDAD CON BACKEND
-- Actualizar la denominación formal en las vistas para garantizar que el frontend
-- y backend consuman el full_name profesional sin abreviaturas técnicas.
-- ----------------------------------------------------------------------------
UPDATE carreras SET carrera = nombre_carrera;

COMMIT;
