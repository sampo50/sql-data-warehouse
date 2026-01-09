INSERT INTO silver.crm_prd_info (
    prd_id,
    prd_key,
    cat_id,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    b.prd_id,
    SUBSTRING(b.prd_key FROM 7)                                           AS prd_key,        -- keep after the dash
    REPLACE(SUBSTRING(b.prd_key FROM 1 FOR 5), '-', '_')                  AS cat_id,         -- category part
    b.prd_nm,
    COALESCE(b.prd_cost, 0)                                               AS prd_cost,
    CASE
        WHEN upper(trim(b.prd_line)) = 'M' THEN 'Mountain'
        WHEN upper(trim(b.prd_line)) = 'R' THEN 'Road'
        WHEN upper(trim(b.prd_line)) = 'S' THEN 'Other Sales'
        WHEN upper(trim(b.prd_line)) = 'T' THEN 'Touring'
        ELSE 'N/A'
    END                                                                    AS prd_line,
    CAST(b.prd_start_dt AS date)                                          AS prd_start_dt,
    (LEAD(b.prd_start_dt) OVER (
        PARTITION BY b.prd_key
        ORDER BY b.prd_start_dt
     ) - INTERVAL '1 day')::date                                          AS prd_end_dt
FROM bronze.crm_prd_info AS b
WHERE b.prd_id IS NOT NULL;