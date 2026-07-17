-- Permanent parallel Nimbus test table.
--
-- Invariant:
--   hydromet.rain_logger_test_events must mirror
--   hydromet.event_observations in columns, defaults, nullability, checks,
--   foreign-key semantics, primary-key shape, hypertable status and index shape.
--
-- It is not related to the old synthetic logger_test chain in public.*.
--
-- Run after sql/hydromet/002_event_observation_dedup.sql.

BEGIN;

DO $$
BEGIN
    IF to_regclass('hydromet.rain_logger_test_events') IS NOT NULL THEN
        RAISE EXCEPTION
            'hydromet.rain_logger_test_events already exists. '
            'Run the parity inventory before replacing an existing table.';
    END IF;
END
$$;

-- LIKE preserves the exact column order, data types, nullability, defaults,
-- storage and CHECK constraints of the corrected production table.
CREATE TABLE hydromet.rain_logger_test_events
(
    LIKE hydromet.event_observations
        INCLUDING DEFAULTS
        INCLUDING CONSTRAINTS
        INCLUDING STORAGE
        INCLUDING COMMENTS
);

-- LIKE does not copy foreign keys or the production primary key in the form
-- needed here, so these are recreated with test-specific constraint names.
ALTER TABLE hydromet.rain_logger_test_events
    ADD CONSTRAINT rain_logger_test_events_series_fk
        FOREIGN KEY (series_id)
        REFERENCES hydromet.observation_series(series_id),

    ADD CONSTRAINT rain_logger_test_events_setup_fk
        FOREIGN KEY (setup_id)
        REFERENCES hydromet.measurement_setups(setup_id),

    ADD CONSTRAINT rain_logger_test_events_pkey
        PRIMARY KEY (time, event_id);

SELECT create_hypertable(
    'hydromet.rain_logger_test_events',
    'time',
    if_not_exists => FALSE
);

-- Same index shapes as production. Names differ only because PostgreSQL index
-- names are schema-global.
CREATE INDEX idx_rain_logger_test_events_series_time
    ON hydromet.rain_logger_test_events (series_id, time DESC);

CREATE INDEX idx_rain_logger_test_events_type_time
    ON hydromet.rain_logger_test_events (event_type, time DESC);

CREATE INDEX idx_rain_logger_test_events_counter
    ON hydromet.rain_logger_test_events (series_id, event_type, counter)
    WHERE counter IS NOT NULL;

CREATE INDEX idx_rain_logger_test_events_quality
    ON hydromet.rain_logger_test_events (quality_flag, time DESC);

COMMENT ON TABLE hydromet.rain_logger_test_events IS
'Permanent parallel test target for real Nimbus MQTT data. Structurally mirrors hydromet.event_observations and is unrelated to the old synthetic logger_test chain.';

COMMIT;
