-- DROP SCHEMA gold;

CREATE SCHEMA gold AUTHORIZATION postgres;
-- gold.dim_customers source

CREATE OR REPLACE VIEW gold.dim_customers
AS WITH customers_ranked AS (
         SELECT row_number() OVER (PARTITION BY cci.cst_key ORDER BY eca.bdate DESC NULLS LAST, cci.cst_id) AS rn,
            cci.cst_id AS customer_id,
            cci.cst_key AS customer_number,
            cci.cst_firstname AS first_name,
            cci.cst_lastname AS last_name,
            ela.cntry AS country,
            cci.cst_marital_status AS marital_status,
                CASE
                    WHEN cci.cst_gndr::text <> 'n/a'::text THEN cci.cst_gndr
                    ELSE COALESCE(eca.gen, 'n/a'::character varying)
                END AS gender,
            eca.bdate AS birth_date,
            cci.cst_create_date AS create_date
           FROM silver.crm_cust_info cci
             LEFT JOIN silver.erp_cust_az12 eca ON cci.cst_key::text = eca.cid::text
             LEFT JOIN silver.erp_loc_a101 ela ON cci.cst_key::text = ela.cid::text
        )
 SELECT row_number() OVER (ORDER BY customer_id) AS customer_key,
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


-- gold.dim_products source

CREATE OR REPLACE VIEW gold.dim_products
AS SELECT row_number() OVER (ORDER BY cpi.prd_start_dt, cpi.prd_key) AS product_key,
    cpi.prd_id AS product_id,
    cpi.prd_key AS product_number,
    cpi.prd_nm AS product_name,
    cpi.cat_id AS category_id,
    epcgv.cat AS category,
    epcgv.subcat AS subcategory,
    epcgv.maintenance,
    cpi.prd_cost AS product_cost,
    cpi.prd_line AS product_line,
    cpi.prd_start_dt AS product_start_date
   FROM silver.crm_prd_info cpi
     LEFT JOIN silver.erp_px_cat_g1v2 epcgv ON cpi.cat_id::text = epcgv.id::text
  WHERE cpi.prd_end_dt IS NULL;


-- gold.fact_sales source

CREATE OR REPLACE VIEW gold.fact_sales
AS SELECT csd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    csd.sls_order_dt AS order_date,
    csd.sls_ship_dt AS shipping_date,
    csd.sls_due_dt AS due_date,
    csd.sls_sales AS sales_amount,
    csd.sls_quantity AS quantity,
    csd.sls_price AS price
   FROM silver.crm_sales_details csd
     LEFT JOIN gold.dim_products dp ON csd.sls_prd_key::text = dp.product_number::text
     LEFT JOIN gold.dim_customers dc ON csd.sls_cust_id = dc.customer_id;


-- gold.vw_customer_profile source

