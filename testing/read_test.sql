\set user_id random(1, 1003)
BEGIN;
SELECT * FROM app_user WHERE id_user = :user_id;
SELECT * FROM monitoring_session WHERE id_user = :user_id ORDER BY date_time DESC LIMIT 10;
END;