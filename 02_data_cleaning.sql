
USE healthcare_portfolio;


--  Patients: Check connt of all missing values
SELECT COUNT(*) AS total_patients,
       SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS missing_dob,
       SUM(CASE WHEN gender IS NULL OR gender = '' THEN 1 ELSE 0 END) AS missing_gender,
       SUM(CASE WHEN insurance_provider IS NULL OR insurance_provider = '' THEN 1 ELSE 0 END) AS missing_insurance,
       SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END) AS missing_city,
       SUM(CASE WHEN phone IS NULL OR phone = '' THEN 1 ELSE 0 END) AS missing_phone
FROM patients;


-- Patients: probable duplicate registrations (same name + date of birth, different patient_id)
SELECT SUM(registrations - 1) AS extra_duplicate_rows
FROM (
    SELECT first_name, last_name, date_of_birth, COUNT(*) AS registrations
    FROM patients
    GROUP BY first_name, last_name, date_of_birth
    HAVING COUNT(*) > 1
) AS duplicated_groups;



-- Billing: amount is text and some values carry a '£'
-- Using SUM() on the raw text silently reads those values as 0.
SELECT SUM(amount) AS wrong_total,
       SUM(CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2))) AS true_total
FROM billing;


-- Billing: negative amounts, split by payment status
SELECT TRIM(UPPER(payment_status)) AS status,
       COUNT(*) AS negative_bills,
       SUM(CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2))) AS total_amount
FROM billing
WHERE CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2)) < 0
GROUP BY TRIM(UPPER(payment_status))
ORDER BY negative_bills DESC;
-- Only a minority are 'Refunded', so "negative = refund" is NOT supported by the data.



--  Check Impossible dates
SELECT patient_id, date_of_birth FROM patients WHERE date_of_birth > CURDATE();
SELECT appointment_id, appointment_date FROM appointments WHERE appointment_date > CURDATE();
SELECT bill_id, bill_date, payment_status FROM billing WHERE bill_date > CURDATE();
-- Decision: future dates become NULL (unknown) in the cleaned views, not guessed.


-- Foreign keys: appointments pointing at patients / doctors that do not exist
SELECT a.appointment_id, a.patient_id
FROM appointments a
LEFT JOIN patients p ON a.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

SELECT a.appointment_id, a.doctor_id
FROM appointments a
LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE d.doctor_id IS NULL;


-- Billing rows with no matching appointment 
SELECT b.bill_id
FROM billing b
LEFT JOIN appointments a ON b.appointment_id = a.appointment_id
WHERE a.appointment_id IS NULL;


-- Diagnoses: malformed codes (lowercase, no decimal point)
SELECT diagnosis_code, COUNT(*) AS n
FROM diagnoses
GROUP BY diagnosis_code
ORDER BY diagnosis_code;



-- Using views 
-- Patients: standardised gender / insurance, cleaned DOB, age and age band
CREATE OR REPLACE VIEW v_patients_clean AS
SELECT patient_id,
       first_name,
       last_name,
       CASE
           WHEN TRIM(UPPER(gender)) IN ('M', 'MALE')   THEN 'Male'
           WHEN TRIM(UPPER(gender)) IN ('F', 'FEMALE') THEN 'Female'
           WHEN TRIM(UPPER(gender)) = 'NON-BINARY'     THEN 'Non-binary'
           ELSE 'Unknown'
       END AS gender_clean,
       CASE
           WHEN TRIM(UPPER(insurance_provider)) = 'BUPA'                       THEN 'BUPA'
           WHEN TRIM(UPPER(insurance_provider)) = 'AXA HEALTH'                 THEN 'AXA_HEALTH'
           WHEN TRIM(UPPER(insurance_provider)) = 'VITALITY'                   THEN 'VITALITY'
           WHEN TRIM(UPPER(insurance_provider)) = 'NHS'                        THEN 'NHS'
           WHEN TRIM(UPPER(insurance_provider)) IN ('SELF PAY', 'SELF-PAY')    THEN 'SELF_PAY'
           WHEN TRIM(UPPER(insurance_provider)) = 'NONE'                       THEN 'EMPTY'
           WHEN insurance_provider IS NULL OR TRIM(insurance_provider) = ''    THEN 'UNKNOWN'
           ELSE 'EMPTY'
       END AS insurance_provider_clean,
       dob_clean,
       TIMESTAMPDIFF(YEAR, dob_clean, '2026-09-16') AS age,
       CASE
           WHEN TIMESTAMPDIFF(YEAR, dob_clean, '2026-09-16') BETWEEN 0 AND 25  THEN '0-25'
           WHEN TIMESTAMPDIFF(YEAR, dob_clean, '2026-09-16') BETWEEN 26 AND 50 THEN '26-50'
           WHEN TIMESTAMPDIFF(YEAR, dob_clean, '2026-09-16') BETWEEN 51 AND 75 THEN '51-75'
           WHEN TIMESTAMPDIFF(YEAR, dob_clean, '2026-09-16') BETWEEN 76 AND 100 THEN '76-100'
           ELSE 'Unknown'
       END AS age_band
