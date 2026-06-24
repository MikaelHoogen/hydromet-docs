BEGIN;

CREATE SCHEMA IF NOT EXISTS hydromet;

CREATE TABLE IF NOT EXISTS hydromet.rain_logger_test_events (
    time            timestamptz NOT NULL,
    received_at     timestamptz NOT NULL DEFAULT now(),

    source          text NOT NULL,
    sensor_id       text NOT NULL,
    logger_id       text,
    topic           text NOT NULL,

    event_type      text NOT NULL DEFAULT 'rain_tip',
    value           double precision NOT NULL,
    unit            text NOT NULL DEFAULT 'mm',

    counter         bigint,
    raw_counter     bigint,
    ignored_counter bigint,
    interval_ms     bigint,
    time_valid      boolean,

    raw_payload     jsonb NOT NULL,
    metadata        jsonb NOT NULL DEFAULT '{}'::jsonb,

    inserted_at     timestamptz NOT NULL DEFAULT now()
);

SELECT create_hypertable(
    'hydromet.rain_logger_test_events',
    'time',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_rain_logger_test_events_received_at
    ON hydromet.rain_logger_test_events (received_at DESC);

CREATE INDEX IF NOT EXISTS idx_rain_logger_test_events_source_sensor_logger
    ON hydromet.rain_logger_test_events (source, sensor_id, logger_id, time DESC);

CREATE UNIQUE INDEX IF NOT EXISTS uq_rain_logger_test_events_counter
    ON hydromet.rain_logger_test_events (source, sensor_id, logger_id, counter)
    WHERE counter IS NOT NULL;

COMMIT;
