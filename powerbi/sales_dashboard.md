# 📊 Power BI Sales Dashboard — Design Guide

## Semantic Model Setup

### 1. Connect to Fabric Warehouse
- **Connector:** Microsoft Fabric → Warehouse
- **Workspace:** `sales-pipeline-workspace`
- **Warehouse:** `sales_warehouse`
- **Import mode:** DirectQuery (for real-time) or Import (for performance)

### 2. Tables to Load
- `dbo.fact_sales`
- `dbo.dim_customer`
- `dbo.dim_product`
- `dbo.dim_date`
- `dbo.dim_region`
- `dbo.vw_monthly_sales` (for summary views)
- `dbo.vw_customer_rfm`
- `dbo.vw_product_performance`

### 3. Relationships
```
fact_sales[date_key]     → dim_date[date_key]       (Many:1, Active)
fact_sales[ship_date_key]→ dim_date[date_key]       (Many:1, Inactive)
fact_sales[customer_key] → dim_customer[customer_key](Many:1, Active)
fact_sales[product_key]  → dim_product[product_key] (Many:1, Active)
fact_sales[region_key]   → dim_region[region_key]   (Many:1, Active)
```

---

## Dashboard Pages

### Page 1: Executive Summary
**Purpose:** C-suite at-a-glance view

| Visual | Type | Fields |
|--------|------|--------|
| Total Revenue | KPI Card | [Total Net Sales] vs [Sales Target] |
| Gross Profit | KPI Card | [Gross Profit] |
| Profit Margin | KPI Card | [Profit Margin %] |
| YoY Growth | KPI Card | [YoY Growth %] |
| Revenue Trend | Line Chart | dim_date[month_name], [Total Net Sales], [Net Sales PY] |
| Sales by Region | Bar Chart | dim_region[region], [Total Net Sales] |
| Top 5 Products | Bar Chart | dim_product[product_name], [Total Net Sales] |
| Segment Mix | Donut Chart | dim_customer[segment], [Total Net Sales] |

---

### Page 2: Sales by Region
**Purpose:** Geographic performance

| Visual | Type | Fields |
|--------|------|--------|
| Region Map | Filled Map | dim_customer[state], [Total Net Sales] |
| Region Comparison | Clustered Bar | dim_region[region], [Total Net Sales], [Gross Profit] |
| Region Trend | Line Chart | dim_date[month_name], [Total Net Sales] — slicer by region |
| Region Metrics | Matrix | dim_region[region] × [Net Sales], [Profit Margin %], [Orders] |
| Slicer: Year | Dropdown | dim_date[year] |

---

### Page 3: Product Performance
**Purpose:** SKU-level analytics

| Visual | Type | Fields |
|--------|------|--------|
| Category Breakdown | Treemap | category → sub_category → [Total Net Sales] |
| Top 10 Products | Horizontal Bar | dim_product[product_name], [Total Net Sales] |
| Margin vs Volume | Scatter | [Total Units Sold] X-axis, [Profit Margin %] Y-axis, bubble=[Net Sales] |
| Product Table | Table | product_name, category, units_sold, net_sales, margin% |
| Slicer: Category | Chiclet/Dropdown | dim_product[category] |

---

### Page 4: Customer Analysis
**Purpose:** Customer segmentation & RFM

| Visual | Type | Fields |
|--------|------|--------|
| RFM Scatter | Scatter Chart | recency_days, frequency, monetary_value |
| Segment Revenue | Donut | dim_customer[segment], [Total Net Sales] |
| Top Customers | Table | customer_name, [orders], [net_sales], [avg_order_value] |
| New vs Returning | KPI Cards | [New Customers], [Unique Customers] |
| Revenue per Customer | KPI | [Revenue per Customer] |

---

### Page 5: Time Analysis
**Purpose:** Temporal trends and seasonality

| Visual | Type | Fields |
|--------|------|--------|
| Monthly Trend | Area Chart | dim_date[date], [Total Net Sales], [Net Sales PY] |
| YoY Waterfall | Waterfall | Month-level YoY delta |
| Heatmap | Matrix | dim_date[year] rows × dim_date[month_name] cols → [Total Net Sales] |
| QTD vs Target | Gauge | [Net Sales QTD] vs [Sales Target] |
| Seasonality Index | Line | dim_date[month_name], avg sales |

---

## Row-Level Security (RLS)

### Setup in Power BI Desktop:
1. Go to **Modeling** → **Manage roles**
2. Create role `RegionalManager`:
   ```dax
   [region] = USERPRINCIPALNAME()
   ```
3. Map roles to Azure AD groups in Power BI Service

---

## Refresh Schedule

| Mode | Schedule |
|------|----------|
| Import mode | Daily at 06:00 UTC (after pipeline completes) |
| DirectQuery | No schedule needed — always live |

---

## Sharing & Distribution

1. **Workspace:** Publish to `sales-pipeline-workspace`
2. **App:** Create Power BI App for end users
3. **Subscriptions:** Set up email subscriptions for daily snapshot
4. **Embed:** Use Power BI Embedded for customer-facing portals
