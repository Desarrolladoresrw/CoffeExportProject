SET search_path TO coffee_project, public;
INSERT INTO farmers (farmer_code,full_name,district,phone) VALUES
('F001','Aline Mukamana','Huye','0788000001'),
('F002','Jean Nkurunziza','Nyamasheke','0788000002'),
('F003','Grace Uwase','Karongi','0788000003'),
('F004','Patrick Habimana','Huye','0788000004'),
('F005','Diane Uwera','Rusizi','0788000005'),
('F006','Eric Mugisha','Nyamasheke','0788000006');
INSERT INTO collection_points (point_code,point_name,district) VALUES
('CP01','Huye Central Collection','Huye'),
('CP02','Nyamasheke Hills Point','Nyamasheke'),
('CP03','Karongi Lakeside Point','Karongi');

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
JOIN collection_points p ON p.point_code=v.point_code;

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
JOIN coffee_lots l ON l.lot_code=v.lot_code;

INSERT INTO export_shipments (shipment_code,destination,planned_date,shipment_status) VALUES
('EXP-2026-001','Netherlands',DATE '2026-11-12','PLANNED'),
('EXP-2026-002','Germany',DATE '2026-11-20','PLANNED');

INSERT INTO shipment_lots (shipment_id,lot_id,allocated_kg)
SELECT s.shipment_id,l.lot_id,l.weight_kg
FROM (VALUES
('EXP-2026-001','LOT-2026-001'),
('EXP-2026-001','LOT-2026-002'),
('EXP-2026-002','LOT-2026-005')
) AS v(shipment_code,lot_code)
JOIN export_shipments s ON s.shipment_code=v.shipment_code
JOIN coffee_lots l ON l.lot_code=v.lot_code;

SELECT 'farmers' AS entity, COUNT(*) AS records FROM farmers
UNION ALL SELECT 'collection_points',COUNT(*) FROM collection_points
UNION ALL SELECT 'coffee_lots',COUNT(*) FROM coffee_lots
UNION ALL SELECT 'grading_results',COUNT(*) FROM grading_results
UNION ALL SELECT 'export_shipments',COUNT(*) FROM export_shipments
UNION ALL SELECT 'shipment_lots',COUNT(*) FROM shipment_lots;
