# Data Dictionary: Healthcare Portfolio Database

Synthetic data generated for portfolio/learning purposes only. Not real patient data.

## 1. departments (10 rows)

| Column | Type | Description |
|---|---|---|
| department_id | INTEGER, PK | Unique department identifier |
| department_name | VARCHAR | e.g. Cardiology, Paediatrics, Oncology |
| location | VARCHAR | Building/floor within the hospital |

## 2. doctors (70 rows)

| Column | Type | Description |
|---|---|---|
| doctor_id | INTEGER, PK | Unique doctor identifier |
| first_name / last_name | VARCHAR | Doctor's name |
| department_id | INTEGER, FK → departments | Department the doctor belongs to. **~3% NULL** (not yet assigned). |
| specialisation | VARCHAR | Doctor's specialism, consistent with their department |
| hire_date | DATE | Date the doctor joined |
| email | VARCHAR | Work email. **Some NULL; inconsistent casing** (e.g. `@NHSTrust.example` vs `@nhstrust.example`) |

## 3. patients (2,652 rows)

| Column | Type | Description |
|---|---|---|
| patient_id | INTEGER, PK | Unique patient identifier |
| first_name / last_name | VARCHAR | Patient's name |
| date_of_birth | DATE | **A few NULL; a handful of impossible future dates** (data entry errors) |
| gender | VARCHAR | **Inconsistent categories**: `M`, `F`, `Male`, `Female`, `m`, `f`, `Non-binary`, NULL, `''` |
| city | VARCHAR | **Inconsistent casing/spacing**, e.g. `Middlesbrough` / `middlesbrough` / `MIDDLESBROUGH`, `York` / `york ` |
| phone | VARCHAR | **Inconsistent formats** (with/without spaces, with/without `+44`); some NULL |
| email | VARCHAR | Some NULL |
| insurance_provider | VARCHAR | **Inconsistent categories & casing**: `NHS`, `Bupa`/`BUPA`/`bupa`, `AXA Health`/`axa health`, `Vitality`, `Self-Pay`/`self pay`, `None` (string), NULL, `''` |
| registration_date | DATE | Date the patient registered |

**Known issue:** ~2% of patients are **near-duplicate registrations** — the same person appears twice with two different `patient_id`s (a realistic "patient registered twice at reception" scenario).

## 4. appointments (9,000 rows)

| Column | Type | Description |
|---|---|---|
| appointment_id | INTEGER, PK | Unique appointment identifier |
| patient_id | INTEGER, FK → patients | **A handful (≈10) reference a patient_id that does not exist** — dangling FK, intentional |
| doctor_id | INTEGER, FK → doctors | **A handful (≈10) reference a doctor_id that does not exist** — dangling FK, intentional |
| appointment_date | DATE | **Some NULL; a few nonsensical entries in the year 2030** |
| appointment_time | TIME | Time of appointment |
| status | VARCHAR | **Inconsistent categories**: `Completed`/`completed`/`COMPLETED`, `Cancelled`/`cancelled`, `No-show`/`no show`/`No Show`, `Scheduled`/`scheduled` |
| reason | VARCHAR | Free-text-style reason category (routine check-up, follow-up, emergency, etc.) |

## 5. diagnoses (4,689 rows)

| Column | Type | Description |
|---|---|---|
| diagnosis_id | INTEGER, PK | Unique diagnosis identifier |
| appointment_id | INTEGER, FK → appointments | The appointment this diagnosis was recorded at |
| diagnosis_code | VARCHAR | ICD-10-style code. **A handful malformed** (lower-cased, punctuation stripped) |
| diagnosis_description | VARCHAR | **Some inconsistent casing (ALL CAPS) and trailing whitespace** |

Not every appointment has a diagnosis (only appointments logged, mostly, as "Completed" — though a small number of inconsistent entries exist against other statuses too, which is itself worth investigating).

## 6. billing (7,857 rows)

| Column | Type | Description |
|---|---|---|
| bill_id | INTEGER, PK | Unique billing record identifier |
| appointment_id | INTEGER, FK → appointments | The appointment being billed |
| amount | VARCHAR | **Mostly numeric, but a small % stored as text with a `£` symbol** (type inconsistency); **a small % are erroneous negative values** |
| payment_status | VARCHAR | **Inconsistent categories**: `Paid`/`paid`/`PAID`, `Unpaid`/`unpaid`, `Pending`/`pending`, `Refunded` |
| insurance_covered | VARCHAR | `True` / `False` / NULL, stored as text rather than boolean |
| bill_date | DATE | Usually matches the appointment date |

Most cancelled appointments were never billed; a small number of appointments that should have a bill are missing one entirely (data gap).

## 7. prescriptions (4,449 rows)

| Column | Type | Description |
|---|---|---|
| prescription_id | INTEGER, PK | Unique prescription identifier |
| appointment_id | INTEGER, FK → appointments | The appointment the medication was prescribed at |
| medication_name | VARCHAR | **Occasional inconsistent casing** |
| dosage | VARCHAR | e.g. `500mg` |
| duration_days | INTEGER | **Some NULL** (course length not recorded) |

An appointment may have 0, 1, or 2 prescriptions attached. Prescriptions are only generated for appointments that also have a diagnosis recorded.

---

## Summary of intentional data-quality issues (for Stage 2/3 of the project)

1. Inconsistent categorical values (gender, insurance_provider, city, status, payment_status) — mixed casing, whitespace, synonyms
2. Missing values scattered across most tables (NULLs and empty strings — check for both)
3. Near-duplicate patient records
4. Dangling foreign keys in `appointments` (patient_id / doctor_id pointing nowhere)
5. Impossible/nonsensical dates (future DOB, appointment dates in 2030, some NULL dates)
6. Type inconsistency in `billing.amount` (numbers stored as text with currency symbols)
7. Invalid/erroneous values (negative billing amounts)
8. Orphaned doctors (NULL department_id)
9. Malformed diagnosis codes

