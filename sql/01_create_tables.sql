-- ============================================
-- E-Commerce Cloud Analytics Pipeline
-- Script 01: Create Star Schema Tables
-- Database: ecommerce-analytics-db
-- Author: Varshini Maskapuri
-- Date: April 2026
-- ============================================

-- Dimension Table: Products
CREATE TABLE dim_products (
    product_id NVARCHAR(50) PRIMARY KEY,
    product_category NVARCHAR(100)
);

-- Dimension Table: Customers
CREATE TABLE dim_customers (
    customer_id NVARCHAR(50) PRIMARY KEY,
    customer_city NVARCHAR(100),
    customer_state NVARCHAR(10)
);

-- Dimension Table: Calendar (for future time intelligence)
CREATE TABLE dim_calendar (
    date_key DATE PRIMARY KEY,
    day_of_week INT,
    month_num INT,
    month_name NVARCHAR(20),
    quarter INT,
    year INT
);

-- Fact Table: Orders
CREATE TABLE fact_orders (
    order_id NVARCHAR(50),
    product_id NVARCHAR(50),
    customer_id NVARCHAR(50),
    order_date DATE,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    total_amount DECIMAL(10,2)
);
