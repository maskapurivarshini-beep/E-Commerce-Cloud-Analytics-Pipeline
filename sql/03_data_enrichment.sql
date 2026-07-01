-- ============================================
-- E-Commerce Cloud Analytics Pipeline
-- Script 03: Data Enrichment
-- Purpose: Populate customer_id and order_date
--          in fact_orders from staging table
-- ============================================

-- Problem:
-- The olist_order_items_dataset.csv (source for fact_orders)
-- does not contain customer_id or order_date.
-- These fields exist in olist_orders_dataset.csv (loaded into stg_orders).
-- After the initial ADF pipeline run, fact_orders had NULL values
-- in customer_id and order_date columns.

-- Solution:
-- UPDATE JOIN using order_id as the matching key

UPDATE f
SET f.customer_id = s.customer_id,
    f.order_date = CAST(LEFT(s.order_purchase_timestamp, 10) AS DATE)
FROM fact_orders f
INNER JOIN stg_orders s ON f.order_id = s.order_id;

-- Result: 112,650 rows updated with real customer IDs and dates

-- Verify the fix worked
SELECT TOP 10 
    order_id, 
    customer_id, 
    order_date, 
    price 
FROM fact_orders
WHERE customer_id IS NOT NULL
ORDER BY order_date DESC;
