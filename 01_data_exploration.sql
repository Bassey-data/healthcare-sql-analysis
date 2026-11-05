

USE healthcare_portfolio;


-- Row counts per table
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'doctors',       COUNT(*) FROM doctors
UNION ALL SELECT 'patients',      COUNT(*) FROM patients
UNION ALL SELECT 'appointments',  COUNT(*) FROM appointments
UNION ALL SELECT 'diagnoses',     COUNT(*) FROM diagnoses
UNION ALL SELECT 'billing',       COUNT(*) FROM billing
UNION ALL SELECT 'prescriptions', COUNT(*) FROM prescriptions;


-- 2. Date ranges to show what period the analysis covers
SELECT MIN(appointment_date) AS first_appt, MAX(appointment_date) AS last_appt FROM appointments;
SELECT MIN(bill_date) AS first_bill, MAX(bill_date) AS last_bill FROM billing;
SELECT MIN(registration_date) AS first_reg, MAX(registration_date) AS last_reg FROM patients;



-- Check Categorical columns
SELECT status, COUNT(*) AS n FROM appointments GROUP BY status ORDER BY n DESC;
SELECT payment_status, COUNT(*) AS n FROM billing GROUP BY payment_status ORDER BY n DESC;
SELECT gender, COUNT(*) AS n FROM patients GROUP BY gender ORDER BY n DESC;
SELECT insurance_provider, COUNT(*) AS n FROM patients GROUP BY insurance_provider ORDER BY n DESC;
-- default collation is case-insensitive, so 'Completed' and 'completed' already
-- 'No-show' vs 'No Show' and 'M' vs 'Male' do not.



-- Each appointment has at most one bill and one diagnosis, and 0-2 prescriptions.
SELECT COUNT(*) AS billing_rows, COUNT(DISTINCT appointment_id) AS distinct_appointments FROM billing;
SELECT COUNT(*) AS diagnosis_rows, COUNT(DISTINCT appointment_id) AS distinct_appointments FROM diagnoses;
SELECT COUNT(*) AS prescription_rows, COUNT(DISTINCT appointment_id) AS distinct_appointments FROM prescriptions;



-- Suspicious values (investigated further in 02_data_cleaning.sql)
SELECT MIN(date_of_birth) AS oldest_dob, MAX(date_of_birth) AS newest_dob FROM patients;
SELECT MIN(CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2))) AS min_amount,
       MAX(CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2))) AS max_amount
FROM billing;
