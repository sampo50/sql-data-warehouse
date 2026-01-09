CREATE OR REPLACE VIEW gold.vw_customer_profile AS
WITH base_query AS (
    SELECT
        t.order_number,
        t.product_key,
        t.order_date,
        t.sales_amount,
        t.quantity,
        dc.customer_key,
        dc.customer_number,
        CONCAT(dc.first_name, ' ', dc.last_name) AS customer_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, dc.birth_date)) AS age_years
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_customers dc 
        ON t.customer_key = dc.customer_key
    WHERE t.order_date IS NOT NULL
),
customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age_years,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity,
        COUNT(DISTINCT product_key)  AS total_products,
        MAX(order_date)              AS last_order_date,
        EXTRACT(YEAR  FROM AGE(MAX(order_date), MIN(order_date))) * 12
        + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan
    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age_years
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age_years,
    CASE
        WHEN age_years < 20 THEN 'Under 20'
        WHEN age_years BETWEEN 20 AND 29 THEN '20-29'
        WHEN age_years BETWEEN 30 AND 39 THEN '30-39'
        WHEN age_years BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE 
        WHEN total_sales >= 5000
             AND lifespan >= 12 THEN 'VIP'
        WHEN total_sales < 5000
             AND lifespan >= 12 THEN 'Regular'
        WHEN lifespan < 12 THEN 'New'
        ELSE 'Unclassified'
    END AS customer_segment,
    EXTRACT(YEAR  FROM AGE(CURRENT_DATE, last_order_date)) * 12
    + EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date)) AS since_last_order,
    total_orders,
    total_sales,
    total_quantity,
    last_order_date,
    lifespan,
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,
    ROUND(
        CASE 
            WHEN lifespan = 0 THEN total_sales
            ELSE total_sales / lifespan
        END
    , 2) AS avg_monthly_spend
FROM customer_aggregation;
