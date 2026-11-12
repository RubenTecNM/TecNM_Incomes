-- ============================================================================
-- ETAPA 1: ESTRUCTURA (DDL, LLAVES PRIMARIAS, FORÁNEAS E ÍNDICES)
-- Sistema de Control de Caja Universitaria - TecNM Campus Monclova
-- ============================================================================
-- Directriz: Preparar las tablas de la nueva base de datos, tipos de datos,
-- llaves primarias, llaves foráneas con ON DELETE RESTRICT en entidades contables,
-- soporte para ventanilla única y tabla de bitácora de incidencias.
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 1. CARRERAS (Catálogo Oficial de Oferta Académica)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS carreras (
    id_carrera      INT PRIMARY KEY,
    carrera         VARCHAR(50) NOT NULL,        -- Abreviatura oficial (ej. 'Ing. Industrial')
    nombre_carrera  VARCHAR(150) NOT NULL,       -- Denominación institucional completa
    titulo          VARCHAR(150),                -- Grado que otorga
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);

-- ----------------------------------------------------------------------------
-- 2. PERIODOS ACADÉMICOS (Ciclos para cobros, adeudos y vigencias)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS periodos_academicos (
    id_periodo   SERIAL PRIMARY KEY,
    codigo       VARCHAR(30) UNIQUE NOT NULL,    -- ej. '2012-1', '2025-2', '2026-1'
    descripcion  VARCHAR(150),
    anio         SMALLINT NOT NULL,
    ciclo        VARCHAR(20) NOT NULL CHECK (ciclo IN ('PRIMAVERA', 'OTONO', 'VERANO', 'VERANILLO')),
    fecha_inicio DATE,
    fecha_fin    DATE,
    activo       BOOLEAN NOT NULL DEFAULT TRUE
);

