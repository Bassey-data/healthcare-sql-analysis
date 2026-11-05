

USE healthcare_portfolio;


-- What is the total amount billed?

SELECT (SELECT SUM(amount) FROM billing) AS wrong_total_from_text,
       SUM(amount_clean) AS total_all_amounts,
       SUM(CASE WHEN amount_clean > 0 THEN amount_clean ELSE 0 END) AS total_positive_only,
       SUM(CASE WHEN amount_clean < 0 THEN amount_clean ELSE 0 END) AS total_negative_only
FROM v_billing_clean;



-- What share of appointments are completed, missed, cancelled or still scheduled?

SELECT status_clean,
       COUNT(*) AS appointments,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM v_appointments_clean) * 100, 1) AS pct_of_appointments
FROM v_appointments_clean
GROUP BY status_clean
ORDER BY appointments DESC;


-- Do the statuses make sense? 
-- Appointments still marked SCHEDULED although their date has already passed
SELECT COUNT(*) AS scheduled_but_in_past
FROM v_appointments_clean
WHERE status_clean = 'SCHEDULED'
  AND appointment_date_clean < '2026-09-16';

-- How many appointments of each status have a bill?
SELECT a.status_clean,
       COUNT(*) AS appointments,
       SUM(CASE WHEN b.bill_id IS NOT NULL THEN 1 ELSE 0 END) AS billed,
       ROUND(SUM(CASE WHEN b.bill_id IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS pct_billed
FROM v_appointments_clean a
LEFT JOIN v_billing_clean b ON a.appointment_id = b.appointment_id
GROUP BY a.status_clean
ORDER BY appointments DESC;


-- How is the workload and attendance spread across departments?
SELECT COALESCE(dep.department_name, 'Unassigned') AS department,
       COUNT(*) AS appointments,
       ROUND(SUM(CASE WHEN a.status_clean = 'COMPLETED' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS completed_pct,
       ROUND(SUM(CASE WHEN a.status_clean = 'MISSED'    THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS missed_pct
FROM v_appointments_clean a
JOIN doctors doc          ON a.doctor_id = doc.doctor_id
LEFT JOIN departments dep ON doc.department_id = dep.department_id
GROUP BY COALESCE(dep.department_name, 'Unassigned')
ORDER BY appointments DESC;



--  How does billed revenue change by quarter?

SELECT YEAR(bill_date_clean) AS yr,
       QUARTER(bill_date_clean) AS qtr,
       COUNT(*) AS bills,
       SUM(amount_clean) AS billed
FROM v_billing_clean
WHERE amount_clean > 0
  AND bill_date_clean IS NOT NULL
GROUP BY YEAR(bill_date_clean), QUARTER(bill_date_clean)
ORDER BY yr, qtr;


-- How much is the hospital still waiting to be paid?
SELECT COUNT(*) AS bills,
       SUM(amount_clean) AS owed_all_amounts,
       SUM(CASE WHEN amount_clean > 0 THEN amount_clean ELSE 0 END) AS owed_positive_only
FROM v_billing_clean
WHERE payment_status_clean IN ('Unpaid', 'Pending');

-- The 10 patients who owe the most (positive amounts, Unpaid/Pending)

SELECT p.patient_id,
       p.first_name,
       p.last_name,
       COUNT(*) AS open_bills,
       SUM(b.amount_clean) AS amount_owed
FROM v_billing_clean b
JOIN v_appointments_clean a ON b.appointment_id = a.appointment_id
JOIN v_patients_clean p     ON a.patient_id = p.patient_id
WHERE b.payment_status_clean IN ('Unpaid', 'Pending')
  AND b.amount_clean > 0
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY amount_owed DESC
LIMIT 10;
