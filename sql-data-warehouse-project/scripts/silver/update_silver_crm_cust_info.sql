UPDATE
    silver.crm_cust_info AS s
SET
    cst_key = b.cst_key,
    cst_firstname = TRIM(b.cst_firstname),
    cst_lastname = TRIM(b.cst_lastname),
    cst_marital_status = CASE
        WHEN upper(trim(b.cst_marital_status)) = 'M' THEN 'Married'
        WHEN upper(trim(b.cst_marital_status)) = 'S' THEN 'Single'
        ELSE 'N/A'
    END,
    cst_gndr = CASE
        WHEN upper(trim(b.cst_gndr)) = 'F' THEN 'Female'
        WHEN upper(trim(b.cst_gndr)) = 'M' THEN 'Male'
        ELSE 'N/A'
    END,
    cst_create_date = b.cst_create_date
FROM
    (
        SELECT
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
            ORDER BY
                cst_create_date DESC
            ) AS flag_last
        FROM
            bronze.crm_cust_info
    ) AS b
WHERE
    b.flag_last = 1
    AND b.cst_id IS NOT NULL
    AND s.cst_id = b.cst_id;
