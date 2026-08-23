-- ============================================================
-- CS306 Database Management Project
-- Project Title: Car Rental Search System
-- Data Source: Cornell Car Rental Dataset from Kaggle
-- Original CSV uploaded: CarRentalData.csv
--
-- This script is written for your real Kaggle CSV columns:
-- fuelType, rating, renterTripsTaken, reviewCount, location.city,
-- location.country, location.latitude, location.longitude, location.state,
-- owner.id, rate.daily, vehicle.make, vehicle.model, vehicle.type, vehicle.year
--
-- The project guidelines require MySQL and Metabase.
-- This database uses a raw Kaggle import table and then normalizes the data
-- into relational tables.
-- ============================================================

DROP DATABASE IF EXISTS car_rental_search_system;
CREATE DATABASE car_rental_search_system;
USE car_rental_search_system;

-- ============================================================
-- 1. RAW IMPORT TABLE
-- ============================================================
-- This table stores the original Kaggle data in a flat format.
-- It represents the original dataset before normalization.

CREATE TABLE raw_kaggle_car_rental_data (
    raw_id INT AUTO_INCREMENT PRIMARY KEY,
    fuel_type VARCHAR(50),
    rating DECIMAL(4,2),
    renter_trips_taken INT NOT NULL,
    review_count INT NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    state VARCHAR(100) NOT NULL,
    owner_id BIGINT NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    vehicle_make VARCHAR(100) NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    vehicle_year INT NOT NULL
);

-- ============================================================
-- 2. IMPORT YOUR CSV DATA
-- ============================================================
-- Recommended beginner method:
-- Use the cleaned CSV file I gave you:
-- CarRentalData_clean_headers.csv
--
-- In MySQL Workbench:
-- 1. Right-click raw_kaggle_car_rental_data.
-- 2. Click Table Data Import Wizard.
-- 3. Select CarRentalData_clean_headers.csv.
-- 4. Choose "Use existing table".
-- 5. Select raw_kaggle_car_rental_data.
-- 6. Match the columns.
-- 7. Finish import.
--
-- Alternative method using LOAD DATA:
-- Change the file path to the place where you saved the CSV on your computer.
--
-- LOAD DATA LOCAL INFILE 'C:/path/to/CarRentalData_clean_headers.csv'
-- INTO TABLE raw_kaggle_car_rental_data
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (fuel_type, rating, renter_trips_taken, review_count, city, country,
--  latitude, longitude, state, owner_id, daily_rate,
--  vehicle_make, vehicle_model, vehicle_type, vehicle_year);

-- ============================================================
-- IMPORTANT:
-- After importing the CSV, run the rest of this script.
-- ============================================================

-- ============================================================
-- 3. NORMALIZED TABLES
-- ============================================================
-- Minimum 5 tables are required by the project guidelines.
-- This design has 5 final normalized tables:
-- owners, locations, fuel_types, vehicle_types, vehicles

CREATE TABLE owners (
    owner_pk INT AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT NOT NULL UNIQUE
);

CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    UNIQUE (city, state, country, latitude, longitude)
);

