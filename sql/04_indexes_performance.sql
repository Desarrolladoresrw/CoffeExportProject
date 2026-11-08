SET search_path TO coffee_project, public;

-- PERFORMANCE TUNING: baseline and post-index execution plans.
-- EXPLAIN ANALYZE executes SELECT. Do not use it on UPDATE/DELETE casually.
-- The small operational dataset may use Seq Scan even when indexes exist.

EXPLAIN (ANALYZE, BUFFERS)
SELECT l.lot_code,l.received_date,l.weight_kg
FROM coffee_lots l
WHERE l.collection_point_id = (
    SELECT collection_point_id FROM collection_points WHERE point_code='CP02'
)
AND l.received_date >= DATE '2026-10-01';

CREATE INDEX IF NOT EXISTS idx_coffee_lots_point_date
ON coffee_lots(collection_point_id, received_date);
CREATE INDEX IF NOT EXISTS idx_coffee_lots_status
ON coffee_lots(status);
CREATE INDEX IF NOT EXISTS idx_grading_grade_label
ON grading_results(grade_label);
-- Unique constraints already index farmer_code, point_code, lot_code and shipment_code.
ANALYZE coffee_lots;
ANALYZE grading_results;

EXPLAIN (ANALYZE, BUFFERS)
SELECT l.lot_code,l.received_date,l.weight_kg
FROM coffee_lots l
WHERE l.collection_point_id = (
    SELECT collection_point_id FROM collection_points WHERE point_code='CP02'
)
AND l.received_date >= DATE '2026-10-01';

-- Controlled scale experiment, deliberately separate from real project data.
-- Requires a few seconds and additional database space. Synthetic rows only.
CREATE TABLE IF NOT EXISTS perf_demo_lots (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  collection_point_id INT NOT NULL,
  received_date DATE NOT NULL,
  weight_kg NUMERIC(10,2) NOT NULL
);
INSERT INTO perf_demo_lots (collection_point_id,received_date,weight_kg)
SELECT 1 + (n % 100), DATE '2024-01-01' + ((n % 1000)::INT), 50 + (n % 500)
FROM generate_series(1,100000) AS n;
ANALYZE perf_demo_lots;

-- Capture these actual baseline metrics (timings and buffers) in pgAdmin.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id,received_date,weight_kg FROM perf_demo_lots
WHERE collection_point_id=42
  AND received_date >= DATE '2026-01-01';

CREATE INDEX idx_perf_point_date
ON perf_demo_lots(collection_point_id,received_date);
ANALYZE perf_demo_lots;

-- Compare with baseline. Plans and runtime depend on hardware and caching.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id,received_date,weight_kg FROM perf_demo_lots
WHERE collection_point_id=42
  AND received_date >= DATE '2026-01-01';

-- Read-only index inspection.
SELECT indexname,indexdef
FROM pg_indexes WHERE schemaname='coffee_project'
ORDER BY tablename,indexname;
