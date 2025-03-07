CREATE TABLE transactions (
    transaction_id VARCHAR(50),
    customer_id INT NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    price INT NOT NULL,
    qty INT NOT NULL,
    total_amount INT NOT NULL,
    store_id INT NOT NULL,
    age INT NOT NULL,
    gender INT NOT NULL CHECK (gender IN (0,1)), -- 0 untuk perempuan, 1 untuk laki-laki
    marital_status VARCHAR(20) NOT NULL,
    income FLOAT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    store_name VARCHAR(100) NOT NULL,
    group_store VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL
);

WITH month_order AS (
    SELECT 
        DISTINCT
        customer_id,
        DATE_TRUNC('month', transaction_date)::date AS cohort_month
    FROM transactions
),
cohort_data AS (
    SELECT 
        m0.cohort_month,
        DATE_TRUNC('month', m1.transaction_date)::date AS order_month,
        COUNT(DISTINCT m1.customer_id) AS user_count
    FROM month_order AS m0
    JOIN transactions AS m1
        ON m0.customer_id = m1.customer_id
    WHERE m1.transaction_date >= m0.cohort_month
    GROUP BY m0.cohort_month, DATE_TRUNC('month', m1.transaction_date)
),
cohort_base AS (
    SELECT 
        cohort_month,
        MAX(CASE WHEN order_month = cohort_month THEN user_count ELSE 0 END) AS initial_users
    FROM cohort_data
    GROUP BY cohort_month
)
SELECT 
    c.cohort_month,
    DATE_PART('month', AGE(c.order_month, c.cohort_month)) AS month_offset,
    c.user_count,
    (c.user_count::NUMERIC / b.initial_users) AS retention_rate
FROM cohort_data c
JOIN cohort_base b
    ON c.cohort_month = b.cohort_month
ORDER BY c.cohort_month, month_offset;