CREATE OR REPLACE VIEW gold.vw_customer_profile
AS WITH base_query AS (
         SELECT t.order_number,
            t.product_key,
            t.order_date,
            t.sales_amount,
            t.quantity,
            dc.customer_key,
            dc.customer_number,
            concat(dc.first_name, ' ', dc.last_name) AS customer_name,
            EXTRACT(year FROM age(CURRENT_DATE::timestamp with time zone, dc.birth_date::timestamp with time zone)) AS age_years
           FROM gold.fact_sales t
             LEFT JOIN gold.dim_customers dc ON t.customer_key = dc.customer_key
          WHERE t.order_date IS NOT NULL
        ), customer_aggregation AS (
         SELECT base_query.customer_key,
            base_query.customer_number,
            base_query.customer_name,
            base_query.age_years,
            count(DISTINCT base_query.order_number) AS total_orders,
            sum(base_query.sales_amount) AS total_sales,
            sum(base_query.quantity) AS total_quantity,
            count(DISTINCT base_query.product_key) AS total_products,
            max(base_query.order_date) AS last_order_date,
            EXTRACT(year FROM age(max(base_query.order_date)::timestamp with time zone, min(base_query.order_date)::timestamp with time zone)) * 12::numeric + EXTRACT(month FROM age(max(base_query.order_date)::timestamp with time zone, min(base_query.order_date)::timestamp with time zone)) AS lifespan
           FROM base_query
          GROUP BY base_query.customer_key, base_query.customer_number, base_query.customer_name, base_query.age_years
        )
 SELECT customer_key,
    customer_number,
    customer_name,
    age_years,
        CASE
            WHEN age_years < 20::numeric THEN 'Under 20'::text
            WHEN age_years >= 20::numeric AND age_years <= 29::numeric THEN '20-29'::text
            WHEN age_years >= 30::numeric AND age_years <= 39::numeric THEN '30-39'::text
            WHEN age_years >= 40::numeric AND age_years <= 49::numeric THEN '40-49'::text
            ELSE '50 and above'::text
        END AS age_group,
        CASE
            WHEN total_sales >= 5000 AND lifespan >= 12::numeric THEN 'VIP'::text
            WHEN total_sales < 5000 AND lifespan >= 12::numeric THEN 'Regular'::text
            WHEN lifespan < 12::numeric THEN 'New'::text
            ELSE 'Unclassified'::text
        END AS customer_segment,
    EXTRACT(year FROM age(CURRENT_DATE::timestamp with time zone, last_order_date::timestamp with time zone)) * 12::numeric + EXTRACT(month FROM age(CURRENT_DATE::timestamp with time zone, last_order_date::timestamp with time zone)) AS since_last_order,
    total_orders,
    total_sales,
    total_quantity,
    last_order_date,
    lifespan,
        CASE
            WHEN total_orders = 0 THEN 0::bigint
            ELSE total_sales / total_orders
        END AS avg_order_value,
    round(
        CASE
            WHEN lifespan = 0::numeric THEN total_sales::numeric
            ELSE total_sales::numeric / lifespan
        END, 2) AS avg_monthly_spend
   FROM customer_aggregation;


-- gold.vw_product_profile source

CREATE OR REPLACE VIEW gold.vw_product_profile
AS WITH base_query AS (
         SELECT t.order_number,
            t.order_date,
            t.customer_key,
            t.sales_amount,
            t.quantity,
            dp.product_key,
            dp.product_name,
            dp.category,
            dp.subcategory,
            dp.product_cost
           FROM gold.fact_sales t
             LEFT JOIN gold.dim_products dp ON t.product_key = dp.product_key
          WHERE t.order_date IS NOT NULL
        ), product_aggregation AS (
         SELECT base_query.product_key,
            base_query.product_name,
            base_query.category,
            base_query.subcategory,
            base_query.product_cost,
            EXTRACT(year FROM age(max(base_query.order_date)::timestamp with time zone, min(base_query.order_date)::timestamp with time zone)) * 12::numeric + EXTRACT(month FROM age(max(base_query.order_date)::timestamp with time zone, min(base_query.order_date)::timestamp with time zone)) AS lifespan,
            max(base_query.order_date) AS last_sale_date,
            count(DISTINCT base_query.order_number) AS total_orders,
            count(DISTINCT base_query.customer_key) AS total_customers,
            sum(base_query.sales_amount) AS total_sales,
            sum(base_query.quantity) AS total_quantity,
                CASE
                    WHEN sum(base_query.quantity) = 0 THEN 0::bigint
                    ELSE sum(base_query.sales_amount) / sum(base_query.quantity)
                END AS avg_selling_price
           FROM base_query
          GROUP BY base_query.product_key, base_query.product_name, base_query.category, base_query.subcategory, base_query.product_cost
        )
 SELECT product_key,
    product_name,
    category,
    subcategory,
    product_cost,
    last_sale_date,
    EXTRACT(year FROM age(CURRENT_DATE::timestamp with time zone, last_sale_date::timestamp with time zone)) * 12::numeric + EXTRACT(month FROM age(CURRENT_DATE::timestamp with time zone, last_sale_date::timestamp with time zone)) AS since_last_sale,
        CASE
            WHEN total_sales > 50000 THEN 'High-Performer'::text
            WHEN total_sales >= 10000 THEN 'Mid-Range'::text
            ELSE 'Low-Performer'::text
        END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
        CASE
            WHEN total_orders = 0 THEN 0::bigint
            ELSE total_sales / total_orders
        END AS avg_order_revenue,
    round(
        CASE
            WHEN lifespan = 0::numeric THEN total_sales::numeric
            ELSE total_sales::numeric / lifespan
        END) AS avg_monthly_revenue
   FROM product_aggregation;