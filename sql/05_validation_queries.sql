-- ============================================
-- E-Commerce Cloud Analytics Pipeline
-- Script 05: Data Validation Queries
-- Purpose: Verify data integrity after pipeline
--          execution and data enrichment
-- ============================================

-- ==========================================
-- 1. Row Counts — Verify all data loaded
-- ==========================================

SELECT 'dim_customers' AS table_name, COUNT(*) AS row_count FROM dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'fact_orders', COUNT(*) FROM fact_orders
UNION ALL
SELECT 'stg_orders', COUNT(*) FROM stg_orders;

-- Expected Results:
-- dim_customers:  99,441
-- dim_products:   32,951
-- fact_orders:   112,650
-- stg_orders:     99,441

-- ==========================================
-- 2. NULL Check — Verify enrichment worked
-- ==========================================

SELECT 
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS rows_with_customer_id,
    COUNT(order_date) AS rows_with_order_date,
    COUNT(*) - COUNT(customer_id) AS null_customer_ids,
    COUNT(*) - COUNT(order_date) AS null_order_dates
FROM fact_orders;

-- Expected: null_customer_ids = 0, null_order_dates = 0

-- ==========================================
-- 3. Revenue Summary — Total revenue check
-- ==========================================

SELECT 
    SUM(price) AS total_revenue,
    SUM(freight_value) AS total_freight,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM fact_orders;

-- ==========================================
-- 4. Top 10 States by Revenue
-- ==========================================

SELECT TOP 10
    c.customer_state,
    SUM(f.price) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS order_count
FROM fact_orders f
INNER JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- Expected: SP leads with ~10.4M, followed by RJ (~3.6M), MG (~3.1M)

-- ==========================================
-- 5. Top 10 Product Categories by Revenue
-- ==========================================

SELECT TOP 10
    p.product_category,
    SUM(f.price) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS order_count
FROM fact_orders f
INNER JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_category
ORDER BY total_revenue DESC;

-- Expected: beleza_saude leads, followed by relogios_presentes

-- ==========================================
-- 6. Top 10 Cities by Revenue
-- ==========================================

SELECT TOP 10
    c.customer_city,
    c.customer_state,
    SUM(f.price) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS order_count
FROM fact_orders f
INNER JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_city, c.customer_state
ORDER BY total_revenue DESC;

-- Expected: sao paulo (SP) leads, followed by rio de janeiro (RJ)

-- ==========================================
-- 7. Monthly Revenue Trend
-- ==========================================

SELECT 
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(price) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS monthly_orders
FROM fact_orders
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;

-- ==========================================
-- 8. View Validation
-- ==========================================

SELECT 
    customer_state,
    SUM(price) AS total_revenue,
    COUNT(DISTINCT order_id) AS order_count
FROM vw_sales_dashboard
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- Should return 27 rows with unique revenue per state
