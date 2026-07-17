-- Verify the permanent parallel Nimbus test/production storage.
--
-- Expected:
--   - no rows from mismatch queries,
--   - both event tables are hypertables,
--   - idempotency ledger and ingest-state table exist,
--   - exactly one active Nimbus series and one active setup,
--   - no duplicate counter groups in either event table.

-- 1. Existence and hypertable status.
SELECT
    to_regclass('hydromet.event_observations') AS production_table,
    to_regclass('hydromet.rain_logger_test_events') AS test_table,
    to_regclass('hydromet.event_ingest_keys') AS dedup_ledger,
    to_regclass('hydromet.event_ingest_state') AS ingest_state;

SELECT
    hypertable_schema,
    hypertable_name,
    num_dimensions,
    num_chunks,
    compression_enabled
FROM timescaledb_information.hypertables
WHERE hypertable_schema = 'hydromet'
  AND hypertable_name IN (
      'event_observations',
      'rain_logger_test_events'
  )
ORDER BY hypertable_name;

-- 2. Exact column parity. Expected: no rows.
WITH production AS (
    SELECT
        ordinal_position,
        column_name,
        data_type,
        udt_name,
        is_nullable,
        column_default
    FROM information_schema.columns
    WHERE table_schema = 'hydromet'
      AND table_name = 'event_observations'
),
test AS (
    SELECT
        ordinal_position,
        column_name,
        data_type,
        udt_name,
        is_nullable,
        column_default
    FROM information_schema.columns
    WHERE table_schema = 'hydromet'
      AND table_name = 'rain_logger_test_events'
)
SELECT
    COALESCE(p.ordinal_position, t.ordinal_position) AS ordinal_position,
    p.column_name AS production_column,
    t.column_name AS test_column,
    p.data_type AS production_type,
    t.data_type AS test_type,
    p.udt_name AS production_udt,
    t.udt_name AS test_udt,
    p.is_nullable AS production_nullable,
    t.is_nullable AS test_nullable,
    p.column_default AS production_default,
    t.column_default AS test_default
FROM production p
FULL OUTER JOIN test t USING (ordinal_position)
WHERE ROW(
        p.column_name,
        p.data_type,
        p.udt_name,
        p.is_nullable,
        p.column_default
      )
      IS DISTINCT FROM
      ROW(
        t.column_name,
        t.data_type,
        t.udt_name,
        t.is_nullable,
        t.column_default
      )
ORDER BY ordinal_position;

-- 3. Primary-key column parity.
-- Expected: two rows, both with {time,event_id}.
SELECT
    c.relname AS table_name,
    array_agg(a.attname ORDER BY key_column.ordinality) AS primary_key_columns
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN LATERAL unnest(con.conkey)
    WITH ORDINALITY AS key_column(attnum, ordinality)
JOIN pg_attribute a
  ON a.attrelid = con.conrelid
 AND a.attnum = key_column.attnum
WHERE n.nspname = 'hydromet'
  AND c.relname IN (
      'event_observations',
      'rain_logger_test_events'
  )
  AND con.contype = 'p'
GROUP BY c.relname
ORDER BY c.relname;

-- 4. Foreign-key parity by referenced table/column.
SELECT
    source.relname AS source_table,
    source_col.attname AS source_column,
    target.relname AS target_table,
    target_col.attname AS target_column
FROM pg_constraint con
JOIN pg_class source ON source.oid = con.conrelid
JOIN pg_namespace source_ns ON source_ns.oid = source.relnamespace
JOIN pg_class target ON target.oid = con.confrelid
JOIN LATERAL unnest(con.conkey)
    WITH ORDINALITY AS source_key(attnum, ordinality) ON true
JOIN LATERAL unnest(con.confkey)
    WITH ORDINALITY AS target_key(attnum, ordinality)
    ON target_key.ordinality = source_key.ordinality
