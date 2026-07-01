-- ============================================
-- E-Commerce Cloud Analytics Pipeline
-- Script 04: Create SQL View for Power BI
-- Purpose: Pre-join fact and dimension tables
--          into a single denormalized view for
--          optimized Power BI reporting
-- ============================================

-- Problem:
-- Power BI Web's Star Schema relationships between
-- fact_orders and dim_customers did not filter correctly.
-- Regional breakdown visuals showed the same total revenue
-- for every state instead of filtering per state.

-- Solution:
-- Create a pre-joined SQL view that eliminates the need
-- for relationship-based filtering in Power BI.
-- This is a common real-world pattern when the BI tool's
-- relationship engine doesn't handle certain join patterns well.

CREATE VIEW vw_sales_dashboard AS
SELECT 
    f.order_id,
    f.order_date,
    f.price,
    f.freight_value,
    c.customer_city,
    c.customer_state,
    p.product_category
FROM fact_orders f
LEFT JOIN dim_customers c ON f.customer_id = c.customer_id
LEFT JOIN dim_products p ON f.product_id = p.product_id;

-- Verify the view works
SELECT TOP 10 * FROM vw_sales_dashboard;

-- Verify state-level aggregation
SELECT 
    customer_state, 
    SUM(price) AS total_revenue, 
    COUNT(DISTINCT order_id) AS order_count
FROM vw_sales_dashboard
GROUP BY customer_state
ORDER BY total_revenue DESC;
