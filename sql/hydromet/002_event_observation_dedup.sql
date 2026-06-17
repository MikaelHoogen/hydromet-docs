-- Hydromet event observation deduplication
--
-- Purpose:
--   Prevent the same counter-based event from being stored twice.
--
-- Background:
--   MQTT messages may theoretically be delivered more than once.
--   For tipping-bucket rain events, the monotonic pulse counter is a better
--   duplicate guard than timestamp alone.
--
-- Important:
--   This migration does not modify or delete any rows.
--   It only adds a partial unique index for events with a non-null counter.

BEGIN;

CREATE UNIQUE INDEX IF NOT EXISTS uq_event_observations_series_event_counter
    ON hydromet.event_observations (series_id, event_type, counter)
    WHERE counter IS NOT NULL;

COMMIT;
