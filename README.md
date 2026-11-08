# Rwanda Coffee Export Cooperative
## Coffee Lot Traceability, Export Readiness & SQL Performance Tuning

**Database:** `RwandaExportCoffee_Project` (use the database name on your own pgAdmin if different)  
**Schema:** `coffee_project`  
**Technology:** PostgreSQL 18, pgAdmin 4  
**Status:** classroom prototype using illustrative/sample records; not a deployed production system.

### Problem
A coffee cooperative needs to connect farmer deliveries, collection points, quality grades and export shipment allocations. Separate records make it hard to answer where a lot came from, whether it is ready, and where it will go.

### Solution
A relational PostgreSQL database using six operational tables, foreign keys, JOIN reports, two common table expressions (CTEs), two reusable views, and indexes. A separate synthetic performance table is used to compare query plans with `EXPLAIN (ANALYZE, BUFFERS)`.

### Tables
| Table | Role |
|---|---|
| `farmers` | Farmer identity and district |
| `collection_points` | Sites accepting coffee deliveries |
| `coffee_lots` | Batch origin, collection point, weight, status |
| `grading_results` | One quality assessment per lot in this prototype |
| `export_shipments` | Planned destination, date and shipment status |
| `shipment_lots` | Assignment of a lot to at most one shipment, with allocated weight |

`perf_demo_lots` contains **100,000 synthetic test rows**; it is not an operational lot table.

### Run the complete project
1. In pgAdmin select the existing project database (`RwandaExportCoffee_Project`). **Do not run in ULK_Database or postgres by accident.**
2. Open Query Tool, open `sql/00_ALL_IN_ONE_CORRECTED.sql`, and execute as one script.
3. The script creates the schema, tables, sample data, reports, CTEs, views, indexes and performance demo. It deliberately does **not** include a `ROLLBACK` that would undo the setup.
4. Verify the counts:

```sql
SELECT 'farmers' AS entity, COUNT(*) FROM coffee_project.farmers
UNION ALL SELECT 'collection_points', COUNT(*) FROM coffee_project.collection_points
UNION ALL SELECT 'coffee_lots', COUNT(*) FROM coffee_project.coffee_lots
UNION ALL SELECT 'grading_results', COUNT(*) FROM coffee_project.grading_results
UNION ALL SELECT 'export_shipments', COUNT(*) FROM coffee_project.export_shipments
UNION ALL SELECT 'shipment_lots', COUNT(*) FROM coffee_project.shipment_lots;
```

Expected from a fresh setup: **6 farmers, 3 collection points, 8 coffee lots, 7 grading results, 2 shipments, 3 allocations**. Existing project records can produce different counts.

### Repository contents
- `sql/00_ALL_IN_ONE_CORRECTED.sql` — **canonical latest script**, copied from the SQL you uploaded
- `sql/01_schema.sql` to `05_safe_demonstrations.sql` — teaching-oriented individual scripts from the prior package; **do not execute these after the all-in-one**, as some actions are not intended for repeated execution
- `sql/06_rollback_demo_RUN_SEPARATELY.sql` — separate transaction lesson, never part of bulk setup
- `diagrams/pgadmin_erd_uploaded.jpg` — ERD screenshot supplied by the group
- `diagrams/coffee_relationships.mmd` — reproducible Mermaid relationship diagram
- `docs/` — table explanation, study notes, performance evidence template and Git instructions
- `slides/` — presentation
- `evidence/` — place your own pgAdmin screenshots/timing outputs here

### Demonstrate these SQL features
- **PK/FK/UNIQUE/CHECK/IDENTITY:** in `sql/00_ALL_IN_ONE_CORRECTED.sql`
- **JOINs:** trace farmer/point and show ungraded lots
- **CTEs:** total weights by collection point and eligible ready-to-export lots
- **Views:** `vw_lot_traceability`, `vw_shipment_summary`
- **Indexes:** `idx_coffee_lots_point_date`, `idx_coffee_lots_status`, `idx_grading_grade_label`, `idx_perf_point_date`
- **Performance:** compare actual `EXPLAIN (ANALYZE, BUFFERS)` plans; no predetermined speed improvement is claimed

### Caveats / limitations
- Illustrative grades, statuses and shipment allocations are **not** official Rwanda grading or export compliance criteria.
- The database uses a simplified one-lot-at-most-one-shipment rule.
- Ready/grade and allocated-weight checks are reporting queries, not enforcement triggers.
- The ERD JPG is the uploaded visual and may not clearly display connection lines at its current zoom. Use the `.mmd` relationship source or re-export the pgAdmin ERD with visible connectors before submission.
- Do not commit passwords, `.env` files, local database dumps containing personal data, or GitHub tokens.

### Before submitting
Run the project locally, capture accurate performance observations in `docs/PERFORMANCE_RESULTS.md`, add the annotated ERD and actual screenshots to `evidence/`, update group names if needed, and push to your **assigned class GitHub organization repository** using `docs/GIT_BASH_UPLOAD.md`.