CREATE TABLE fuel_types (
    fuel_type_id INT AUTO_INCREMENT PRIMARY KEY,
    fuel_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE vehicle_types (
    vehicle_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    owner_pk INT NOT NULL,
    location_id INT NOT NULL,
    fuel_type_id INT NULL,
    vehicle_type_id INT NOT NULL,
    vehicle_make VARCHAR(100) NOT NULL,
    vehicle_model VARCHAR(100) NOT NULL,
    vehicle_year INT NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    rating DECIMAL(4,2),
    review_count INT NOT NULL DEFAULT 0,
    renter_trips_taken INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_vehicle_owner
        FOREIGN KEY (owner_pk) REFERENCES owners(owner_pk)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_vehicle_location
        FOREIGN KEY (location_id) REFERENCES locations(location_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_vehicle_fuel
        FOREIGN KEY (fuel_type_id) REFERENCES fuel_types(fuel_type_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_vehicle_type
        FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types(vehicle_type_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_vehicle_daily_rate CHECK (daily_rate > 0),
    CONSTRAINT chk_vehicle_rating CHECK (rating IS NULL OR rating BETWEEN 0 AND 5),
    CONSTRAINT chk_vehicle_review_count CHECK (review_count >= 0),
    CONSTRAINT chk_vehicle_trips CHECK (renter_trips_taken >= 0),
    CONSTRAINT chk_vehicle_year CHECK (vehicle_year BETWEEN 1900 AND 2035)
);

-- ============================================================
-- 4. NORMALIZE DATA FROM RAW KAGGLE TABLE
-- ============================================================
-- These statements split the original Kaggle table into relational tables.

INSERT IGNORE INTO owners (owner_id)
SELECT DISTINCT owner_id
FROM raw_kaggle_car_rental_data
WHERE owner_id IS NOT NULL;

INSERT IGNORE INTO locations (city, state, country, latitude, longitude)
SELECT DISTINCT city, state, country, latitude, longitude
FROM raw_kaggle_car_rental_data
WHERE city IS NOT NULL
  AND state IS NOT NULL
  AND country IS NOT NULL
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

INSERT IGNORE INTO fuel_types (fuel_name)
SELECT DISTINCT fuel_type
FROM raw_kaggle_car_rental_data
WHERE fuel_type IS NOT NULL
  AND fuel_type <> '';

INSERT IGNORE INTO vehicle_types (type_name)
SELECT DISTINCT vehicle_type
FROM raw_kaggle_car_rental_data
WHERE vehicle_type IS NOT NULL
  AND vehicle_type <> '';

INSERT INTO vehicles (
    owner_pk,
    location_id,
    fuel_type_id,
    vehicle_type_id,
    vehicle_make,
    vehicle_model,
    vehicle_year,
    daily_rate,
    rating,
    review_count,
    renter_trips_taken
)
SELECT
    o.owner_pk,
    l.location_id,
    ft.fuel_type_id,
    vt.vehicle_type_id,
    r.vehicle_make,
    r.vehicle_model,
    r.vehicle_year,
    r.daily_rate,
    r.rating,
    r.review_count,
    r.renter_trips_taken
FROM raw_kaggle_car_rental_data r
JOIN owners o
    ON r.owner_id = o.owner_id
JOIN locations l
    ON r.city = l.city
   AND r.state = l.state
   AND r.country = l.country
   AND r.latitude = l.latitude
   AND r.longitude = l.longitude
JOIN vehicle_types vt
    ON r.vehicle_type = vt.type_name
LEFT JOIN fuel_types ft
    ON r.fuel_type = ft.fuel_name
WHERE r.vehicle_make IS NOT NULL
  AND r.vehicle_model IS NOT NULL
  AND r.vehicle_type IS NOT NULL
  AND r.vehicle_year IS NOT NULL
  AND r.daily_rate IS NOT NULL
  AND r.daily_rate > 0
  AND (r.rating IS NULL OR r.rating BETWEEN 0 AND 5)
  AND r.review_count >= 0
  AND r.renter_trips_taken >= 0;

-- ============================================================
-- 5. VIEW FOR EASY SEARCHING
-- ============================================================
-- This view combines the normalized tables so users can view complete car details.

CREATE VIEW vehicle_details_view AS
SELECT
    v.vehicle_id,
    o.owner_id,
    l.city,
    l.state,
    l.country,
    l.latitude,
    l.longitude,
    ft.fuel_name AS fuel_type,
    vt.type_name AS vehicle_type,
    v.vehicle_make,
    v.vehicle_model,
    v.vehicle_year,
    v.daily_rate,
    v.rating,
    v.review_count,
    v.renter_trips_taken
FROM vehicles v
JOIN owners o ON v.owner_pk = o.owner_pk
JOIN locations l ON v.location_id = l.location_id
JOIN vehicle_types vt ON v.vehicle_type_id = vt.vehicle_type_id
LEFT JOIN fuel_types ft ON v.fuel_type_id = ft.fuel_type_id;

-- ============================================================
-- 6. CRUD OPERATIONS
-- ============================================================
-- The guidelines require insert, update, delete, and view operations.

-- INSERT:
-- Insert a new fuel type example.
INSERT IGNORE INTO fuel_types (fuel_name)
VALUES ('UNKNOWN');

-- UPDATE:
-- Update missing fuel types to UNKNOWN if you want to avoid NULL in display.
UPDATE vehicles
SET fuel_type_id = (SELECT fuel_type_id FROM fuel_types WHERE fuel_name = 'UNKNOWN')
WHERE fuel_type_id IS NULL;

-- DELETE:
-- Insert a temporary owner and delete it.
INSERT INTO owners (owner_id)
VALUES (999999999);

DELETE FROM owners
WHERE owner_id = 999999999;

-- VIEW:
SELECT * FROM vehicle_details_view
LIMIT 100;

-- ============================================================
-- 7. SEARCH, FILTER, JOIN, SUBQUERY, AND ADVANCED QUERIES
-- ============================================================

-- Search vehicles by city.
SELECT
    vehicle_make,
    vehicle_model,
    vehicle_year,
    vehicle_type,
    fuel_type,
    daily_rate,
    rating,
    city,
    state
FROM vehicle_details_view
WHERE city = 'Seattle'
ORDER BY rating DESC;

-- Search vehicles by country and state.
SELECT
    vehicle_make,
    vehicle_model,
    city,
    state,
    country,
    daily_rate,
    rating
FROM vehicle_details_view
WHERE country = 'US'
  AND state = 'CA'
ORDER BY city;

-- Filter by fuel type.
SELECT
    vehicle_make,
    vehicle_model,
    fuel_type,
    daily_rate,
    rating
FROM vehicle_details_view
WHERE fuel_type = 'ELECTRIC'
ORDER BY daily_rate ASC;

-- Filter by vehicle type.
SELECT
    vehicle_make,
    vehicle_model,
    vehicle_type,
    daily_rate,
    rating
FROM vehicle_details_view
WHERE vehicle_type = 'suv'
ORDER BY rating DESC;

-- Filter by daily rate range.
SELECT
    vehicle_make,
    vehicle_model,
    daily_rate,
    rating
FROM vehicle_details_view
WHERE daily_rate BETWEEN 40 AND 100
ORDER BY daily_rate ASC;

-- Compare cars by rating, year, and price.
SELECT
    vehicle_make,
    vehicle_model,
    vehicle_year,
    fuel_type,
    vehicle_type,
    daily_rate,
    rating,
    review_count,
    renter_trips_taken
FROM vehicle_details_view
ORDER BY rating DESC, vehicle_year DESC, daily_rate ASC
LIMIT 50;

-- Special operator LIKE.
SELECT
    vehicle_make,
    vehicle_model,
    vehicle_year
FROM vehicle_details_view
WHERE vehicle_model LIKE '%Model%';

-- Subquery:
-- Find vehicles with above-average rating.
SELECT
    vehicle_make,
    vehicle_model,
    rating,
    daily_rate
FROM vehicle_details_view
WHERE rating > (
    SELECT AVG(rating)
    FROM vehicles
    WHERE rating IS NOT NULL
)
ORDER BY rating DESC;

-- JOIN query:
-- Show vehicles with owner and location data.
SELECT
    o.owner_id,
    v.vehicle_make,
    v.vehicle_model,
    l.city,
    l.state,
    l.country,
    v.daily_rate
FROM vehicles v
JOIN owners o ON v.owner_pk = o.owner_pk
JOIN locations l ON v.location_id = l.location_id
ORDER BY l.city;

-- Advanced query:
-- Average daily rate by make and vehicle type.
SELECT
    vehicle_make,
    vehicle_type,
    COUNT(vehicle_id) AS total_vehicles,
    ROUND(AVG(daily_rate), 2) AS average_daily_rate,
    ROUND(AVG(rating), 2) AS average_rating
FROM vehicle_details_view
GROUP BY vehicle_make, vehicle_type
HAVING COUNT(vehicle_id) >= 3
ORDER BY average_daily_rate DESC;

-- ============================================================
-- 8. METABASE REPORT QUERIES
-- ============================================================
-- Create these as SQL questions in Metabase.

-- REPORT 1:
-- Number of vehicles by city.
-- Chart: Bar chart.
SELECT
    city,
    COUNT(vehicle_id) AS total_vehicles
FROM vehicle_details_view
GROUP BY city
ORDER BY total_vehicles DESC
LIMIT 20;

-- REPORT 2:
-- Average daily rate by vehicle type.
-- Chart: Bar chart.
SELECT
    vehicle_type,
    ROUND(AVG(daily_rate), 2) AS average_daily_rate,
    COUNT(vehicle_id) AS total_vehicles
FROM vehicle_details_view
GROUP BY vehicle_type
ORDER BY average_daily_rate DESC;

-- REPORT 3:
-- Average rating by fuel type.
-- Chart: Bar chart.
SELECT
    fuel_type,
    ROUND(AVG(rating), 2) AS average_rating,
    COUNT(vehicle_id) AS total_vehicles
FROM vehicle_details_view
WHERE rating IS NOT NULL
GROUP BY fuel_type
ORDER BY average_rating DESC;

-- REPORT 4:
-- Total renter trips by state.
-- Chart: Bar chart.
SELECT
    state,
    SUM(renter_trips_taken) AS total_renter_trips,
    SUM(review_count) AS total_reviews,
    COUNT(vehicle_id) AS total_vehicles
FROM vehicle_details_view
GROUP BY state
ORDER BY total_renter_trips DESC
LIMIT 20;

-- REPORT 5:
-- Average daily rate by vehicle make.
-- Chart: Bar chart.
SELECT
    vehicle_make,
    COUNT(vehicle_id) AS total_vehicles,
    ROUND(AVG(daily_rate), 2) AS average_daily_rate
FROM vehicle_details_view
GROUP BY vehicle_make
HAVING COUNT(vehicle_id) >= 5
ORDER BY average_daily_rate DESC
LIMIT 20;

-- ============================================================
-- 9. FINAL CHECK QUERIES
-- ============================================================

SELECT COUNT(*) AS raw_rows_imported FROM raw_kaggle_car_rental_data;
SELECT COUNT(*) AS total_owners FROM owners;
SELECT COUNT(*) AS total_locations FROM locations;
SELECT COUNT(*) AS total_fuel_types FROM fuel_types;
SELECT COUNT(*) AS total_vehicle_types FROM vehicle_types;
SELECT COUNT(*) AS total_vehicles FROM vehicles;

SELECT * FROM vehicle_details_view LIMIT 100;
