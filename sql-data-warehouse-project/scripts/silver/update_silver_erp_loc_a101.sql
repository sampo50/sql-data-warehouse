TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (cid, cntry, dwh_create_date)
SELECT 
    REPLACE(cid, '-', '') AS cid,
    CASE 
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE TRIM(cntry)
    END AS cntry,
    now() AS dwh_create_date
FROM bronze.erp_loc_a101;
