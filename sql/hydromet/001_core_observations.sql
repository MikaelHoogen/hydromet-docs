-- Hydromet core observation schema
--
-- Purpose:
--   Create the first generic hydromet core tables.
--
-- Scope:
--   - observation series
--   - measurement setups
--   - point observations
--   - interval observations
--   - event observations
--   - system health
--   - system alerts
--
-- Important:
--   This migration does not modify or delete the existing public.rain_tip_events table.
--   Existing prototype data should be migrated explicitly in a later migration.

BEGIN;

CREATE SCHEMA IF NOT EXISTS hydromet;

-- Optional but expected in the TimescaleDB add-on environment.
-- pgcrypto provides gen_random_uuid(), used for UUID primary keys.
-- Kept as IF NOT EXISTS so the script can be re-run safely where permitted.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- -----------------------------------------------------------------------------
-- Observation series
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.observation_series (
    series_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    series_key text NOT NULL UNIQUE,

    -- What is measured, for example:
    -- precipitation_tip, precipitation_interval, water_level, discharge,
    -- soil_moisture, wind_speed, air_temperature, system_status.
    observed_property text NOT NULL,

    -- What medium/object the observation relates to, for example:
    -- atmosphere, precipitation, stormwater, surface_water, groundwater,
    -- soil, pond, well, pipe_flow, system.
    medium text,

    location_key text,
    location_type text,

    unit text,
    source_type text NOT NULL,
    resolution_type text NOT NULL,

    is_primary boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    is_test boolean NOT NULL DEFAULT false,

    created_at timestamptz NOT NULL DEFAULT now(),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT observation_series_series_key_not_blank
        CHECK (length(trim(series_key)) > 0),
    CONSTRAINT observation_series_observed_property_not_blank
        CHECK (length(trim(observed_property)) > 0),
    CONSTRAINT observation_series_source_type_not_blank
        CHECK (length(trim(source_type)) > 0),
    CONSTRAINT observation_series_resolution_type_not_blank
        CHECK (length(trim(resolution_type)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_observation_series_observed_property
    ON hydromet.observation_series (observed_property);

CREATE INDEX IF NOT EXISTS idx_observation_series_medium
    ON hydromet.observation_series (medium);

CREATE INDEX IF NOT EXISTS idx_observation_series_active
    ON hydromet.observation_series (is_active);

-- -----------------------------------------------------------------------------
-- Measurement setups
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.measurement_setups (
    setup_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    series_id uuid NOT NULL REFERENCES hydromet.observation_series(series_id),

    valid_from timestamptz NOT NULL,
    valid_to timestamptz,

    instrument_model text,
    instrument_serial text,
    sensor_type text,
    installation_description text,
    mounting_height_m double precision,
    reference_level text,
    logger_type text,
    firmware text,
    notes text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT measurement_setups_valid_time_range
        CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE INDEX IF NOT EXISTS idx_measurement_setups_series_time
    ON hydromet.measurement_setups (series_id, valid_from DESC);

CREATE INDEX IF NOT EXISTS idx_measurement_setups_active
    ON hydromet.measurement_setups (series_id)
    WHERE valid_to IS NULL;

-- -----------------------------------------------------------------------------
-- Point observations
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.point_observations (
    time timestamptz NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),

    series_id uuid NOT NULL REFERENCES hydromet.observation_series(series_id),
    setup_id uuid REFERENCES hydromet.measurement_setups(setup_id),

    value double precision NOT NULL,
    unit text,
    quality_flag text NOT NULL DEFAULT 'unchecked',
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    PRIMARY KEY (time, series_id)
);

SELECT create_hypertable(
    'hydromet.point_observations',
    'time',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_point_observations_series_time
    ON hydromet.point_observations (series_id, time DESC);

CREATE INDEX IF NOT EXISTS idx_point_observations_quality
    ON hydromet.point_observations (quality_flag, time DESC);

-- -----------------------------------------------------------------------------
-- Interval observations
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.interval_observations (
    interval_start timestamptz NOT NULL,
    interval_end timestamptz NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),

    series_id uuid NOT NULL REFERENCES hydromet.observation_series(series_id),
    setup_id uuid REFERENCES hydromet.measurement_setups(setup_id),

    value double precision NOT NULL,
    unit text,
    aggregation text,
    quality_flag text NOT NULL DEFAULT 'unchecked',
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    PRIMARY KEY (interval_start, series_id, interval_end),

    CONSTRAINT interval_observations_valid_interval
        CHECK (interval_end > interval_start)
);

SELECT create_hypertable(
    'hydromet.interval_observations',
    'interval_start',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_interval_observations_series_time
    ON hydromet.interval_observations (series_id, interval_start DESC);

CREATE INDEX IF NOT EXISTS idx_interval_observations_end_time
    ON hydromet.interval_observations (interval_end DESC);

CREATE INDEX IF NOT EXISTS idx_interval_observations_quality
    ON hydromet.interval_observations (quality_flag, interval_start DESC);

-- -----------------------------------------------------------------------------
-- Event observations
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.event_observations (
    time timestamptz NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),

    series_id uuid NOT NULL REFERENCES hydromet.observation_series(series_id),
    setup_id uuid REFERENCES hydromet.measurement_setups(setup_id),

    event_type text NOT NULL,
    value double precision,
    unit text,
    counter bigint,
    quality_flag text NOT NULL DEFAULT 'unchecked',
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    PRIMARY KEY (time, series_id, event_type),

    CONSTRAINT event_observations_event_type_not_blank
        CHECK (length(trim(event_type)) > 0)
);

SELECT create_hypertable(
    'hydromet.event_observations',
    'time',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_event_observations_series_time
    ON hydromet.event_observations (series_id, time DESC);

CREATE INDEX IF NOT EXISTS idx_event_observations_type_time
    ON hydromet.event_observations (event_type, time DESC);

CREATE INDEX IF NOT EXISTS idx_event_observations_counter
    ON hydromet.event_observations (series_id, counter)
    WHERE counter IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_event_observations_quality
    ON hydromet.event_observations (quality_flag, time DESC);

-- -----------------------------------------------------------------------------
-- System health
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.system_health (
    time timestamptz NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),

    component_key text NOT NULL,
    component_type text,
    status text NOT NULL,
    severity text NOT NULL DEFAULT 'info',

    series_id uuid REFERENCES hydromet.observation_series(series_id),
    setup_id uuid REFERENCES hydromet.measurement_setups(setup_id),

    message text,
    raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    PRIMARY KEY (time, component_key, status),

    CONSTRAINT system_health_component_key_not_blank
        CHECK (length(trim(component_key)) > 0),
    CONSTRAINT system_health_status_not_blank
        CHECK (length(trim(status)) > 0),
    CONSTRAINT system_health_severity_not_blank
        CHECK (length(trim(severity)) > 0)
);

SELECT create_hypertable(
    'hydromet.system_health',
    'time',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_system_health_component_time
    ON hydromet.system_health (component_key, time DESC);

CREATE INDEX IF NOT EXISTS idx_system_health_status_time
    ON hydromet.system_health (status, time DESC);

CREATE INDEX IF NOT EXISTS idx_system_health_severity_time
    ON hydromet.system_health (severity, time DESC);

-- -----------------------------------------------------------------------------
-- System alerts
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS hydromet.system_alerts (
    alert_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    opened_at timestamptz NOT NULL DEFAULT now(),
    closed_at timestamptz,

    component_key text NOT NULL,
    alert_type text NOT NULL,
    severity text NOT NULL DEFAULT 'warning',
    status text NOT NULL DEFAULT 'open',

    series_id uuid REFERENCES hydromet.observation_series(series_id),
    setup_id uuid REFERENCES hydromet.measurement_setups(setup_id),

    message text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT system_alerts_component_key_not_blank
        CHECK (length(trim(component_key)) > 0),
    CONSTRAINT system_alerts_alert_type_not_blank
        CHECK (length(trim(alert_type)) > 0),
    CONSTRAINT system_alerts_severity_not_blank
        CHECK (length(trim(severity)) > 0),
    CONSTRAINT system_alerts_status_not_blank
        CHECK (length(trim(status)) > 0),
    CONSTRAINT system_alerts_valid_time_range
        CHECK (closed_at IS NULL OR closed_at >= opened_at)
);

CREATE INDEX IF NOT EXISTS idx_system_alerts_open
    ON hydromet.system_alerts (opened_at DESC)
    WHERE status = 'open';

CREATE INDEX IF NOT EXISTS idx_system_alerts_component_opened
    ON hydromet.system_alerts (component_key, opened_at DESC);

CREATE INDEX IF NOT EXISTS idx_system_alerts_type_opened
    ON hydromet.system_alerts (alert_type, opened_at DESC);

COMMIT;
