CREATE OR REPLACE view gold.dim_products as
SELECT
    ROW_NUMBER() OVER (
    ORDER BY
        cpi.prd_start_dt,
        cpi.prd_key
    ) AS product_key,
    cpi.prd_id AS product_id,    
    cpi.prd_key AS product_number,
    cpi.prd_nm AS product_name,
    cpi.cat_id AS category_id,
    epcgv.cat AS category,
    epcgv.subcat subcategory,
    epcgv.maintenance,
    cpi.prd_cost AS product_cost,
    cpi.prd_line AS product_line,
    cpi.prd_start_dt AS product_start_date
FROM
    silver.crm_prd_info cpi
LEFT JOIN silver.erp_px_cat_g1v2 epcgv 
ON
    cpi.cat_id = epcgv.id
WHERE
    cpi.prd_end_dt IS NULL