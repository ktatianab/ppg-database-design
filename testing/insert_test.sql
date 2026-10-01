-- insert_full_test.sql
-- Variables aleatorias para evitar colisiones y simular datos reales

--Escenario de pruebas

ktatianab:~# pgbench "$PGURL" -f insert_test.sql -c 1   -j 1 -T 60 --no-vacuum

--ktatianab:~# pgbench "$PGURL" -f insert_test.sql -c 10  -j 2 -T 60 --no-vacuum

--ktatianab:~# pgbench "$PGURL" -f insert_test.sql -c 50  -j 4 -T 60 --no-vacuum

--ktatianab:~# pgbench "$PGURL" -f insert_test.sql -c 100 -j 8 -T 60 --no-vacuum



SET search_path TO tu_esquema, public;
\set uid random(1, 100000000)
\set r_weight random(500, 1100)
\set r_height random(1500, 1950)
\set r_mac random(10, 99)
\set r_val random(6000, 12000)
\set r_green random(1000, 50000)
\set r_red random(1000, 50000)
\set r_ir random(1000, 50000)

BEGIN;



-- 1. Crear usuario asociado a la credencial y a una ciudad (asume id_city = 1)
INSERT INTO app_user (
    id_city, 
    id_credential, 
    email, 
    first_name, 
    last_name, 
    birth_date, 
    created_at, 
    updated_at
)
VALUES (
    1, 
    :id_credential, 
    'user_' || :uid || '_' || pg_backend_pid() || '@test.com', 
    'FirstName_' || :uid, 
    'LastName_' || :uid, 
    '1995-05-15', 
    clock_timestamp(), 
    clock_timestamp()
)
RETURNING id_user \gset

-- 2. Crear credencial de autenticación (1:1 con app_user)
INSERT INTO auth_credential (password_hash, is_active, created_at, update_at)
VALUES (
    md5(:uid::text || clock_timestamp()::text),
    true,
    clock_timestamp(),
    clock_timestamp()
)
RETURNING id_credential \gset

-- 3. Historial de salud del usuario
INSERT INTO health_record (id_user, weight_kg, height_cm, recorded_at)
VALUES (
    :id_user, 
    (:r_weight / 10.0)::numeric(5,2), 
    (:r_height / 10.0)::numeric(5,1), 
    clock_timestamp()
);

-- 4. Registro del dispositivo wearable asociado al usuario (asume id_wearable_model = 1)
INSERT INTO wearable (id_user, id_wearable_model, mac_address, created_at, updated_at)
VALUES (
    :id_user, 
    1, 
    '00:1A:2B:3C:4D:' || :r_mac, 
    clock_timestamp(), 
    clock_timestamp()
);

-- 5. Sesión de monitoreo (asume id_compute_status = 1)
INSERT INTO monitoring_session (
    id_user, 
    id_compute_status, 
    date_time, 
    created_at, 
    updated_at, 
    is_delta_encoded
)
VALUES (
    :id_user, 
    1, 
    clock_timestamp(), 
    clock_timestamp(), 
    clock_timestamp(), 
    false
)
RETURNING id_session \gset

-- 6. Muestra de sensor PPG
INSERT INTO ppg_sample (id_session, ts, green, red, ir)
VALUES (
    :id_session, 
    extract(epoch from clock_timestamp())::bigint, 
    :r_green, 
    :r_red, 
    :r_ir
);

-- 7. Medición calculada (asume metric_type = 1)
INSERT INTO measurement (id_metric_type, id_session, value, error_message, recorded_at)
VALUES (
    1, 
    :id_session, 
    (:r_val / 100.0)::numeric(10,4), 
    NULL, 
    clock_timestamp()
);

-- 8. Alerta generada durante la sesión (asume id_severity_level = 1)
INSERT INTO alert (id_session, id_severity_level, description, created_at, updated_at)
VALUES (
    :id_session, 
    1, 
    'Ritmo cardíaco fuera de umbral normal', 
    clock_timestamp(), 
    clock_timestamp()
);

COMMIT;