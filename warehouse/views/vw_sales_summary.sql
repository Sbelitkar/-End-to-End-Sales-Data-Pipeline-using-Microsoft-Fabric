-- ============================================================
-- vw_sales_summary.sql
-- Reporting views for Power BI semantic model
-- ============================================================

-- ── 1. Monthly Sales Summary ─────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_monthly_sales AS
SELECT
    d.year,
    d.quarter,
    d.quarter_label,
    d.month,
    d.month_name,
    d.yyyymm,
    r.region,
    cat.category,
    cat.sub_category,
    seg.segment,
    COUNT(DISTINCT f.order_id)      AS order_count,
    SUM(f.quantity)                 AS units_sold,
    SUM(f.gross_sales)              AS gross_sales,
    SUM(f.discount_amt)             AS total_discounts,
    SUM(f.net_sales)                AS net_sales,
    SUM(f.cogs)                     AS total_cogs,
    SUM(f.profit)                   AS gross_profit,
    CASE WHEN SUM(f.net_sales) = 0 THEN 0
         ELSE ROUND(SUM(f.profit) / SUM(f.net_sales) * 100, 2)
    END                             AS profit_margin_pct
FROM dbo.fact_sales f
JOIN dbo.dim_date     d   ON f.date_key     = d.date_key
JOIN dbo.dim_region   r   ON f.region_key   = r.region_key
JOIN dbo.dim_product  cat ON f.product_key  = cat.product_key
JOIN dbo.dim_customer seg ON f.customer_key = seg.customer_key
GROUP BY
    d.year, d.quarter, d.quarter_label, d.month, d.month_name, d.yyyymm,
    r.region, cat.category, cat.sub_category, seg.segment;
GO

-- ── 2. Customer RFM View ──────────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_customer_rfm AS
SELECT
    c.customer_key,
    c.customer_id,
    c.customer_name,
    c.segment,
    c.country,
    c.state,
    DATEDIFF(DAY, MAX(d.date), GETUTCDATE())  AS recency_days,
    COUNT(DISTINCT f.order_id)                AS frequency,
    SUM(f.net_sales)                          AS monetary_value,
    AVG(f.net_sales)                          AS avg_order_value,
    MIN(d.date)                               AS first_order_date,
    MAX(d.date)                               AS last_order_date
FROM dbo.fact_sales   f
JOIN dbo.dim_customer c ON f.customer_key = c.customer_key
JOIN dbo.dim_date     d ON f.date_key     = d.date_key
GROUP BY
    c.customer_key, c.customer_id, c.customer_name,
    c.segment, c.country, c.state;
GO

-- ── 3. Product Performance View ───────────────────────────────
CREATE OR ALTER VIEW dbo.vw_product_performance AS
SELECT
    p.product_key,
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    p.brand,
    p.list_price,
    SUM(f.quantity)    AS units_sold,
    SUM(f.net_sales)   AS net_sales,
    SUM(f.profit)      AS gross_profit,
    CASE WHEN SUM(f.net_sales) = 0 THEN 0
         ELSE ROUND(SUM(f.profit) / SUM(f.net_sales) * 100, 2)
    END                AS profit_margin_pct,
    AVG(f.discount)    AS avg_discount_rate
FROM dbo.fact_sales  f
JOIN dbo.dim_product p ON f.product_key = p.product_key
GROUP BY
    p.product_key, p.product_id, p.product_name,
    p.category, p.sub_category, p.brand, p.list_price;
GO

PRINT 'All reporting views created.';
