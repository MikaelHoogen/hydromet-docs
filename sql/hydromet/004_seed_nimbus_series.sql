-- Register the real Nimbus observation series and its current measurement setup.
--
-- Both the test and production AppDaemon instances resolve the same series_id
-- and setup_id. Only their target event table differs.
--
-- This migration inserts no rainfall observation and does not touch public.*.

BEGIN;

WITH upserted_series AS (
    INSERT INTO hydromet.observation_series (
        series_key,
        observed_property,
        medium,
        location_key,
        location_type,
        unit,
        source_type,
        resolution_type,
        is_primary,
        is_active,
        is_test,
        metadata
    )
    VALUES (
        'rain.sannesholma.nimbus.rain_1.tb4_0p2',
        'precipitation_tip',
        'precipitation',
        'sannesholma',
        'station',
        'mm',
        'mqtt_logger',
        'event',
        true,
        true,
        false,
        jsonb_build_object(
            'site_id', 'sannesholma',
            'logger_id', 'nimbus',
            'channel_id', 'rain_1',
            'sensor_id', 'tb4_0p2',
            'sensor_manufacturer', 'KISTERS',
            'sensor_model', 'TB4',
            'mm_per_tip', 0.2,
            'mqtt_topic_root',
                'regnlogger/sannesholma/nimbus/rain_1'
        )
    )
    ON CONFLICT (series_key) DO UPDATE
    SET
        observed_property = EXCLUDED.observed_property,
        medium = EXCLUDED.medium,
        location_key = EXCLUDED.location_key,
        location_type = EXCLUDED.location_type,
        unit = EXCLUDED.unit,
        source_type = EXCLUDED.source_type,
        resolution_type = EXCLUDED.resolution_type,
        is_primary = EXCLUDED.is_primary,
        is_active = true,
        is_test = false,
        metadata =
            hydromet.observation_series.metadata || EXCLUDED.metadata
    RETURNING series_id
),
resolved_series AS (
    SELECT series_id FROM upserted_series
    UNION ALL
    SELECT series_id
    FROM hydromet.observation_series
    WHERE series_key = 'rain.sannesholma.nimbus.rain_1.tb4_0p2'
    LIMIT 1
)
INSERT INTO hydromet.measurement_setups (
    series_id,
    valid_from,
    instrument_model,
    sensor_type,
    installation_description,
    logger_type,
    firmware,
    notes,
    metadata
)
SELECT
    series_id,
    '2026-07-17 00:00:00+00'::timestamptz,
    'KISTERS TB4',
    'tipping_bucket',
    'Sännesholma Nimbus: KISTERS TB4 connected as a dry contact between DI1 and DGND.',
    'waveshare_esp32_s3_poe_eth_8di_8do',
    'rainlens-level1-0.1.1',
    'Initial verified Nimbus measurement setup. GPIO4 input + pull-up + inverted; 0.2 mm per tip.',
    jsonb_build_object(
        'physical_input', 'DI1',
        'field_return', 'DGND',
        'hardware_binding', 'GPIO4',
        'network', 'poe_ethernet',
        'framework', 'esp-idf',
        'mqtt_topic_root',
            'regnlogger/sannesholma/nimbus/rain_1'
    )
FROM resolved_series
WHERE NOT EXISTS (
    SELECT 1
    FROM hydromet.measurement_setups ms
    WHERE ms.series_id = resolved_series.series_id
      AND ms.valid_to IS NULL
);

COMMIT;