JOIN pg_attribute source_col
  ON source_col.attrelid = source.oid
 AND source_col.attnum = source_key.attnum
JOIN pg_attribute target_col
  ON target_col.attrelid = target.oid
 AND target_col.attnum = target_key.attnum
WHERE source_ns.nspname = 'hydromet'
  AND source.relname IN (
      'event_observations',
      'rain_logger_test_events'
  )
  AND con.contype = 'f'
ORDER BY source.relname, source_col.attname;

-- 5. Index shapes. Names differ; definitions should correspond.
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'hydromet'
  AND tablename IN (
      'event_observations',
      'rain_logger_test_events'
  )
ORDER BY tablename, indexname;

-- 6. Nimbus registry/setup.
SELECT
    s.series_id,
    s.series_key,
    s.observed_property,
    s.source_type,
    s.resolution_type,
    s.is_primary,
    s.is_active,
    s.is_test,
    ms.setup_id,
    ms.valid_from,
    ms.valid_to,
    ms.instrument_model,
    ms.sensor_type,
    ms.logger_type,
    ms.firmware
FROM hydromet.observation_series s
LEFT JOIN hydromet.measurement_setups ms
  ON ms.series_id = s.series_id
 AND ms.valid_to IS NULL
WHERE s.series_key =
    'rain.sannesholma.nimbus.rain_1.tb4_0p2';

-- 7. Target-specific ingest state.
-- Before AppDaemon has been enabled this may return no rows.
-- After both targets have established a baseline it should return two rows.
SELECT
    st.target_table,
    s.series_key,
    st.last_seen_pulse_total,
    st.last_boot_count,
    st.updated_at,
    st.metadata
FROM hydromet.event_ingest_state st
JOIN hydromet.observation_series s USING (series_id)
WHERE s.series_key =
    'rain.sannesholma.nimbus.rain_1.tb4_0p2'
ORDER BY st.target_table;

-- 8. Duplicate counter checks. Expected: no rows.
SELECT
    'production' AS target,
    series_id,
    event_type,
    counter,
    count(*) AS rows
FROM hydromet.event_observations
WHERE counter IS NOT NULL
GROUP BY series_id, event_type, counter
HAVING count(*) > 1

UNION ALL

SELECT
    'test' AS target,
    series_id,
    event_type,
    counter,
    count(*) AS rows
FROM hydromet.rain_logger_test_events
WHERE counter IS NOT NULL
GROUP BY series_id, event_type, counter
HAVING count(*) > 1
ORDER BY target, counter;

-- 9. Ledger duplicates are impossible by primary key, but inspect recent keys.
SELECT
    target_table,
    source_event_key,
    event_time,
    event_id,
    event_type,
    counter,
    created_at
FROM hydromet.event_ingest_keys
WHERE series_id = (
    SELECT series_id
    FROM hydromet.observation_series
    WHERE series_key =
        'rain.sannesholma.nimbus.rain_1.tb4_0p2'
)
ORDER BY created_at DESC
LIMIT 100;

-- 10. Recent Nimbus rows in both targets.
SELECT
    'production' AS target,
    e.time,
    e.received_at,
    e.event_id,
    e.event_type,
    e.value,
    e.unit,
    e.counter,
    e.quality_flag,
    e.metadata
FROM hydromet.event_observations e
JOIN hydromet.observation_series s USING (series_id)
WHERE s.series_key =
    'rain.sannesholma.nimbus.rain_1.tb4_0p2'

UNION ALL

SELECT
    'test' AS target,
    e.time,
    e.received_at,
    e.event_id,
    e.event_type,
    e.value,
    e.unit,
    e.counter,
    e.quality_flag,
    e.metadata
FROM hydromet.rain_logger_test_events e
JOIN hydromet.observation_series s USING (series_id)
WHERE s.series_key =
    'rain.sannesholma.nimbus.rain_1.tb4_0p2'
ORDER BY received_at DESC
LIMIT 100;
