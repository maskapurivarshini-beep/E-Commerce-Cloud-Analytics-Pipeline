# Architecture Overview

## Pipeline Flow

```
Source Data (Kaggle CSVs)
    │
    ▼
Azure Data Lake Storage Gen2 (varshinidatalake01)
    │   ├── raw/          ← 5 CSV files uploaded here
    │   └── processed/    ← Reserved for transformed data
    │
    ▼
Azure Data Factory V2 (varshini-adf-pipeline)
    │   ├── Linked Services (2): ADLS Gen2 + Azure SQL
    │   ├── Datasets (8): 4 source CSVs + 4 target SQL tables
    │   └── Copy Activities (4): Running in parallel
    │       ├── copy_customers      → dim_customers (99,441 rows)
    │       ├── copy_products       → dim_products (32,951 rows)
    │       ├── copy_order_items    → fact_orders (112,650 rows)
    │       └── copy_orders_staging → stg_orders (99,441 rows)
    │
    ▼
Azure SQL Database (ecommerce-analytics-db)
    │   ├── dim_customers (PK: customer_id)
    │   ├── dim_products (PK: product_id)
    │   ├── fact_orders (enriched via UPDATE JOIN from stg_orders)
    │   ├── stg_orders (staging table — loaded, joined, done)
    │   └── vw_sales_dashboard (pre-joined view for Power BI)
    │
    ▼
Power BI Web (app.powerbi.com)
        ├── Page 1: Executive Summary (KPIs, bar chart, filled map)
        ├── Page 2: Product Performance (table, top 10 chart)
        └── Page 3: Regional Analysis (state table, top 5 cities)
```

## Design Decisions

### Why ADLS Gen2 instead of Blob Storage?
ADLS Gen2 adds hierarchical namespace on top of Blob Storage, enabling folder level permissions, better analytics performance, and data lake zoning patterns (raw/processed/curated).

### Why Star Schema?
Star Schema optimizes for aggregation queries common in BI reporting. The fact table stays lean (transaction data only) while dimension tables handle descriptive filtering. This structure makes DAX measures in Power BI more efficient.

### Why a Staging Table?
The order_items source file (fact table source) didn't contain customer_id or order_date these lived in the orders file. Rather than redesigning the pipeline, a staging table was loaded and a SQL UPDATE JOIN enriched the fact table. This is a common real world ETL pattern.

### Why a SQL View?
Power BI Web's relationship engine didn't filter correctly between fact_orders and dim_customers despite proper Many-to-One configuration. Creating a pre-joined SQL view (vw_sales_dashboard) bypassed the issue entirely. This is a pragmatic, production common pattern.

### Why Filled Map instead of Donut Chart?
27 Brazilian states in a donut chart created 27 unreadable slices of nearly equal size. A filled map communicates geographic concentration instantly São Paulo's revenue dominance is visible without reading a single label.

## Cost Summary

| Resource | Monthly Cost |
|----------|-------------|
| ADLS Gen2 (few CSV files) | ~$0.01 |
| Azure SQL Database (free tier) | $0.00 |
| Data Factory (idle) | $0.00 |
| **Total** | **Under $0.05/month** |

Total project cost: Under $2 of $100 student credits.
