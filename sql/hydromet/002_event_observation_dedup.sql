-- Hydromet event observation identity and deduplication
--
-- Purpose:
--   1. Allow more than one event for the same series and event_type in one second.
--   2. Keep hydromet.event_observations as a TimescaleDB hypertable.
--   3. Provide database-backed idempotency without an invalid unique hypertable
--      index on (series_id, event_type, counter).
--
-- Actual database state observed 2026-07-17:
--   - hydromet.event_observations exists and is a hypertable.
--   - it contains only two old proof-of-concept rows.
--   - the old UNIQUE counter migration has not been applied.
--
-- This migration preserves existing rows. It does not touch public.*.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS timescaledb;

ALTER TABLE hydromet.event_observations
    ADD COLUMN IF NOT EXISTS event_id uuid;

UPDATE hydromet.event_observations
SET event_id = gen_random_uuid()
WHERE event_id IS NULL;

ALTER TABLE hydromet.event_observations
    ALTER COLUMN event_id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN event_id SET NOT NULL;

-- Replace the old PK (time, series_id, event_type) with a Timescale-compatible
-- identity that permits multiple real tips in the same second.
DO $$
DECLARE
    pk_name text;
    pk_columns text[];
BEGIN
    SELECT
        c.conname,
        array_agg(a.attname ORDER BY key_column.ordinality)
    INTO pk_name, pk_columns
    FROM pg_constraint c
    CROSS JOIN LATERAL unnest(c.conkey)
        WITH ORDINALITY AS key_column(attnum, ordinality)
    JOIN pg_attribute a
      ON a.attrelid = c.conrelid
     AND a.attnum = key_column.attnum
    WHERE c.conrelid = 'hydromet.event_observations'::regclass
      AND c.contype = 'p'
    GROUP BY c.conname;

    IF pk_name IS NOT NULL
       AND pk_columns IS DISTINCT FROM ARRAY['time', 'event_id']::text[] THEN
        EXECUTE format(
            'ALTER TABLE hydromet.event_observations DROP CONSTRAINT %I',
            pk_name
        );
        pk_name := NULL;
    END IF;

    IF pk_name IS NULL THEN
        ALTER TABLE hydromet.event_observations
            ADD CONSTRAINT event_observations_pkey
            PRIMARY KEY (time, event_id);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'hydromet.event_observations'::regclass
          AND conname = 'event_observations_counter_nonnegative'
    ) THEN
        ALTER TABLE hydromet.event_observations
            ADD CONSTRAINT event_observations_counter_nonnegative
            CHECK (counter IS NULL OR counter >= 0);
    END IF;
END
$$;

-- The previous repository draft attempted a UNIQUE index that omitted time.
-- Such an index is not valid for a hypertable partitioned on time.
DROP INDEX IF EXISTS hydromet.uq_event_observations_series_event_counter;

CREATE INDEX IF NOT EXISTS idx_event_observations_counter
    ON hydromet.event_observations (series_id, event_type, counter)
    WHERE counter IS NOT NULL;

-- Regular PostgreSQL ledger used transactionally with either event target.
-- target_table makes test and production idempotency completely separate.
CREATE TABLE IF NOT EXISTS hydromet.event_ingest_keys (
    target_table     text NOT NULL,
    source_event_key text NOT NULL,

    event_time       timestamptz NOT NULL,
    event_id         uuid NOT NULL,

    series_id        uuid NOT NULL
                     REFERENCES hydromet.observation_series(series_id),
    event_type       text NOT NULL,
    counter          bigint,

    created_at       timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (target_table, source_event_key),

    CONSTRAINT event_ingest_keys_target_table_not_blank
        CHECK (length(trim(target_table)) > 0),

    CONSTRAINT event_ingest_keys_source_event_key_not_blank
        CHECK (length(trim(source_event_key)) > 0),

    CONSTRAINT event_ingest_keys_event_type_not_blank
        CHECK (length(trim(event_type)) > 0),

    CONSTRAINT event_ingest_keys_counter_nonnegative
        CHECK (counter IS NULL OR counter >= 0)
);

CREATE INDEX IF NOT EXISTS idx_event_ingest_keys_series_counter
    ON hydromet.event_ingest_keys (
        target_table,
        series_id,
        event_type,
        counter
    )
    WHERE counter IS NOT NULL;

COMMENT ON COLUMN hydromet.event_observations.event_id IS
'Database event identity. Together with time it forms the Timescale-compatible primary key.';

COMMENT ON TABLE hydromet.event_ingest_keys IS
'Regular PostgreSQL idempotency ledger for event hypertables. Test and production are separated by target_table.';

COMMIT;
