-- ============================================================================
-- Healthcare Portfolio Database — Schema
-- ============================================================================
-- 7 tables: departments, doctors, patients, appointments, diagnoses,
-- billing, prescriptions.
--
-- IMPORTANT: This dataset is intentionally messy. Foreign keys are declared
-- below for documentation of the intended relationships, but the raw CSVs
-- contain a small number of rows that VIOLATE them on purpose (e.g. a few
-- appointments reference a patient_id or doctor_id that doesn't exist).
-- This is a deliberate data-quality issue for you to discover during
-- Stage 2/3 of the project — don't "fix" the generator, find it in the data.
--
-- If you load this into MySQL/Postgres with FK constraints ON, the load
-- will fail on those rows until you've identified and handled them. If you
-- want to load everything first and clean afterwards (recommended), disable
-- FK checks during import, or use the pre-built healthcare.db (SQLite, FKs
-- declared but not enforced) provided alongside this file.
-- ============================================================================

CREATE TABLE departments (
    department_id    INTEGER PRIMARY KEY,
    department_name  VARCHAR(50),
    location          VARCHAR(50)
);

CREATE TABLE doctors (
    doctor_id       INTEGER PRIMARY KEY,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    department_id   INTEGER,             -- some NULLs: doctor not yet assigned
    specialisation  VARCHAR(50),
    hire_date       DATE,
    email           VARCHAR(100),        -- some NULLs, inconsistent casing
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE patients (
    patient_id          INTEGER PRIMARY KEY,
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    date_of_birth       DATE,             -- some NULLs, a few impossible future dates
    gender              VARCHAR(20),      -- inconsistent categories: M/F/Male/Female/m/f/NULL/''
    city                VARCHAR(50),      -- inconsistent casing/spacing
    phone               VARCHAR(30),      -- inconsistent formats, some NULL
    email               VARCHAR(100),     -- some NULL
    insurance_provider  VARCHAR(50),      -- inconsistent categories, some NULL/''
    registration_date   DATE
    -- NOTE: ~2% of patients are near-duplicates (same person, new patient_id)
    -- with a later registration_date — a realistic double-registration issue.
);

CREATE TABLE appointments (
    appointment_id    INTEGER PRIMARY KEY,
    patient_id        INTEGER,           -- a handful reference a non-existent patient
    doctor_id         INTEGER,           -- a handful reference a non-existent doctor
    appointment_date  DATE,              -- some NULL, a few nonsensical (year 2030) entries
    appointment_time  TIME,
    status            VARCHAR(20),       -- inconsistent categories: Completed/completed/COMPLETED/
                                          -- Cancelled/cancelled/No-show/no show/No Show/Scheduled/scheduled
    reason             VARCHAR(50),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE diagnoses (
    diagnosis_id           INTEGER PRIMARY KEY,
    appointment_id         INTEGER,
    diagnosis_code         VARCHAR(10),   -- a handful malformed (case/format inconsistency)
    diagnosis_description  VARCHAR(100),  -- some inconsistent casing/trailing whitespace
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

CREATE TABLE billing (
    bill_id            INTEGER PRIMARY KEY,
    appointment_id     INTEGER,
    amount             VARCHAR(20),      -- MOSTLY numeric, but some stored as text with a
                                          -- currency symbol (e.g. "£234.50") — type inconsistency
                                          -- on purpose; a few are erroneous negative values
    payment_status     VARCHAR(20),      -- inconsistent categories: Paid/paid/PAID/Unpaid/
                                          -- unpaid/Pending/pending/Refunded
    insurance_covered  VARCHAR(10),      -- True/False/NULL (stored as text)
    bill_date          DATE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

CREATE TABLE prescriptions (
    prescription_id  INTEGER PRIMARY KEY,
    appointment_id   INTEGER,
    medication_name  VARCHAR(50),        -- occasional inconsistent casing
    dosage           VARCHAR(20),
    duration_days    INTEGER,            -- some NULL
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

-- ============================================================================
-- RELATIONSHIPS (cardinality)
-- ============================================================================
-- departments  1 --- * doctors           (a department has many doctors)
-- doctors      1 --- * appointments      (a doctor has many appointments)
-- patients     1 --- * appointments      (a patient has many appointments)
-- appointments 1 --- 0..1 diagnoses      (an appointment has at most one diagnosis
--                                         in this dataset, but not every
--                                         appointment resulted in a diagnosis)
-- appointments 1 --- 0..1 billing        (most, but not all, appointments were billed)
-- appointments 1 --- 0..2 prescriptions  (an appointment may have 0, 1, or 2
--                                         medications prescribed)
-- ============================================================================
