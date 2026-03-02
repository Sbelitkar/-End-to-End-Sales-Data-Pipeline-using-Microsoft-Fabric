-- ============================================================
-- create_facts.sql
-- Fact Table for Sales Star Schema (Fabric Warehouse)
-- ============================================================

IF OBJECT_ID('dbo.fact_sales', 'U') IS NOT NULL DROP TABLE dbo.fact_sales;

CREATE TABLE dbo.fact_sales (
    -- Surrogate key
    sales_key           BIGINT        NOT NULL PRIMARY KEY,

    -- Foreign keys to dimensions
    date_key            INT           NOT NULL REFERENCES dbo.dim_date(date_key),
    ship_date_key       INT           NULL     REFERENCES dbo.dim_date(date_key),
    customer_key        INT           NOT NULL REFERENCES dbo.dim_customer(customer_key),
    product_key         INT           NOT NULL REFERENCES dbo.dim_product(product_key),
    region_key          INT           NULL     REFERENCES dbo.dim_region(region_key),

    -- Degenerate dimensions (kept in fact)
    order_id            VARCHAR(50)   NOT NULL,
    order_line          SMALLINT      NOT NULL,
    ship_mode           VARCHAR(50)   NULL,

    -- Additive measures
    quantity            INT           NOT NULL DEFAULT 0,
    unit_price          DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount            DECIMAL(8,4)  NOT NULL DEFAULT 0,
    gross_sales         DECIMAL(18,2) NOT NULL DEFAULT 0,
    discount_amt        DECIMAL(18,2) NOT NULL DEFAULT 0,
    net_sales           DECIMAL(18,2) NOT NULL DEFAULT 0,
    cogs                DECIMAL(18,2) NOT NULL DEFAULT 0,
    profit              DECIMAL(18,2) NOT NULL DEFAULT 0,

    -- Audit
    _loaded_at          DATETIME2     NOT NULL DEFAULT GETUTCDATE()
)
WITH (HEAP);

-- Create indexes for common query patterns
CREATE INDEX ix_fact_sales_date         ON dbo.fact_sales (date_key);
CREATE INDEX ix_fact_sales_customer     ON dbo.fact_sales (customer_key);
CREATE INDEX ix_fact_sales_product      ON dbo.fact_sales (product_key);
CREATE INDEX ix_fact_sales_region       ON dbo.fact_sales (region_key);
CREATE INDEX ix_fact_sales_order        ON dbo.fact_sales (order_id);

PRINT 'fact_sales table created successfully.';
