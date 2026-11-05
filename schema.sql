

CREATE TABLE departments (
    department_id    INTEGER PRIMARY KEY,
    department_name  VARCHAR(50),
    location          VARCHAR(50)
);

CREATE TABLE doctors (
    doctor_id       INTEGER PRIMARY KEY,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    department_id   INTEGER,             
    specialisation  VARCHAR(50),
    hire_date       DATE,
    email           VARCHAR(100),       
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE patients (
    patient_id          INTEGER PRIMARY KEY,
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    date_of_birth       DATE,             
    gender              VARCHAR(20),      
    city                VARCHAR(50),      
    phone               VARCHAR(30),    
    email               VARCHAR(100),     
    insurance_provider  VARCHAR(50),      
    registration_date   DATE
    
);

CREATE TABLE appointments (
    appointment_id    INTEGER PRIMARY KEY,
    patient_id        INTEGER,          
    doctor_id         INTEGER,           
    appointment_date  DATE,             
    appointment_time  TIME,
    status            VARCHAR(20),       
                                          
    reason             VARCHAR(50),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE diagnoses (
    diagnosis_id           INTEGER PRIMARY KEY,
    appointment_id         INTEGER,
    diagnosis_code         VARCHAR(10),  
    diagnosis_description  VARCHAR(100),  
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

CREATE TABLE billing (
    bill_id            INTEGER PRIMARY KEY,
    appointment_id     INTEGER,
    amount             VARCHAR(20),      
                                          
                                         
    payment_status     VARCHAR(20),     
                                          
    insurance_covered  VARCHAR(10),     )
    bill_date          DATE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

CREATE TABLE prescriptions (
    prescription_id  INTEGER PRIMARY KEY,
    appointment_id   INTEGER,
    medication_name  VARCHAR(50),    
    dosage           VARCHAR(20),
    duration_days    INTEGER,          
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

