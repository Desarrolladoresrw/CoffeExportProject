-- Run only AFTER the full script completed, as a separate Query Tool execution.
SET search_path TO coffee_project, public;
BEGIN;
UPDATE coffee_lots SET status='GRADED'
WHERE lot_code='LOT-2026-006'
RETURNING lot_code,status;
ROLLBACK;
SELECT lot_code,status FROM coffee_project.coffee_lots WHERE lot_code='LOT-2026-006';
