TRUNCATE
    TABLE silver.erp_px_cat_g1v2;

INSERT
    INTO
    silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance,
        dwh_create_date
    )
SELECT
    id,
    cat,
    subcat,
    maintenance,
    now() AS dwh_create_date
FROM
    bronze.erp_px_cat_g1v2 epcgv;