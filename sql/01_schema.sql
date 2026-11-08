-- Rwanda Coffee Lot Traceability and Export Readiness
-- Run in a dedicated PostgreSQL database. All objects are contained in coffee_project.
CREATE SCHEMA IF NOT EXISTS coffee_project;
SET search_path TO coffee_project, public;

CREATE TABLE farmers (
    farmer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    farmer_code VARCHAR(12) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    district VARCHAR(50) NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE collection_points (
    collection_point_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    point_code VARCHAR(12) NOT NULL UNIQUE,
    point_name VARCHAR(100) NOT NULL,
    district VARCHAR(50) NOT NULL
);

CREATE TABLE coffee_lots (
    lot_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_code VARCHAR(18) NOT NULL UNIQUE,
    farmer_id BIGINT NOT NULL REFERENCES farmers(farmer_id),
    collection_point_id BIGINT NOT NULL REFERENCES collection_points(collection_point_id),
    received_date DATE NOT NULL,
    weight_kg NUMERIC(10,2) NOT NULL CHECK (weight_kg > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED'
       CHECK (status IN ('RECEIVED','GRADED','READY','REJECTED'))
);

CREATE TABLE grading_results (
    grade_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lot_id BIGINT NOT NULL UNIQUE REFERENCES coffee_lots(lot_id),
    graded_on DATE NOT NULL,
    quality_score NUMERIC(5,2) NOT NULL CHECK (quality_score BETWEEN 0 AND 100),
    grade_label VARCHAR(10) NOT NULL CHECK (grade_label IN ('A','B','C','REJECT')),
    grader_name VARCHAR(100) NOT NULL,
    notes TEXT
);

CREATE TABLE export_shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_code VARCHAR(18) NOT NULL UNIQUE,
    destination VARCHAR(70) NOT NULL,
    planned_date DATE NOT NULL,
    shipment_status VARCHAR(20) NOT NULL DEFAULT 'PLANNED'
      CHECK (shipment_status IN ('PLANNED','DISPATCHED','DELIVERED'))
);

CREATE TABLE shipment_lots (
    shipment_id BIGINT NOT NULL REFERENCES export_shipments(shipment_id),
    lot_id BIGINT NOT NULL UNIQUE REFERENCES coffee_lots(lot_id),
    allocated_kg NUMERIC(10,2) NOT NULL CHECK (allocated_kg > 0),
    PRIMARY KEY (shipment_id, lot_id)
);
-- Design choice: a lot belongs to at most one shipment; a shipment holds many lots.
-- Demo-only labels/scores are internal illustrative categories, NOT official Rwanda grading standards.
