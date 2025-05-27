-- DROP & CREATE SCHEMA
DROP SCHEMA IF EXISTS hospital_management CASCADE;
CREATE SCHEMA IF NOT EXISTS hospital_management;

-- Enhanced user_login table in a separate schema
DROP TABLE IF EXISTS online_retail_app.user_login;
CREATE TABLE IF NOT EXISTS online_retail_app.user_login (
	user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_password TEXT NOT NULL,
    first_name TEXT NOT NULL,
	last_name TEXT NOT NULL,
	sign_up_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	email_id TEXT UNIQUE NOT NULL
);

-- Patient Table
DROP TABLE IF EXISTS hospital_management.patient;
CREATE TABLE IF NOT EXISTS hospital_management.patient (
    patient_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(60) NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Medical History Table
DROP TABLE IF EXISTS hospital_management.medical_history;
CREATE TABLE IF NOT EXISTS hospital_management.medical_history (
    medical_history_id SERIAL PRIMARY KEY,
    patient_id UUID REFERENCES hospital_management.patient(patient_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    conditions TEXT,
    surgeries TEXT,
    medication TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Doctor Table
DROP TABLE IF EXISTS hospital_management.doctor;
CREATE TABLE IF NOT EXISTS hospital_management.doctor (
    doctor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(50) UNIQUE NOT NULL,
    gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
    password VARCHAR(60) NOT NULL,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Appointment Table
DROP TABLE IF EXISTS hospital_management.appointment;
CREATE TABLE IF NOT EXISTS hospital_management.appointment (
    appointment_id SERIAL PRIMARY KEY,
    patient_id UUID REFERENCES hospital_management.patient(patient_id) ON DELETE SET NULL,
    doctor_id UUID REFERENCES hospital_management.doctor(doctor_id) ON DELETE SET NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(15) CHECK (status IN ('Scheduled', 'Completed', 'Cancelled')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Patient Visits Table
DROP TABLE IF EXISTS hospital_management.patient_visits;
CREATE TABLE IF NOT EXISTS hospital_management.patient_visits (
    visit_id SERIAL PRIMARY KEY,
    appointment_id INT REFERENCES hospital_management.appointment(appointment_id) ON DELETE CASCADE,
    concerns TEXT,
    symptoms TEXT,
    diagnosis TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Schedule Table
DROP TABLE IF EXISTS hospital_management.schedule;
CREATE TABLE IF NOT EXISTS hospital_management.schedule (
    schedule_id SERIAL PRIMARY KEY,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_time INTERVAL,
    day_of_week VARCHAR(10) CHECK (day_of_week IN ('Mon','Tue','Wed','Thu','Fri','Sat','Sun')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Doctor Schedules
DROP TABLE IF EXISTS hospital_management.doctor_schedules;
CREATE TABLE IF NOT EXISTS hospital_management.doctor_schedules (
    id SERIAL PRIMARY KEY,
    doctor_id UUID REFERENCES hospital_management.doctor(doctor_id) ON DELETE CASCADE,
    schedule_id INT REFERENCES hospital_management.schedule(schedule_id) ON DELETE CASCADE,
    active BOOLEAN DEFAULT TRUE,
    UNIQUE(doctor_id, schedule_id)
);

-- Diagnoses Table
DROP TABLE IF EXISTS hospital_management.diagnose;
CREATE TABLE IF NOT EXISTS hospital_management.diagnose (
    diagnosis_id SERIAL PRIMARY KEY,
    appointment_id INT REFERENCES hospital_management.appointment(appointment_id) ON DELETE CASCADE,
    doctor_id UUID REFERENCES hospital_management.doctor(doctor_id) ON DELETE CASCADE,
    diagnosis TEXT NOT NULL,
    prescription TEXT NOT NULL,
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Doctor View History
DROP TABLE IF EXISTS hospital_management.doctor_view_history;
CREATE TABLE IF NOT EXISTS hospital_management.doctor_view_history (
    view_id SERIAL PRIMARY KEY,
    doctor_id UUID REFERENCES hospital_management.doctor(doctor_id),
    medical_history_id INT REFERENCES hospital_management.medical_history(medical_history_id),
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_patient_email ON hospital_management.patient(email);
CREATE INDEX IF NOT EXISTS idx_appointment_date ON hospital_management.appointment(date);
CREATE INDEX IF NOT EXISTS idx_doctor_specialization ON hospital_management.doctor(specialization);

-- Sample View for Daily Appointments
CREATE OR REPLACE VIEW hospital_management.daily_appointments AS
SELECT a.date, d.name AS doctor_name, p.name AS patient_name, a.status
FROM hospital_management.appointment a
JOIN hospital_management.doctor d ON a.doctor_id = d.doctor_id
JOIN hospital_management.patient p ON a.patient_id = p.patient_id
WHERE a.date = CURRENT_DATE;

-- Sample Trigger: Auto-Cancel Past Appointments
CREATE OR REPLACE FUNCTION auto_cancel_past_appointments()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.date < CURRENT_DATE THEN
    NEW.status := 'Cancelled';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_cancel_past
BEFORE INSERT ON hospital_management.appointment
FOR EACH ROW
EXECUTE FUNCTION auto_cancel_past_appointments();
