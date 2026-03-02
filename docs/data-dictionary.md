# 📖 Data Dictionary

## Source Layer (Raw / Bronze)

### sales (raw)
| Column | Type | Description |
|--------|------|-------------|
| order_id | string | Unique order identifier (e.g., ORD-000001) |
| order_line | integer | Line item number within the order |
| order_date | date | Date when order was placed (YYYY-MM-DD) |
| ship_date | date | Date when order was shipped |
| ship_mode | string | Shipping method: Standard Class, Second Class, First Class, Same Day |
| customer_id | string | Customer identifier (e.g., CUST-00001) |
| product_id | string | Product identifier (e.g., PROD-00001) |
| region | string | Sales region: North, South, East, West, Central |
| quantity | integer | Number of units ordered |
| unit_price | decimal | Selling price per unit |
| discount | decimal | Discount rate (0–1, e.g., 0.20 = 20%) |
| cogs | decimal | Cost of goods sold for this line |

### customers (raw)
| Column | Type | Description |
|--------|------|-------------|
| customer_id | string | Unique customer identifier |
| customer_name | string | Full name of customer |
| segment | string | Customer segment: Consumer, Corporate, Home Office |
| country | string | Country of customer |
| state | string | State/province |
| city | string | City |
| postal_code | string | Postal / ZIP code |
| email | string | Customer email address |

### products (raw)
| Column | Type | Description |
|--------|------|-------------|
| product_id | string | Unique product identifier |
| product_name | string | Full product name |
| category | string | Top-level category: Technology, Furniture, Office Supplies |
| sub_category | string | Sub-category within the category |
| brand | string | Product brand name |
| standard_cost | decimal | Internal cost price |
| list_price | decimal | Published list price |

---

## Silver Layer (Cleaned Delta Tables)

### silver_sales
All columns from raw sales, plus:

| Column | Type | Description |
|--------|------|-------------|
| gross_sales | decimal | quantity × unit_price |
| discount_amt | decimal | gross_sales × discount |
| net_sales | decimal | gross_sales − discount_amt |
| profit | decimal | net_sales − cogs |
| _silver_loaded_at | timestamp | When this record was loaded to Silver |

### silver_customers / silver_products
Same as raw, with standardized casing, trimmed strings, and `_silver_loaded_at`.

---

## Gold Layer — Star Schema (Fabric Warehouse)

### dim_date
| Column | Type | Description |
|--------|------|-------------|
| date_key | int | Surrogate key (YYYYMMDD format) |
| date | date | Calendar date |
| year | smallint | Calendar year |
| quarter | tinyint | Quarter number (1–4) |
| quarter_label | varchar | 'Q1', 'Q2', 'Q3', 'Q4' |
| month | tinyint | Month number (1–12) |
| month_name | varchar | 'January', 'February', etc. |
| week | tinyint | ISO week number |
| day | tinyint | Day of month |
| day_of_week | tinyint | 1=Sunday … 7=Saturday |
| day_name | varchar | 'Monday', 'Tuesday', etc. |
| is_weekend | bit | 1 if Saturday or Sunday |
| yyyymm | int | Year-month key (YYYYMM) |

### dim_customer
| Column | Type | Description |
|--------|------|-------------|
| customer_key | int | Surrogate key (PK) |
| customer_id | varchar | Natural/source key |
| customer_name | nvarchar | Full name |
| segment | varchar | Consumer / Corporate / Home Office |
| country | varchar | Country |
| state | varchar | State/province |
| city | varchar | City |
| postal_code | varchar | ZIP/postal code |
| email | varchar | Email address |
| is_current | bit | SCD Type 2: 1 = current record |
| valid_from | datetime2 | SCD Type 2: when record became active |
| valid_to | datetime2 | SCD Type 2: NULL if current |

### dim_product
| Column | Type | Description |
|--------|------|-------------|
| product_key | int | Surrogate key (PK) |
| product_id | varchar | Natural/source key |
| product_name | nvarchar | Full product name |
| category | varchar | Technology / Furniture / Office Supplies |
| sub_category | varchar | Sub-category |
| brand | varchar | Brand name |
| standard_cost | decimal(18,2) | Internal cost |
| list_price | decimal(18,2) | Published price |

### dim_region
| Column | Type | Description |
|--------|------|-------------|
| region_key | int | Surrogate key (PK) |
| region | varchar | Region name |

### fact_sales
| Column | Type | Description |
|--------|------|-------------|
| sales_key | bigint | Surrogate key (PK) |
| date_key | int | FK → dim_date |
| ship_date_key | int | FK → dim_date (ship date) |
| customer_key | int | FK → dim_customer |
| product_key | int | FK → dim_product |
| region_key | int | FK → dim_region |
| order_id | varchar | Degenerate dimension — source order ID |
| order_line | smallint | Line number within order |
| ship_mode | varchar | Shipping method |
| quantity | int | Units sold |
| unit_price | decimal(18,4) | Selling price per unit |
| discount | decimal(8,4) | Discount rate applied |
| gross_sales | decimal(18,2) | quantity × unit_price |
| discount_amt | decimal(18,2) | gross_sales × discount |
| net_sales | decimal(18,2) | After discount |
| cogs | decimal(18,2) | Cost of goods sold |
| profit | decimal(18,2) | net_sales − cogs |
| _loaded_at | datetime2 | Load timestamp |

---

## Business Rules

| Rule | Description |
|------|-------------|
| Deduplication | Bronze → Silver removes duplicate `(order_id, order_line)` pairs |
| Discount | Always 0–1 decimal; NULL coalesced to 0 |
| COGS | Sourced from ERP; approximated as `standard_cost × quantity` if missing |
| Profit | Always `net_sales − cogs`; can be negative (returns/clearance) |
| Date range | `dim_date` covers 2018-01-01 to 2030-12-31 |
| SCD Type 2 | `dim_customer` tracks historical changes via `valid_from` / `valid_to` |
