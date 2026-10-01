-- Parámetros (se pasan con -D): fs = frecuencia de muestreo (Hz), dur = duración de sesión (s)
\set uid random(1, 100000000)
\set r_weight random(500, 1100)
\set r_height random(1500, 1950)
\set r_mac random(10, 99)
\set r_val random(6000, 12000)
\set n_samples :fs * :dur
\set step_ms 1000 / :fs

BEGIN;

-- 1. Credencial (primero, porque app_user la referencia)
INSERT INTO auth_credential (password_hash, is_active, created_at, update_at)
VALUES (md5(:uid::text || clock_timestamp()::text), true, clock_timestamp(), clock_timestamp())
RETURNING id_credential \gset

-- 2. Usuario
INSERT INTO app_user (id_city, id_credential, email, first_name, last_name, birth_date, created_at, updated_at)
VALUES (1, :id_credential, 'user_' || :uid || '_' || pg_backend_pid() || '@test.com',
        'FirstName_' || :uid, 'LastName_' || :uid, '1995-05-15', clock_timestamp(), clock_timestamp())
RETURNING id_user \gset

-- 3. Historial de salud
INSERT INTO health_record (id_user, weight_kg, height_cm, recorded_at)
VALUES (:id_user, (:r_weight / 10.0)::numeric(5,2), (:r_height / 10.0)::numeric(5,1), clock_timestamp());

-- 4. Wearable
INSERT INTO wearable (id_user, id_wearable_model, mac_address, created_at, updated_at)
VALUES (:id_user, 1, '00:1A:2B:3C:4D:' || :r_mac, clock_timestamp(), clock_timestamp());

-- 5. Sesión de monitoreo
INSERT INTO monitoring_session (id_user, id_compute_status, date_time, created_at, updated_at, is_delta_encoded)
VALUES (:id_user, 1, clock_timestamp(), clock_timestamp(), clock_timestamp(), false)
RETURNING id_session \gset

-- 6. INSERCIÓN MASIVA de toda la sesión PPG en una sola sentencia
INSERT INTO ppg_sample (id_session, ts, green, red, ir)
SELECT :id_session,
       (extract(epoch from clock_timestamp()) * 1000)::bigint + g * :step_ms,
       (1000 + random() * 49000)::int,
       (1000 + random() * 49000)::int,
       (1000 + random() * 49000)::int
FROM generate_series(0, :n_samples - 1) AS g;

-- 7. Medición calculada
INSERT INTO measurement (id_metric_type, id_session, value, error_message, recorded_at)
VALUES (1, :id_session, (:r_val / 100.0)::numeric(10,4), NULL, clock_timestamp());

-- 8. Alerta posterior a la sesión
INSERT INTO alert (id_session, id_severity_level, description, created_at, updated_at)
VALUES (:id_session, 1, 'Ritmo cardíaco fuera de umbral normal', clock_timestamp(), clock_timestamp());

COMMIT;
