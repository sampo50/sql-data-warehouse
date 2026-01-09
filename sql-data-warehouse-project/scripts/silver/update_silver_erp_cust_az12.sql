INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen,
    dwh_create_date
)
SELECT 
    -- Clean CID: remove 'NAS' prefix if present
    CASE 
        WHEN LEFT(cid, 3) = 'NAS' THEN SUBSTRING(cid FROM 4)
        ELSE cid
    END AS cid,
    
    -- Nullify future birthdates
    CASE
        WHEN bdate > CURRENT_DATE THEN NULL
        ELSE bdate
    END AS bdate,
    
    -- Standardize gender
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'N/A'
    END AS gen,
    now() AS dwh_create_date
FROM bronze.erp_cust_az12 AS eca
WHERE cid IS NOT NULL;
