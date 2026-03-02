-- ============================================================
-- create_dimensions.sql
-- Dimension Tables for Sales Star Schema (Fabric Warehouse)
-- ============================================================

-- ─────────────────────────────────────
-- dim_date
-- ─────────────────────────────────────
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL DROP TABLE dbo.dim_date;

CREATE TABLE dbo.dim_date (
    date_key        INT           NOT NULL PRIMARY KEY,
    [date]          DATE          NOT NULL,
    [year]          SMALLINT      NOT NULL,
    quarter         TINYINT       NOT NULL,
    quarter_label   VARCHAR(3)    NOT NULL,  -- 'Q1','Q2'...
    [month]         TINYINT       NOT NULL,
    month_name      VARCHAR(10)   NOT NULL,
    [week]          TINYINT       NOT NULL,
    [day]           TINYINT       NOT NULL,
    day_of_week     TINYINT       NOT NULL,  -- 1=Sun, 7=Sat
    day_name        VARCHAR(10)   NOT NULL,
    is_weekend      BIT           NOT NULL DEFAULT 0,
    yyyymm          INT           NOT NULL
)
WITH (HEAP);

-- ─────────────────────────────────────
-- dim_customer
-- ─────────────────────────────────────
IF OBJECT_ID('dbo.dim_customer', 'U') IS NOT NULL DROP TABLE dbo.dim_customer;

CREATE TABLE dbo.dim_customer (
    customer_key    INT           NOT NULL PRIMARY KEY,
    customer_id     VARCHAR(50)   NOT NULL,
    customer_name   NVARCHAR(200) NOT NULL,
    segment         VARCHAR(50)   NULL,      -- Consumer, Corporate, Home Office
    country         VARCHAR(100)  NULL,
    [state]         VARCHAR(100)  NULL,
    city            VARCHAR(100)  NULL,
    postal_code     VARCHAR(20)   NULL,
    email           VARCHAR(200)  NULL,
    is_current      BIT           NOT NULL DEFAULT 1,
    valid_from      DATETIME2     NULL,
    valid_to        DATETIME2     NULL
)
WITH (HEAP);

-- ─────────────────────────────────────
-- dim_product
-- ─────────────────────────────────────
IF OBJECT_ID('dbo.dim_product', 'U') IS NOT NULL DROP TABLE dbo.dim_product;

CREATE TABLE dbo.dim_product (
    product_key     INT           NOT NULL PRIMARY KEY,
    product_id      VARCHAR(50)   NOT NULL,
    product_name    NVARCHAR(500) NOT NULL,
    category        VARCHAR(100)  NULL,
    sub_category    VARCHAR(100)  NULL,
    brand           VARCHAR(100)  NULL,
    standard_cost   DECIMAL(18,2) NULL,
    list_price      DECIMAL(18,2) NULL
)
WITH (HEAP);

-- ─────────────────────────────────────
-- dim_region
-- ─────────────────────────────────────
IF OBJECT_ID('dbo.dim_region', 'U') IS NOT NULL DROP TABLE dbo.dim_region;

CREATE TABLE dbo.dim_region (
    region_key      INT           NOT NULL PRIMARY KEY,
    region          VARCHAR(100)  NOT NULL
)
WITH (HEAP);

PRINT 'All dimension tables created successfully.';
