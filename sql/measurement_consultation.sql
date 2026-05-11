
-- measurement_consultation

SELECT
    u.first_name AS firstname,
    u.last_name AS lastnameU,
    hr.weight_kg,
    hr.height_cm,
    m.value AS metric_value,
    m.recorded_at AS metric_recorded_at
    ppg.id_ppg_sample,
    ppg.ts,
    ppg.green,
    ppg.red,
    ppg.ir,

    mt.name AS typeName,

FROM ppg_sample ppg
INNER JOIN monitoring_session ms
    ON ppg.id_session = ms.id_session

INNER JOIN App_User u
    ON ms.id_user = u.id_user

LEFT JOIN health_record hr
    ON u.id_user = hr.id_user

LEFT JOIN Measurement m
    ON ms.id_session = m.id_session

LEFT JOIN metric_type mt
    ON m.id_metric_type = mt.id_metric_type;