SET search_path TO coffee_project, public;

-- Safe demonstration of UPDATE and transaction rollback.
BEGIN;
UPDATE coffee_lots
SET status='GRADED'
WHERE lot_code='LOT-2026-006'
RETURNING lot_code,status;
ROLLBACK;
SELECT lot_code,status FROM coffee_lots WHERE lot_code='LOT-2026-006';

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