FROM (
    SELECT p.*,
           CASE WHEN date_of_birth <= '2026-09-16' THEN date_of_birth ELSE NULL END AS dob_clean
    FROM patients p
) AS p;


-- Appointments: standardised status, future dates set to NULL
CREATE OR REPLACE VIEW v_appointments_clean AS
SELECT appointment_id,
       patient_id,
       doctor_id,
       CASE WHEN appointment_date <= '2026-09-16' THEN appointment_date ELSE NULL END AS appointment_date_clean,
       CASE
           WHEN TRIM(UPPER(status)) IN ('NO-SHOW', 'NO SHOW') THEN 'MISSED'
           WHEN TRIM(UPPER(status)) = 'COMPLETED'             THEN 'COMPLETED'
           WHEN TRIM(UPPER(status)) = 'SCHEDULED'             THEN 'SCHEDULED'
           WHEN TRIM(UPPER(status)) = 'CANCELLED'             THEN 'CANCELLED'
       END AS status_clean,
       reason
FROM appointments;


--  Billing: numeric amount, standardised status / insurance flag, future dates set to NULL
CREATE OR REPLACE VIEW v_billing_clean AS
SELECT bill_id,
       appointment_id,
       CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2)) AS amount_clean,
       CAST(REPLACE(amount, '£', '') AS DECIMAL(10,2)) < 0 AS is_negative,
       CASE
           WHEN TRIM(UPPER(payment_status)) = 'PAID'     THEN 'Paid'
           WHEN TRIM(UPPER(payment_status)) = 'UNPAID'   THEN 'Unpaid'
           WHEN TRIM(UPPER(payment_status)) = 'PENDING'  THEN 'Pending'
           WHEN TRIM(UPPER(payment_status)) = 'REFUNDED' THEN 'Refunded'
       END AS payment_status_clean,
       CASE
           WHEN TRIM(UPPER(insurance_covered)) = 'TRUE'  THEN 'COVERED'
           WHEN TRIM(UPPER(insurance_covered)) = 'FALSE' THEN 'NOT_COVERED'
           ELSE 'UNKNOWN'
       END AS insurance_covered_clean,
       CASE WHEN bill_date <= '2026-09-16' THEN bill_date ELSE NULL END AS bill_date_clean
FROM billing;


-- Diagnoses: 8 malformed rows with 7  codes mapped to the correct form then description trimmed and upper-cased
CREATE OR REPLACE VIEW v_diagnoses_clean AS
SELECT diagnosis_id,
       appointment_id,
       CASE
           WHEN diagnosis_code = 'e785' THEN 'E78.5'
           WHEN diagnosis_code = 'f329' THEN 'F32.9'
           WHEN diagnosis_code = 'g439' THEN 'G43.9'
           WHEN diagnosis_code = 'l209' THEN 'L20.9'
           WHEN diagnosis_code = 'm179' THEN 'M17.9'
           WHEN diagnosis_code = 'm545' THEN 'M54.5'
           WHEN diagnosis_code = 'n390' THEN 'N39.0'
           ELSE diagnosis_code
       END AS diagnosis_code_clean,
       TRIM(UPPER(diagnosis_description)) AS diagnosis_clean
FROM diagnoses;


-- Prescriptions: medication names standardised
CREATE OR REPLACE VIEW v_prescriptions_clean AS
SELECT prescription_id,
       appointment_id,
       TRIM(UPPER(medication_name)) AS medication_clean,
       dosage,
       duration_days
FROM prescriptions;



-- Check that the views are right

SELECT gender_clean, COUNT(*) AS n FROM v_patients_clean GROUP BY gender_clean;                       
SELECT insurance_provider_clean, COUNT(*) AS n FROM v_patients_clean GROUP BY insurance_provider_clean; 
SELECT status_clean, COUNT(*) AS n FROM v_appointments_clean GROUP BY status_clean;                   
SELECT payment_status_clean, COUNT(*) AS n FROM v_billing_clean GROUP BY payment_status_clean;       
SELECT diagnosis_code_clean, COUNT(*) AS n FROM v_diagnoses_clean GROUP BY diagnosis_code_clean;     
SELECT diagnosis_clean, COUNT(*) AS n FROM v_diagnoses_clean GROUP BY diagnosis_clean;               

-- Future dates blanked: 8,990 -> 8,982 non-NULL appointment dates; 2,637 -> 2,631 non-NULL DOBs
SELECT COUNT(appointment_date) AS raw_non_null, 
(SELECT COUNT(appointment_date_clean) 
FROM v_appointments_clean) AS cleaned_non_null 
FROM appointments;

SELECT COUNT(date_of_birth) AS raw_non_null, 
(SELECT COUNT(dob_clean) FROM v_patients_clean) AS cleaned_non_null 
FROM patients;

-- True total billed vs the wrong text total 
SELECT SUM(amount_clean) AS true_total FROM v_billing_clean;
