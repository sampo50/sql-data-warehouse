CREATE OR REPLACE VIEW gold.dim_customers AS 
WITH customers_ranked AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY cci.cst_key     -- one row per customer_number
            ORDER BY 
                eca.bdate DESC NULLS LAST,   -- prefer row with latest birth_date
                cci.cst_id                  -- tie-breaker
        ) AS rn,
        cci.cst_id             AS customer_id,
        cci.cst_key            AS customer_number,
        cci.cst_firstname      AS first_name,
        cci.cst_lastname       AS last_name,
        ela.cntry              AS country,
        cci.cst_marital_status AS marital_status,
        CASE 
            WHEN cci.cst_gndr <> 'n/a' THEN cci.cst_gndr
            ELSE COALESCE(eca.gen, 'n/a')
        END                    AS gender,
        eca.bdate              AS birth_date,
        cci.cst_create_date    AS create_date
    FROM silver.crm_cust_info cci 
    LEFT JOIN silver.erp_cust_az12 eca 
        ON cci.cst_key = eca.cid 
    LEFT JOIN silver.erp_loc_a101 ela 
        ON cci.cst_key = ela.cid
)
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    customer_id,
    customer_number,
    first_name,
    last_name,
    country,
    marital_status,
    gender,
    birth_date,
    create_date
FROM customers_ranked
WHERE rn = 1;
