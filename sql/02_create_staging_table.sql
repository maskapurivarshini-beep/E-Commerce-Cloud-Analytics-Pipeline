-- ============================================
-- E-Commerce Cloud Analytics Pipeline
-- Script 02: Create Staging Table for Orders
-- Purpose: Temporarily holds orders data for
--          enriching fact_orders with customer_id
--          and order_date via UPDATE JOIN
-- ============================================

CREATE TABLE stg_orders (
    order_id NVARCHAR(50),
    customer_id NVARCHAR(50),
    order_status NVARCHAR(20),
    order_purchase_timestamp NVARCHAR(50),
    order_approved_at NVARCHAR(50),
    order_delivered_carrier_date NVARCHAR(50),
    order_delivered_customer_date NVARCHAR(50),
    order_estimated_delivery_date NVARCHAR(50)
);
