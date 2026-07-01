# E-Commerce Cloud Analytics Pipeline

An end-to-end Azure cloud analytics pipeline that ingests raw e-commerce CSV data into Azure Data Lake Storage Gen2, transforms and loads it through Azure Data Factory into Azure SQL Database with Star Schema modeling, and visualizes it in a 3-page Power BI dashboard.

![Azure](https://img.shields.io/badge/Microsoft%20Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-CC2927?style=flat&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)

---

## Architecture

```
CSV Files → ADLS Gen2 (raw zone) → Azure Data Factory → Azure SQL Database → Power BI
```

```
┌──────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌──────────────────┐    ┌───────────┐
│  Kaggle CSV  │───▶│  ADLS Gen2       │───▶│  Azure Data     │───▶│  Azure SQL       │───▶│  Power BI │
│  Files (5)   │    │  varshinidatalake│    │  Factory        │    │  Database        │    │  Web      │
│              │    │  raw / processed │    │  4 Copy         │    │  Star Schema     │    │  3 Pages  │
│              │    │                  │    │  Activities     │    │  + SQL View      │    │           │
└──────────────┘    └──────────────────┘    └─────────────────┘    └──────────────────┘    └───────────┘
```

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Total Records Processed | 112,650+ |
| Unique Customers | 99,441 |
| Products | 32,951 |
| Product Categories | 70+ |
| Brazilian States | 27 |
| Total Revenue | R$ 13.59M |
| ADF Copy Activities | 4 (all succeeded on first run) |
| Dashboard Pages | 3 |

---

## Azure Resource Group

All resources were deployed within a single resource group: `ecommerce-analytics-rg`

| Resource Name | Type | Region |
|---------------|------|--------|
| varshinidatalake01 | Storage Account (ADLS Gen2) | East US |
| varshini-adf-pipeline | Data Factory (V2) | Central US |
| varshini-sql-server01 | SQL Server | Central US |
| ecommerce-analytics-db | SQL Database (Free tier) | Central US |

---

## Dataset

**Brazilian E-Commerce Public Dataset by Olist** — [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

Real anonymized commercial data from a Brazilian e-commerce marketplace covering 2016–2018.

| CSV File | Records | Target Table |
|----------|---------|--------------|
| olist_customers_dataset.csv | 99,441 | dim_customers |
| olist_products_dataset.csv | 32,951 | dim_products |
| olist_order_items_dataset.csv | 112,650 | fact_orders |
| olist_orders_dataset.csv | 99,441 | stg_orders (staging) |
| product_category_name_translation.csv | 71 | Reference only |

---

## Database Schema

### Star Schema Design

```
                    ┌──────────────────┐
                    │  dim_products    │
                    │──────────────────│
                    │  product_id (PK) │
                    │  product_category│
                    └────────┬─────────┘
                             │
                             │ product_id
                             │
┌──────────────────┐    ┌────┴─────────────────────────────────┐
│  dim_customers   │    │           fact_orders                │
│──────────────────│    │──────────────────────────────────────│
│  customer_id(PK) │◄───│  order_id                           │
│  customer_city   │    │  product_id (FK → dim_products)     │
│  customer_state  │    │  customer_id (FK → dim_customers)   │
└──────────────────┘    │  order_date                         │
                        │  price                              │
                        │  freight_value                      │
                        │  total_amount                       │
                        └─────────────────────────────────────┘
```

### SQL View: vw_sales_dashboard

Pre-joined view for optimized Power BI reporting — eliminates relationship dependency issues in Power BI Web.

```sql
CREATE VIEW vw_sales_dashboard AS
SELECT 
    f.order_id, f.order_date, f.price, f.freight_value,
    c.customer_city, c.customer_state,
    p.product_category
FROM fact_orders f
LEFT JOIN dim_customers c ON f.customer_id = c.customer_id
LEFT JOIN dim_products p ON f.product_id = p.product_id;
```

---

## Azure Data Factory Pipeline

**Pipeline Name:** `pipeline_load_ecommerce`

### Linked Services
| Name | Type | Target |
|------|------|--------|
| ls_adls_raw | Azure Data Lake Storage Gen2 | varshinidatalake01 |
| ls_azure_sql | Azure SQL Database | ecommerce-analytics-db |

### Copy Activities (4 parallel)
| Activity | Source (CSV) | Sink (SQL) | Columns Mapped |
|----------|-------------|------------|----------------|
| copy_customers | olist_customers_dataset.csv | dim_customers | customer_id, customer_city, customer_state |
| copy_products | olist_products_dataset.csv | dim_products | product_id, product_category_name → product_category |
| copy_order_items | olist_order_items_dataset.csv | fact_orders | order_id, product_id, price, freight_value |
| copy_orders_staging | olist_orders_dataset.csv | stg_orders | All 8 columns |

### Data Enrichment

After initial load, `fact_orders` had NULL values in `customer_id` and `order_date` because the order_items source file lacked these fields. Resolved using SQL UPDATE with INNER JOIN:

```sql
UPDATE f
SET f.customer_id = s.customer_id,
    f.order_date = CAST(LEFT(s.order_purchase_timestamp, 10) AS DATE)
FROM fact_orders f
INNER JOIN stg_orders s ON f.order_id = s.order_id;
```

**Result:** 112,650 rows enriched with customer IDs and order dates.

---

## Power BI Dashboard

### Page 1 — Executive Summary
- **KPI Card:** Total Revenue (R$ 13.59M)
- **KPI Card:** Total Orders (98,666 unique)
- **Clustered Bar Chart:** Revenue by Product Category
- **Filled Map:** Revenue by Brazilian State (geographic heat map)

### Page 2 — Product Performance
- **Table:** Product category, revenue, order count, freight cost
- **Clustered Bar Chart:** Top 10 product categories by revenue

### Page 3 — Regional Analysis
- **Table:** State-level revenue breakdown (27 states with unique values)
- **Clustered Bar Chart:** Top 5 cities by revenue (São Paulo, Rio de Janeiro, Belo Horizonte, Brasília, Curitiba)

> **Design Decision:** Originally used a donut chart for regional breakdown but rejected it because 27 states created 27 unreadable slices. Switched to a filled map which communicates geographic concentration instantly — São Paulo's dominance is visible without reading a single label.

---

## Project Structure

```
├── README.md                          # This file
├── sql/
│   ├── 01_create_tables.sql           # Star Schema DDL
│   ├── 02_create_staging_table.sql    # Staging table for orders
│   ├── 03_data_enrichment.sql         # UPDATE JOIN to fix NULLs
│   ├── 04_create_view.sql             # vw_sales_dashboard
│   └── 05_validation_queries.sql      # Data verification queries
├── adf/
│   └── pipeline_config.json           # ADF pipeline configuration reference
├── docs/
│   └── architecture_overview.md       # Detailed architecture documentation
└── screenshots/
    └── README.md                      # Add your dashboard screenshots here
```

---

## How to Reproduce

### Prerequisites
- Azure account (Azure for Students provides $100 free credits)
- Power BI account (free with .edu email)

### Steps

1. **Download Dataset:** Get the [Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle

2. **Create Azure Resources:**
   - Resource Group
   - ADLS Gen2 Storage Account (enable hierarchical namespace)
   - Azure SQL Database (Free tier)
   - Azure Data Factory V2

3. **Upload Data:** Upload 5 CSV files to the `raw` container in ADLS Gen2

4. **Create Tables:** Run SQL scripts in order (01 → 02)

5. **Build ADF Pipeline:** Create linked services, datasets, and 4 Copy Activities

6. **Run Pipeline:** Debug the pipeline — all 4 activities should succeed

7. **Enrich Data:** Run SQL scripts 03 and 04

8. **Connect Power BI:** Connect Power BI to Azure SQL, load tables + view, build dashboard

---

## Lessons Learned

- **Region restrictions:** Azure for Students subscription doesn't support SQL databases in all regions. East US was unavailable; Central US worked.
- **Firewall management:** Azure SQL blocks connections by default. Client IP must be whitelisted, and "Allow Azure services" must be enabled for ADF connectivity.
- **Source file alignment:** Source files rarely match target schema perfectly. The order_items file lacked customer_id, requiring a staging table and UPDATE JOIN pattern.
- **BI tool workarounds:** Power BI Web's Star Schema relationships can behave unexpectedly. Creating a pre-joined SQL view is a reliable and common real-world workaround.
- **Save frequently:** Power BI Web doesn't auto-save reports. Unsaved work is lost on refresh.

---

## Technologies Used

- **Azure Data Lake Storage Gen2** — Hierarchical namespace, raw/processed zones
- **Azure Data Factory V2** — ETL pipeline with Copy Activities
- **Azure SQL Database** — Star Schema, staging tables, SQL views
- **Power BI Web** — Connected to Azure SQL, 3-page dashboard
- **SQL** — DDL, DML, UPDATE JOINs, views, validation queries
- **Kaggle** — Brazilian E-Commerce dataset by Olist

---

## Author

**Varshini Maskapuri**
- MS in Management Information Systems, Northern Illinois University (May 2026)
- B.Tech in Computer Engineering, JNTU Hyderabad
- PL-300 Certified | Power BI | SQL | Azure | Python

[LinkedIn](https://linkedin.com/in/varshinimaskapuri) | [GitHub](https://github.com/maskapurivarshini-beep)

---

## License

This project is for educational and portfolio purposes. The dataset is publicly available on Kaggle under the [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.
