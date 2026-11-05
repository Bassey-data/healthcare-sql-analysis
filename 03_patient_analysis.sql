

USE healthcare_portfolio;


-- Patients analysis
-- How many patients have an insurance provider on file?

SELECT CASE
           WHEN insurance_provider_clean IN ('BUPA', 'AXA_HEALTH', 'VITALITY', 'NHS') THEN 'Has provider'
           ELSE 'No provider'
       END AS insurance_status,
       COUNT(*) AS patients,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM v_patients_clean) * 100, 1) AS pct_of_patients
FROM v_patients_clean
GROUP BY insurance_status;



-- Which diagnoses are most common in each age band?

SELECT p.age_band,
       d.diagnosis_clean,
       COUNT(*) AS diagnoses
FROM v_diagnoses_clean d
JOIN v_appointments_clean a ON d.appointment_id = a.appointment_id
JOIN v_patients_clean p     ON a.patient_id = p.patient_id
GROUP BY p.age_band, d.diagnosis_clean
ORDER BY p.age_band, diagnoses DESC;

-- Top 3 diagnoses per age band 
WITH band_counts AS (
    SELECT p.age_band,
           d.diagnosis_clean,
           COUNT(*) AS diagnoses
    FROM v_diagnoses_clean d
    JOIN v_appointments_clean a ON d.appointment_id = a.appointment_id
    JOIN v_patients_clean p     ON a.patient_id = p.patient_id
    GROUP BY p.age_band, d.diagnosis_clean
),
ranked AS (
    SELECT age_band,
           diagnosis_clean,
           diagnoses,
           RANK() OVER (PARTITION BY age_band ORDER BY diagnoses DESC) AS rank_in_band
    FROM band_counts
)
SELECT age_band, rank_in_band, diagnosis_clean, diagnoses
FROM ranked
WHERE rank_in_band <= 3
ORDER BY age_band, rank_in_band;



-- Which medications are prescribed most in each age band?

WITH band_counts AS (
    SELECT p.age_band,
           rx.medication_clean,
           COUNT(*) AS prescriptions
    FROM v_prescriptions_clean rx
    JOIN v_appointments_clean a ON rx.appointment_id = a.appointment_id
    JOIN v_patients_clean p     ON a.patient_id = p.patient_id
    GROUP BY p.age_band, rx.medication_clean
),
ranked AS (
    SELECT age_band,
           medication_clean,
           prescriptions,
           RANK() OVER (PARTITION BY age_band ORDER BY prescriptions DESC) AS rank_in_band
    FROM band_counts
)
SELECT age_band, rank_in_band, medication_clean, prescriptions
FROM ranked
WHERE rank_in_band <= 3
ORDER BY age_band, rank_in_band;



-- How do insurance segments compare on attendance and billing?

SELECT p.insurance_provider_clean AS insurance_provider,
       COUNT(DISTINCT p.patient_id) AS patients,
       COUNT(DISTINCT a.appointment_id) AS appointments,
       ROUND(SUM(CASE WHEN a.status_clean = 'MISSED' THEN 1 ELSE 0 END) / COUNT(DISTINCT a.appointment_id) * 100, 1) AS missed_pct,
       ROUND(AVG(CASE WHEN b.amount_clean > 0 THEN b.amount_clean END), 2) AS avg_bill
FROM v_patients_clean p
JOIN v_appointments_clean a ON p.patient_id = a.patient_id
LEFT JOIN v_billing_clean b ON a.appointment_id = b.appointment_id
GROUP BY p.insurance_provider_clean
ORDER BY avg_bill DESC;
