-- ALL-IN-ONE POSTGRESQL SCRIPT (safe to rerun in the project database)
-- Execute with pgAdmin 4 Query Tool connected to RwandaExportCoffee_Project.
-- No explicit ROLLBACK inside this combined execution. Existing project rows are retained.

-- Rwanda Coffee Lot Traceability and Export Readiness
-- Run in a dedicated PostgreSQL database. All objects are contained in coffee_project.
CREATE SCHEMA IF NOT EXISTS coffee_project;
SET search_path TO coffee_project, public;

CREATE TABLE IF NOT EXISTS farmers (
    farmer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    farmer_code VARCHAR(12) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    district VARCHAR(50) NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS collection_points (
    collection_point_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    point_code VARCHAR(12) NOT NULL UNIQUE,
    point_name VARCHAR(100) NOT NULL,
    district VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS coffee_lots (
    lot_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_code VARCHAR(18) NOT NULL UNIQUE,
    farmer_id BIGINT NOT NULL REFERENCES farmers(farmer_id),
    collection_point_id BIGINT NOT NULL REFERENCES collection_points(collection_point_id),
    received_date DATE NOT NULL,
    weight_kg NUMERIC(10,2) NOT NULL CHECK (weight_kg > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED'
       CHECK (status IN ('RECEIVED','GRADED','READY','REJECTED'))
);

CREATE TABLE IF NOT EXISTS grading_results (
    grade_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_id BIGINT NOT NULL UNIQUE REFERENCES coffee_lots(lot_id),
    graded_on DATE NOT NULL,
    quality_score NUMERIC(5,2) NOT NULL CHECK (quality_score BETWEEN 0 AND 100),
    grade_label VARCHAR(10) NOT NULL CHECK (grade_label IN ('A','B','C','REJECT')),
    grader_name VARCHAR(100) NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS export_shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_code VARCHAR(18) NOT NULL UNIQUE,
    destination VARCHAR(70) NOT NULL,
    planned_date DATE NOT NULL,
    shipment_status VARCHAR(20) NOT NULL DEFAULT 'PLANNED'
      CHECK (shipment_status IN ('PLANNED','DISPATCHED','DELIVERED'))
);

CREATE TABLE IF NOT EXISTS shipment_lots (
    shipment_id BIGINT NOT NULL REFERENCES export_shipments(shipment_id),
    lot_id BIGINT NOT NULL UNIQUE REFERENCES coffee_lots(lot_id),
    allocated_kg NUMERIC(10,2) NOT NULL CHECK (allocated_kg > 0),
    PRIMARY KEY (shipment_id, lot_id)
);
-- Design choice: a lot belongs to at most one shipment; a shipment holds many lots.
-- Demo-only labels/scores are internal illustrative categories, NOT official Rwanda grading standards.


SET search_path TO coffee_project, public;
INSERT INTO farmers (farmer_code,full_name,district,phone) VALUES
('F001','Aline Mukamana','Huye','0788000001'),
('F002','Jean Nkurunziza','Nyamasheke','0788000002'),
('F003','Grace Uwase','Karongi','0788000003'),
('F004','Patrick Habimana','Huye','0788000004'),
('F005','Diane Uwera','Rusizi','0788000005'),
('F006','Eric Mugisha','Nyamasheke','0788000006')
ON CONFLICT (farmer_code) DO NOTHING;
INSERT INTO collection_points (point_code,point_name,district) VALUES
('CP01','Huye Central Collection','Huye'),
('CP02','Nyamasheke Hills Point','Nyamasheke'),
('CP03','Karongi Lakeside Point','Karongi')
ON CONFLICT (point_code) DO NOTHING;

-- Look up parent IDs through business codes: no assumptions about identity sequence values.
INSERT INTO coffee_lots (lot_code,farmer_id,collection_point_id,received_date,weight_kg,status)
SELECT v.lot_code,f.farmer_id,p.collection_point_id,v.received_date,v.weight_kg,v.status
FROM (VALUES
('LOT-2026-001','F001','CP01',DATE '2026-10-05',350.00,'READY'),
('LOT-2026-002','F002','CP02',DATE '2026-10-06',420.00,'READY'),
('LOT-2026-003','F003','CP03',DATE '2026-10-07',280.00,'GRADED'),
('LOT-2026-004','F004','CP01',DATE '2026-10-08',300.00,'REJECTED'),
('LOT-2026-005','F005','CP02',DATE '2026-10-09',510.00,'READY'),
('LOT-2026-006','F006','CP02',DATE '2026-10-10',215.00,'RECEIVED'),
('LOT-2026-007','F001','CP01',DATE '2026-10-11',260.00,'READY'),
('LOT-2026-008','F003','CP03',DATE '2026-10-12',190.00,'GRADED')
) AS v(lot_code,farmer_code,point_code,received_date,weight_kg,status)
JOIN farmers f ON f.farmer_code=v.farmer_code
JOIN collection_points p ON p.point_code=v.point_code
WHERE TRUE
ON CONFLICT (lot_code) DO NOTHING;

INSERT INTO grading_results (lot_id,graded_on,quality_score,grade_label,grader_name,notes)
SELECT l.lot_id,v.graded_on,v.quality_score,v.grade_label,'M. Niyonsenga',v.notes
FROM (VALUES
('LOT-2026-001',DATE '2026-10-06',89.50,'A','Approved for shipment'),
('LOT-2026-002',DATE '2026-10-07',84.00,'B','Approved for shipment'),
('LOT-2026-003',DATE '2026-10-08',78.00,'C','Review packaging'),
('LOT-2026-004',DATE '2026-10-09',55.00,'REJECT','Moisture concern'),
('LOT-2026-005',DATE '2026-10-10',91.00,'A','Approved for shipment'),
('LOT-2026-007',DATE '2026-10-12',86.00,'B','Approved for shipment'),
('LOT-2026-008',DATE '2026-10-13',81.00,'B','Awaiting readiness review')
) AS v(lot_code,graded_on,quality_score,grade_label,notes)
JOIN coffee_lots l ON l.lot_code=v.lot_code
WHERE TRUE
ON CONFLICT (lot_id) DO NOTHING;

INSERT INTO export_shipments (shipment_code,destination,planned_date,shipment_status) VALUES
('EXP-2026-001','Netherlands',DATE '2026-11-12','PLANNED'),
('EXP-2026-002','Germany',DATE '2026-11-20','PLANNED')
ON CONFLICT (shipment_code) DO NOTHING;

INSERT INTO shipment_lots (shipment_id,lot_id,allocated_kg)
SELECT s.shipment_id,l.lot_id,l.weight_kg
FROM (VALUES
('EXP-2026-001','LOT-2026-001'),
('EXP-2026-001','LOT-2026-002'),
('EXP-2026-002','LOT-2026-005')
) AS v(shipment_code,lot_code)
JOIN export_shipments s ON s.shipment_code=v.shipment_code
JOIN coffee_lots l ON l.lot_code=v.lot_code
WHERE TRUE
ON CONFLICT (lot_id) DO NOTHING;

SELECT 'farmers' AS entity, COUNT(*) AS records FROM farmers
UNION ALL SELECT 'collection_points',COUNT(*) FROM collection_points
UNION ALL SELECT 'coffee_lots',COUNT(*) FROM coffee_lots
UNION ALL SELECT 'grading_results',COUNT(*) FROM grading_results
UNION ALL SELECT 'export_shipments',COUNT(*) FROM export_shipments
UNION ALL SELECT 'shipment_lots',COUNT(*) FROM shipment_lots;


SET search_path TO coffee_project, public;

-- Report 1: Trace a coffee lot back to its farmer and collection point.
SELECT l.lot_code, f.full_name AS farmer, f.district AS farmer_district,
       p.point_name, l.received_date, l.weight_kg, l.status
FROM coffee_lots l
INNER JOIN farmers f ON f.farmer_id=l.farmer_id
INNER JOIN collection_points p ON p.collection_point_id=l.collection_point_id
ORDER BY l.received_date, l.lot_code;

-- Report 2: LEFT JOIN retains ungraded lots, showing why they need attention.
SELECT l.lot_code, l.status, g.quality_score, g.grade_label
FROM coffee_lots l
LEFT JOIN grading_results g ON g.lot_id=l.lot_id
ORDER BY l.lot_code;

-- Report 3: CTE summarizes weight by point and counts lots.
WITH point_totals AS (
  SELECT p.collection_point_id,p.point_name,COUNT(l.lot_id) AS lot_count,
         COALESCE(SUM(l.weight_kg),0) AS total_kg
  FROM collection_points p
  LEFT JOIN coffee_lots l ON l.collection_point_id=p.collection_point_id
  GROUP BY p.collection_point_id,p.point_name
)
SELECT point_name,lot_count,total_kg
FROM point_totals ORDER BY total_kg DESC;

-- Report 4: CTE identifies eligible export lots (business rule for this demo).
WITH eligible_lots AS (
 SELECT l.lot_code,l.weight_kg,g.grade_label
 FROM coffee_lots l
 JOIN grading_results g ON g.lot_id=l.lot_id
 LEFT JOIN shipment_lots sl ON sl.lot_id=l.lot_id
 WHERE l.status='READY' AND g.grade_label IN ('A','B')
   AND sl.lot_id IS NULL
)
SELECT * FROM eligible_lots ORDER BY weight_kg DESC;

-- View 1: reusable overview of the lot's path.
CREATE OR REPLACE VIEW vw_lot_traceability AS
SELECT l.lot_id,l.lot_code,f.farmer_code,f.full_name AS farmer,
       p.point_code,p.point_name,l.received_date,l.weight_kg,l.status,
       g.quality_score,g.grade_label,
       s.shipment_code,s.destination,s.shipment_status
FROM coffee_lots l
JOIN farmers f ON f.farmer_id=l.farmer_id
JOIN collection_points p ON p.collection_point_id=l.collection_point_id
LEFT JOIN grading_results g ON g.lot_id=l.lot_id
LEFT JOIN shipment_lots sl ON sl.lot_id=l.lot_id
LEFT JOIN export_shipments s ON s.shipment_id=sl.shipment_id;

-- View 2: shipment summary, including shipments with no assigned lots.
CREATE OR REPLACE VIEW vw_shipment_summary AS
SELECT s.shipment_code,s.destination,s.planned_date,s.shipment_status,
       COUNT(sl.lot_id) AS lot_count,
       COALESCE(SUM(sl.allocated_kg),0) AS shipment_kg
FROM export_shipments s
LEFT JOIN shipment_lots sl ON sl.shipment_id=s.shipment_id
GROUP BY s.shipment_id,s.shipment_code,s.destination,s.planned_date,s.shipment_status;

SELECT * FROM vw_lot_traceability ORDER BY lot_code;
SELECT * FROM vw_shipment_summary ORDER BY shipment_code;

-- Verification: no lot allocated more than its recorded weight.
SELECT l.lot_code,sl.allocated_kg,l.weight_kg
FROM shipment_lots sl
JOIN coffee_lots l ON l.lot_id=sl.lot_id
WHERE sl.allocated_kg > l.weight_kg;
-- Expected: zero rows with supplied data.


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
FROM generate_series(1,100000) AS n
WHERE NOT EXISTS (SELECT 1 FROM perf_demo_lots);
ANALYZE perf_demo_lots;

-- Capture these actual baseline metrics (timings and buffers) in pgAdmin.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id,received_date,weight_kg FROM perf_demo_lots
WHERE collection_point_id=42
  AND received_date >= DATE '2026-01-01';

CREATE INDEX IF NOT EXISTS idx_perf_point_date
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


SET search_path TO coffee_project, public;

-- Read-only demonstration of what an UPDATE would change.
-- Run the separate transaction demonstration file if you want to practice ROLLBACK.
SELECT lot_code, status AS current_status,
       'GRADED'::VARCHAR(20) AS proposed_status
FROM coffee_lots
WHERE lot_code='LOT-2026-006';

-- Data-integrity check: all shipment allocations should refer to READY lots.
SELECT l.lot_code,l.status,s.shipment_code
FROM shipment_lots sl
JOIN coffee_lots l ON l.lot_id=sl.lot_id
JOIN export_shipments s ON s.shipment_id=sl.shipment_id
WHERE l.status <> 'READY';

-- The unique constraint on shipment_lots(lot_id) stops a lot from being
-- placed into more than one shipment, but this is a business convention.
-- This demo does not enforce grade/status/allocated-weight cross-table rules
-- with triggers; the checks above detect inconsistent data.

-- FINAL EXISTENCE AND COUNT CHECK (should show six operational tables)
SELECT 'farmers' AS table_name, COUNT(*) AS row_count FROM coffee_project.farmers
UNION ALL SELECT 'collection_points', COUNT(*) FROM coffee_project.collection_points
UNION ALL SELECT 'coffee_lots', COUNT(*) FROM coffee_project.coffee_lots
UNION ALL SELECT 'grading_results', COUNT(*) FROM coffee_project.grading_results
UNION ALL SELECT 'export_shipments', COUNT(*) FROM coffee_project.export_shipments
UNION ALL SELECT 'shipment_lots', COUNT(*) FROM coffee_project.shipment_lots
ORDER BY table_name;