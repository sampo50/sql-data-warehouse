INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    -- Convert order date safely
    CASE
        WHEN sls_order_dt IS NULL
          OR sls_order_dt = 0
          OR length(sls_order_dt::text) <> 8
        THEN NULL
        ELSE to_date(lpad(sls_order_dt::text, 8, '0'), 'YYYYMMDD')
    END AS sls_order_dt,
    -- Convert ship date safely
    CASE
        WHEN sls_ship_dt IS NULL
          OR sls_ship_dt = 0
          OR length(sls_ship_dt::text) <> 8
        THEN NULL
        ELSE to_date(lpad(sls_ship_dt::text, 8, '0'), 'YYYYMMDD')
    END AS sls_ship_dt,
    -- Convert due date safely
    CASE
        WHEN sls_due_dt IS NULL
          OR sls_due_dt = 0
          OR length(sls_due_dt::text) <> 8
        THEN NULL
        ELSE to_date(lpad(sls_due_dt::text, 8, '0'), 'YYYYMMDD')
    END AS sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_ord_num IS NOT NULL;
