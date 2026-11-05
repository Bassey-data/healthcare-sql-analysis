-- 00_load_data.sql
-- Loads the 7 CSV files from the csv/ folder into the tables created by schema.sql.
--
-- BEFORE RUNNING
-- 1. Run schema.sql first (it creates the tables).
-- 2. Replace /PATH/TO/csv/ below with the full path to the csv folder in this repository.
-- 3. LOAD DATA LOCAL INFILE must be allowed on both server and client
--    (MySQL Workbench: Edit Connection > Advanced > add  OPT_LOCAL_INFILE=1  under "Others",
--     and on the server run:  SET GLOBAL local_infile = 1;).
--    If it is blocked (error 2068), use the Table Data Import Wizard instead: right-click each
--    table > Table Data Import Wizard > choose the matching CSV.
--
-- NOTES
-- * The CSV files use Windows line endings, hence LINES TERMINATED BY '\r\n'.
-- * Empty cells in date and number columns are loaded as NULL.
-- * Foreign key checks are switched off during loading because a few rows deliberately reference
--   patients or doctors that do not exist (see 02_data_cleaning.sql).

USE healthcare_portfolio;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE '/PATH/TO/csv/departments.csv'
INTO TABLE departments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/PATH/TO/csv/doctors.csv'
INTO TABLE doctors
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(doctor_id, first_name, last_name, @department_id, specialisation, @hire_date, @email)
SET department_id = NULLIF(@department_id, ''),
    hire_date     = NULLIF(@hire_date, ''),
    email         = NULLIF(@email, '');

LOAD DATA LOCAL INFILE '/PATH/TO/csv/patients.csv'
INTO TABLE patients
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(patient_id, first_name, last_name, @date_of_birth, @gender, city, @phone, @email, @insurance_provider, @registration_date)
SET date_of_birth      = NULLIF(@date_of_birth, ''),
    gender             = NULLIF(@gender, ''),
    phone              = NULLIF(@phone, ''),
    email              = NULLIF(@email, ''),
    insurance_provider = NULLIF(@insurance_provider, ''),
    registration_date  = NULLIF(@registration_date, '');

LOAD DATA LOCAL INFILE '/PATH/TO/csv/appointments.csv'
INTO TABLE appointments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(appointment_id, @patient_id, @doctor_id, @appointment_date, @appointment_time, status, reason)
SET patient_id       = NULLIF(@patient_id, ''),
    doctor_id        = NULLIF(@doctor_id, ''),
    appointment_date = NULLIF(@appointment_date, ''),
    appointment_time = NULLIF(@appointment_time, '');

LOAD DATA LOCAL INFILE '/PATH/TO/csv/diagnoses.csv'
INTO TABLE diagnoses
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- billing.amount contains the '£' symbol, so the file must be read as UTF-8
LOAD DATA LOCAL INFILE '/PATH/TO/csv/billing.csv'
INTO TABLE billing
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(bill_id, @appointment_id, @amount, payment_status, @insurance_covered, @bill_date)
SET appointment_id    = NULLIF(@appointment_id, ''),
    amount            = NULLIF(@amount, ''),
    insurance_covered = NULLIF(@insurance_covered, ''),
    bill_date         = NULLIF(@bill_date, '');

LOAD DATA LOCAL INFILE '/PATH/TO/csv/prescriptions.csv'
INTO TABLE prescriptions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(prescription_id, @appointment_id, medication_name, dosage, @duration_days)
SET appointment_id = NULLIF(@appointment_id, ''),
    duration_days  = NULLIF(@duration_days, '');

SET FOREIGN_KEY_CHECKS = 1;

-- Check: expected row counts are 10, 70, 2652, 9000, 4689, 7857, 4449
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'doctors',       COUNT(*) FROM doctors
UNION ALL SELECT 'patients',      COUNT(*) FROM patients
UNION ALL SELECT 'appointments',  COUNT(*) FROM appointments
UNION ALL SELECT 'diagnoses',     COUNT(*) FROM diagnoses
UNION ALL SELECT 'billing',       COUNT(*) FROM billing
UNION ALL SELECT 'prescriptions', COUNT(*) FROM prescriptions;
