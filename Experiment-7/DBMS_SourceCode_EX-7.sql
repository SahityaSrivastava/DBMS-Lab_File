-- ============================================================================
-- EXPERIMENT - 7: Database Normalization (1NF, 2NF, 3NF, BCNF)
-- ============================================================================

-- Create the database if it does not already exist and switch to it
CREATE DATABASE IF NOT EXISTS SalesDB;
USE SalesDB;

-- Drop the Sales table if it already exists to start fresh
DROP TABLE IF EXISTS Sales;

-- Create the denormalized Sales table
CREATE TABLE Sales (
    sale_id INT, 
    sale_date DATE, 
    customer_id INT, 
    customer_name VARCHAR(50),
    salesperson_id INT, 
    salesperson_name VARCHAR(50), 
    product_id INT,
    product_name VARCHAR(50), 
    quantity INT
);

-- Insert sample sales records with redundant customer, salesperson, and product data
INSERT INTO Sales VALUES
(1001, '2026-01-10', 1, 'Aarav', 101, 'Rahul', 201, 'Laptop', 1),
(1001, '2026-01-10', 1, 'Aarav', 101, 'Rahul', 202, 'Mouse', 2),
(1002, '2026-01-11', 2, 'Diya', 102, 'Priya', 201, 'Laptop', 1),
(1002, '2026-01-11', 2, 'Diya', 102, 'Priya', 203, 'Keyboard', 1),
(1003, '2026-01-12', 1, 'Aarav', 101, 'Rahul', 202, 'Mouse', 3),
(1003, '2026-01-12', 1, 'Aarav', 101, 'Rahul', 204, 'Monitor', 1);

-- Retrieve and display all records from the denormalized Sales table
SELECT * FROM Sales;


-- Display the 1NF records ordered by the composite candidate key (sale_id, product_id)
SELECT 
    sale_id, 
    sale_date, 
    customer_id,
    customer_name,
    salesperson_id,
    salesperson_name,
    product_id, 
    product_name,
    quantity
FROM Sales
ORDER BY sale_id, product_id;


-- Create Sale_Header table to store attributes dependent only on sale_id
CREATE TABLE Sale_Header AS
SELECT DISTINCT 
    sale_id, 
    sale_date, 
    customer_id, 
    customer_name,
    salesperson_id, 
    salesperson_name
FROM Sales;

-- Create Product table to store attributes dependent only on product_id
CREATE TABLE Product AS
SELECT DISTINCT 
    product_id, 
    product_name
FROM Sales;

-- Create Sale_Item table to store attributes dependent on both sale_id and product_id
CREATE TABLE Sale_Item AS
SELECT 
    sale_id, 
    product_id, 
    quantity
FROM Sales;

-- Display the newly created 2NF tables
SELECT * FROM Sale_Header ORDER BY sale_id;
SELECT * FROM Product ORDER BY product_id;
SELECT * FROM Sale_Item ORDER BY sale_id, product_id;


-- Create Customer table to isolate customer_id -> customer_name dependency
CREATE TABLE Customer AS
SELECT DISTINCT 
    customer_id, 
    customer_name
FROM Sale_Header;

-- Create Salesperson table to isolate salesperson_id -> salesperson_name dependency
CREATE TABLE Salesperson AS
SELECT DISTINCT 
    salesperson_id, 
    salesperson_name
FROM Sale_Header;

-- Create the 3NF version of Sale_Header containing only foreign keys for customer and salesperson
CREATE TABLE Sale_Header_3NF AS
SELECT 
    sale_id, 
    sale_date, 
    customer_id, 
    salesperson_id
FROM Sale_Header;

-- Display the newly created 3NF tables
SELECT * FROM Customer ORDER BY customer_id;
SELECT * FROM Salesperson ORDER BY salesperson_id;
SELECT * FROM Sale_Header_3NF ORDER BY sale_id;


-- Query Customer records (Determinant: customer_id)
SELECT customer_id, customer_name
FROM Customer;

-- Query Salesperson records (Determinant: salesperson_id)
SELECT salesperson_id, salesperson_name
FROM Salesperson;

-- Query Product records (Determinant: product_id)
SELECT product_id, product_name
FROM Product;

-- Query 3NF Sale Header records (Determinant: sale_id)
SELECT sale_id, sale_date, customer_id, salesperson_id
FROM Sale_Header_3NF;

-- Query Sale Item records (Determinant: sale_id, product_id)
SELECT sale_id, product_id, quantity
FROM Sale_Item;


-- Reconstruct the original denormalized sales data using INNER JOINs across all 5 tables
SELECT 
    H.sale_id, 
    H.sale_date, 
    H.customer_id, 
    C.customer_name,
    H.salesperson_id, 
    SP.salesperson_name, 
    P.product_id, 
    P.product_name, 
    I.quantity
FROM Sale_Header_3NF H
JOIN Customer C ON H.customer_id = C.customer_id
JOIN Salesperson SP ON H.salesperson_id = SP.salesperson_id
JOIN Sale_Item I ON H.sale_id = I.sale_id
JOIN Product P ON I.product_id = P.product_id
ORDER BY H.sale_id, P.product_id;

-- Compare the total row count of the original table against the reconstructed join result
SELECT 
    (SELECT COUNT(*) FROM Sales) AS original_rows,
    (SELECT COUNT(*) 
     FROM Sale_Header_3NF H
     JOIN Customer C ON H.customer_id = C.customer_id
     JOIN Salesperson SP ON H.salesperson_id = SP.salesperson_id
     JOIN Sale_Item I ON H.sale_id = I.sale_id
     JOIN Product P ON I.product_id = P.product_id) AS reconstructed_rows;

-- Verify customer_id -> customer_name (each customer_id maps to exactly 1 customer_name)
SELECT customer_id, COUNT(DISTINCT customer_name) AS name_count
FROM Customer
GROUP BY customer_id;

-- Verify salesperson_id -> salesperson_name (each salesperson_id maps to exactly 1 salesperson_name)
SELECT salesperson_id, COUNT(DISTINCT salesperson_name) AS name_count
FROM Salesperson
GROUP BY salesperson_id;

-- Verify product_id -> product_name (each product_id maps to exactly 1 product_name)
SELECT product_id, COUNT(DISTINCT product_name) AS name_count
FROM Product
GROUP BY product_id;
