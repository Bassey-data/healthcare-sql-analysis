
USE healthcare_portfolio;



-- How concentrated is billed revenue? Do a few patients account for most of it?
WITH patient_spend AS (
    SELECT p.patient_id,
           SUM(b.amount_clean) AS total_billed
    FROM v_billing_clean b
    JOIN v_appointments_clean a ON b.appointment_id = a.appointment_id
    JOIN v_patients_clean p     ON a.patient_id = p.patient_id
    WHERE b.amount_clean > 0
    GROUP BY p.patient_id
),
deciles AS (
    SELECT patient_id,
           total_billed,
           NTILE(10) OVER (ORDER BY total_billed DESC) AS spend_decile
    FROM patient_spend
)
SELECT spend_decile,
       COUNT(*) AS patients,
       ROUND(SUM(total_billed), 2) AS billed,
       ROUND(SUM(total_billed) / SUM(SUM(total_billed)) OVER () * 100, 1) AS pct_of_total_billed
FROM deciles
GROUP BY spend_decile
ORDER BY spend_decile;



-- How often do patients come back within 30 days of a completed visit?

WITH visits AS (
    SELECT a.patient_id,
           a.appointment_id,
           a.appointment_date_clean AS visit_date,
           LAG(a.appointment_date_clean) OVER (
               PARTITION BY a.patient_id
               ORDER BY a.appointment_date_clean, a.appointment_id
           ) AS previous_visit_date
    FROM v_appointments_clean a
    JOIN v_patients_clean p ON a.patient_id = p.patient_id
    WHERE a.status_clean = 'COMPLETED'
      AND a.appointment_date_clean IS NOT NULL
),
gaps AS (
    SELECT patient_id,
           DATEDIFF(visit_date, previous_visit_date) AS days_since_previous
    FROM visits
    WHERE previous_visit_date IS NOT NULL
)
SELECT COUNT(*) AS repeat_visits,
       SUM(CASE WHEN days_since_previous <= 30 THEN 1 ELSE 0 END) AS within_30_days,
       ROUND(SUM(CASE WHEN days_since_previous <= 30 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS pct_within_30_days,
       ROUND(AVG(days_since_previous), 0) AS avg_days_between_visits
FROM gaps;



-- Which doctors handle more or fewer appointments than their department average?
WITH doctor_load AS (
    SELECT doc.doctor_id,
           CONCAT(doc.first_name, ' ', doc.last_name) AS doctor,
           dep.department_name,
           COUNT(*) AS appointments,
           ROUND(SUM(CASE WHEN a.status_clean = 'COMPLETED' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS completed_pct
    FROM v_appointments_clean a
    JOIN doctors doc     ON a.doctor_id = doc.doctor_id
    JOIN departments dep ON doc.department_id = dep.department_id
    GROUP BY doc.doctor_id, doc.first_name, doc.last_name, dep.department_name
)
SELECT doctor,
       department_name,
       appointments,
       ROUND(AVG(appointments) OVER (PARTITION BY department_name), 1) AS dept_avg_appointments,
       ROUND(appointments - AVG(appointments) OVER (PARTITION BY department_name), 1) AS diff_from_dept_avg,
       completed_pct
FROM doctor_load
ORDER BY diff_from_dept_avg DESC;