-- ----------------------------------------------------------------------------
-- 3. USUARIOS Y EMPLEADOS DEL SISTEMA
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username    VARCHAR(64) UNIQUE NOT NULL,
    email       VARCHAR(254) UNIQUE NOT NULL,
    password    VARCHAR(512) NOT NULL,
    name        VARCHAR(160) NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'Cajero' CHECK (role IN ('Admin', 'User', 'Cajero', 'Auditor')),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 4. ALUMNOS (Padrón Maestro)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alumnos (
    matricula       VARCHAR(20) PRIMARY KEY,
    nombre_completo VARCHAR(160) NOT NULL,
    nombre          VARCHAR(160) GENERATED ALWAYS AS (nombre_completo) STORED, -- Retrocompatibilidad con reportes legacy
    nombres         VARCHAR(100),
    apellidos       VARCHAR(100),
    sexo            CHAR(1) CHECK (sexo IN ('M', 'F') OR sexo IS NULL),
    id_carrera      INT REFERENCES carreras(id_carrera) ON DELETE RESTRICT,
    carrera         VARCHAR(100) NOT NULL,
    semestre        INTEGER NOT NULL CHECK (semestre >= 1 AND semestre <= 15),
    turno           VARCHAR(20) NOT NULL CHECK (turno IN ('Matutino', 'Nocturno', 'Vespertino', 'Sabatino')),
    numero_ficha    VARCHAR(30),
    cuenta_a        INT,
    estatus         VARCHAR(30) NOT NULL DEFAULT 'Inscrito' CHECK (estatus IN ('Inscrito', 'No Inscrito', 'Baja Temporal', 'Baja Definitiva', 'Egresado')),
    tiene_beca      BOOLEAN NOT NULL DEFAULT FALSE,
    porcentaje_beca NUMERIC(5, 2) NOT NULL DEFAULT 0.00 CHECK (porcentaje_beca >= 0 AND porcentaje_beca <= 100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_alumnos_nombre ON alumnos(nombre_completo);
CREATE INDEX IF NOT EXISTS idx_alumnos_carrera ON alumnos(id_carrera);
CREATE INDEX IF NOT EXISTS idx_alumnos_estatus ON alumnos(estatus);
CREATE INDEX IF NOT EXISTS idx_alumnos_cuenta_a ON alumnos(cuenta_a);

-- ----------------------------------------------------------------------------
-- 5. HISTORIAL DE CAMBIOS DE MATRÍCULA (Resolución de Duplicados)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alumno_matriculas_historial (
    id_historial      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricula_alumno  VARCHAR(20) NOT NULL REFERENCES alumnos(matricula) ON DELETE CASCADE,
    matricula_previa  VARCHAR(30) NOT NULL,
    id_periodo        INT REFERENCES periodos_academicos(id_periodo) ON DELETE RESTRICT,
    fecha_registro    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_cambio     TEXT
);

CREATE INDEX IF NOT EXISTS idx_hist_mat_actual ON alumno_matriculas_historial(matricula_alumno);
CREATE INDEX IF NOT EXISTS idx_hist_mat_previa ON alumno_matriculas_historial(matricula_previa);

-- ----------------------------------------------------------------------------
-- 6. BECAS Y DESCUENTOS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS becas_descuentos (
    id_beca             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricula           VARCHAR(20) NOT NULL REFERENCES alumnos(matricula) ON DELETE CASCADE,
    id_periodo          INT NOT NULL REFERENCES periodos_academicos(id_periodo) ON DELETE RESTRICT,
    tipo_beca           VARCHAR(50) NOT NULL DEFAULT 'ACADEMICA',
    porcentaje          NUMERIC(5, 2) DEFAULT 0.00 CHECK (porcentaje BETWEEN 0 AND 100),
    monto_fijo          NUMERIC(12, 4) DEFAULT 0.00 CHECK (monto_fijo >= 0),
    motivo              VARCHAR(250),
    activa              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_becas_matricula ON becas_descuentos(matricula);

-- ----------------------------------------------------------------------------
-- 7. ADEUDOS DE ALUMNOS (Multianuales)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS adeudos (
    id_adeudo           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricula           VARCHAR(20) NOT NULL REFERENCES alumnos(matricula) ON DELETE RESTRICT,
    concepto_cobro      VARCHAR(100) NOT NULL,
    id_periodo          INT NOT NULL REFERENCES periodos_academicos(id_periodo) ON DELETE RESTRICT,
    monto_original      NUMERIC(12, 4) NOT NULL CHECK (monto_original >= 0),
    saldo_pendiente     NUMERIC(12, 4) NOT NULL CHECK (saldo_pendiente >= 0),
    fecha_limite        DATE,
    estado              VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'LIQUIDADO', 'CONDONADO')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_adeudos_alumno ON adeudos(matricula);
CREATE INDEX IF NOT EXISTS idx_adeudos_periodo ON adeudos(id_periodo);
CREATE INDEX IF NOT EXISTS idx_adeudos_estado ON adeudos(estado);

-- ----------------------------------------------------------------------------
-- 8. CONCEPTOS DE COBRO (Catálogo Maestro Desacoplado de Periodo)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS conceptos_cobro (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave             VARCHAR(30) UNIQUE NOT NULL,
    descripcion       VARCHAR(200) NOT NULL,
    cuota_base        NUMERIC(12, 4) NOT NULL CHECK (cuota_base >= 0),
    orden             INT DEFAULT 0,
    cuenta_referencia VARCHAR(30),
    aplica_beca       BOOLEAN NOT NULL DEFAULT FALSE,
    categoria         VARCHAR(50) NOT NULL DEFAULT 'Inscripción',
    is_active         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_conceptos_clave ON conceptos_cobro(clave);
CREATE INDEX IF NOT EXISTS idx_conceptos_categoria ON conceptos_cobro(categoria);
CREATE INDEX IF NOT EXISTS idx_conceptos_active ON conceptos_cobro(is_active);

-- ----------------------------------------------------------------------------
-- 9. SESIONES DE CAJA (Aperturas y Cierres - Ventanilla Única)
-- Confirmación de usuario: Monto inicial en $0.00 por defecto.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sesiones_caja (
    id_sesion       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_cajero  VARCHAR(64) NOT NULL REFERENCES users(username) ON DELETE RESTRICT,
    nombre_cajero   VARCHAR(160) NOT NULL,
    fecha_apertura  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto_inicial   NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    fecha_cierre    TIMESTAMPTZ,
    total_sistema   NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    total_arqueo    NUMERIC(12, 4),
    diferencia      NUMERIC(12, 4) DEFAULT 0.00,
    estado          VARCHAR(20) NOT NULL DEFAULT 'ABIERTA' CHECK (estado IN ('ABIERTA', 'CERRADA', 'ARQUEADA')),
    observaciones   TEXT
);

CREATE INDEX IF NOT EXISTS idx_sesiones_cajero ON sesiones_caja(usuario_cajero);
CREATE INDEX IF NOT EXISTS idx_sesiones_estado ON sesiones_caja(estado);

-- ----------------------------------------------------------------------------
-- 10. FOLIOS ADMINISTRATIVOS (Serie Unificada)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS folios (
    numero_folio    BIGINT PRIMARY KEY,
    serie           VARCHAR(10) NOT NULL DEFAULT 'A',
    fecha_creacion  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones   TEXT
);

-- ----------------------------------------------------------------------------
-- 11. PÓLIZAS DE INGRESO
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS polizas_ingreso (
    id_poliza       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_poliza   VARCHAR(50) UNIQUE NOT NULL,
    fecha_poliza    DATE NOT NULL DEFAULT CURRENT_DATE,
    total_recaudado NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    cajero_usuario  VARCHAR(64) NOT NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'ABIERTA' CHECK (estado IN ('ABIERTA', 'CONSOLIDADA', 'CANCELADA')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_polizas_fecha ON polizas_ingreso(fecha_poliza);

-- ----------------------------------------------------------------------------
-- 12. RECIBOS DE CAJA (Comprobante Oficial)
-- ----------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS recibos_numero_recibo_seq START WITH 128450;

CREATE TABLE IF NOT EXISTS recibos (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_recibo        BIGINT NOT NULL DEFAULT nextval('recibos_numero_recibo_seq') UNIQUE,
    folio_administrativo VARCHAR(50) NOT NULL,
    fecha_operacion      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_efectiva_pago  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    alumno_matricula     VARCHAR(20) NOT NULL REFERENCES alumnos(matricula) ON DELETE RESTRICT,
    alumno_nombre        VARCHAR(160) NOT NULL,
    alumno_carrera       VARCHAR(100) NOT NULL,
    alumno_semestre      INTEGER NOT NULL,
    alumno_turno         VARCHAR(20) NOT NULL,
    metodo_pago          VARCHAR(30) NOT NULL CHECK (metodo_pago IN ('EFECTIVO', 'DEPOSITO_BANCARIO', 'TRANSFERENCIA', 'TARJETA_DEBITO', 'TARJETA_CREDITO')),
    referencia_bancaria  VARCHAR(50),
    cuenta_bancaria      VARCHAR(50),
    fecha_bancaria       TIMESTAMPTZ,
    subtotal             NUMERIC(12, 4) NOT NULL,
    descuento_total      NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    total                NUMERIC(12, 4) NOT NULL,
    status               SMALLINT NOT NULL DEFAULT 1 CHECK (status IN (0, 1)),
    estado               VARCHAR(20) NOT NULL DEFAULT 'REGISTRADO' CHECK (estado IN ('REGISTRADO', 'Vigente', 'PREVIO', 'CANCELADO', 'BLOQUEADO')),
    tipo_recibo          VARCHAR(20) NOT NULL DEFAULT 'DEFINITIVO' CHECK (tipo_recibo IN ('PREVIO', 'DEFINITIVO')),
    is_locked            BOOLEAN NOT NULL DEFAULT FALSE,
    sesion_id            UUID REFERENCES sesiones_caja(id_sesion) ON DELETE SET NULL,
    poliza_id            BIGINT REFERENCES polizas_ingreso(id_poliza) ON DELETE SET NULL,
    motivo_cancelacion   VARCHAR(500),
    fecha_cancelacion    TIMESTAMPTZ,
    cajero_usuario       VARCHAR(64) NOT NULL,
    cajero_nombre        VARCHAR(160) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_recibos_numero ON recibos(numero_recibo);
CREATE INDEX IF NOT EXISTS idx_recibos_folio ON recibos(folio_administrativo);
CREATE INDEX IF NOT EXISTS idx_recibos_matricula ON recibos(alumno_matricula);
CREATE INDEX IF NOT EXISTS idx_recibos_referencia ON recibos(referencia_bancaria);
CREATE INDEX IF NOT EXISTS idx_recibos_fecha ON recibos(fecha_operacion);
CREATE INDEX IF NOT EXISTS idx_recibos_estado ON recibos(estado);

-- ----------------------------------------------------------------------------
-- 13. DETALLES DE RECIBO (Partidas Facturadas)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS detalles_recibo (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recibo_id       UUID NOT NULL REFERENCES recibos(id) ON DELETE CASCADE,
    concepto_id     UUID REFERENCES conceptos_cobro(id) ON DELETE SET NULL,
    descripcion     VARCHAR(200) NOT NULL,
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    cuota_unitario  NUMERIC(12, 4) NOT NULL,
    descuento_beca  NUMERIC(12, 4) NOT NULL DEFAULT 0.00,
    importe_total   NUMERIC(12, 4) NOT NULL,
    periodo_ano     VARCHAR(20)
);

CREATE INDEX IF NOT EXISTS idx_detalles_recibo ON detalles_recibo(recibo_id);
CREATE INDEX IF NOT EXISTS idx_detalles_concepto ON detalles_recibo(concepto_id);

-- ----------------------------------------------------------------------------
-- 14. MOVIMIENTOS DE PAGO (Desglose Monetario)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_pago (
    id_movimiento       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recibo_id           UUID NOT NULL REFERENCES recibos(id) ON DELETE CASCADE,
    forma_pago          VARCHAR(30) NOT NULL CHECK (forma_pago IN ('EFECTIVO', 'DEPOSITO_BANCARIO', 'TRANSFERENCIA', 'TARJETA_DEBITO', 'TARJETA_CREDITO')),
    referencia_bancaria VARCHAR(100),
    monto               NUMERIC(12, 4) NOT NULL CHECK (monto > 0),
    fecha_movimiento    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cajero_usuario      VARCHAR(64) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_movimientos_recibo ON movimientos_pago(recibo_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_forma ON movimientos_pago(forma_pago);

-- ----------------------------------------------------------------------------
-- 15. BITÁCORA DE INCIDENCIAS DE MIGRACIÓN (Segunda Etapa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS migracion_incidencias (
    id                     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    origen_tabla           VARCHAR(50) NOT NULL,
    identificador_registro VARCHAR(100),
    error_detectado        TEXT NOT NULL,
    fecha_registro         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resuelto               BOOLEAN NOT NULL DEFAULT FALSE,
    notas_resolucion       TEXT
);

COMMIT;
