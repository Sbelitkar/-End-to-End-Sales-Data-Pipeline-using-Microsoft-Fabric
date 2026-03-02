-- ============================================================
-- sp_load_fact_sales.sql
-- Incremental merge of new sales records into fact_sales
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_load_fact_sales
    @run_date DATE = NULL   -- If NULL, uses yesterday
AS
BEGIN
    SET NOCOUNT ON;

    IF @run_date IS NULL
        SET @run_date = CAST(DATEADD(DAY, -1, GETUTCDATE()) AS DATE);

    DECLARE @date_key INT = CAST(FORMAT(@run_date, 'yyyyMMdd') AS INT);

    -- ── Step 1: Stage from Lakehouse Silver (via shortcut or EXTERNAL TABLE) ──
    -- In Fabric, Silver Delta Tables are auto-discoverable in the Lakehouse SQL endpoint.
    -- This procedure assumes a staging table is pre-populated by the Spark notebook.

    -- ── Step 2: MERGE into fact_sales ──
    MERGE dbo.fact_sales AS target
    USING (
        SELECT
            s.order_id,
            s.order_line,
            CAST(FORMAT(s.order_date, 'yyyyMMdd') AS INT)       AS date_key,
            CAST(FORMAT(s.ship_date,  'yyyyMMdd') AS INT)       AS ship_date_key,
            c.customer_key,
            p.product_key,
            r.region_key,
            s.ship_mode,
            s.quantity,
            s.unit_price,
            s.discount,
            s.gross_sales,
            s.discount_amt,
            s.net_sales,
            s.cogs,
            s.profit
        FROM dbo.stg_sales s                          -- staging table from Lakehouse shortcut
        LEFT JOIN dbo.dim_customer c ON c.customer_id = s.customer_id AND c.is_current = 1
        LEFT JOIN dbo.dim_product  p ON p.product_id  = s.product_id
        LEFT JOIN dbo.dim_region   r ON r.region      = s.region
        WHERE CAST(FORMAT(s.order_date, 'yyyyMMdd') AS INT) = @date_key
    ) AS source
    ON target.order_id = source.order_id
       AND target.order_line = source.order_line
    WHEN MATCHED THEN UPDATE SET
        target.quantity     = source.quantity,
        target.unit_price   = source.unit_price,
        target.discount     = source.discount,
        target.gross_sales  = source.gross_sales,
        target.discount_amt = source.discount_amt,
        target.net_sales    = source.net_sales,
        target.cogs         = source.cogs,
        target.profit       = source.profit,
        target._loaded_at   = GETUTCDATE()
    WHEN NOT MATCHED BY TARGET THEN INSERT (
        sales_key, date_key, ship_date_key, customer_key, product_key, region_key,
        order_id, order_line, ship_mode,
        quantity, unit_price, discount, gross_sales, discount_amt, net_sales, cogs, profit
    ) VALUES (
        NEXT VALUE FOR dbo.seq_sales_key,
        source.date_key, source.ship_date_key,
        source.customer_key, source.product_key, source.region_key,
        source.order_id, source.order_line, source.ship_mode,
        source.quantity, source.unit_price, source.discount,
        source.gross_sales, source.discount_amt, source.net_sales,
        source.cogs, source.profit
    );

    DECLARE @rows_affected INT = @@ROWCOUNT;
    RAISERROR('sp_load_fact_sales: %d rows merged for date %s', 0, 1, @rows_affected, @run_date) WITH NOWAIT;
END;
GO
