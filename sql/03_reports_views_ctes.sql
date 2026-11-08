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
