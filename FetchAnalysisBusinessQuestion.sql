-- Users Table
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    state VARCHAR(2),
    created_date TIMESTAMP,
    last_login TIMESTAMP,
    active BOOLEAN,
    role VARCHAR(20)
);

-- Brands Table
CREATE TABLE brands (
    brand_id UUID PRIMARY KEY,
    name VARCHAR(255),
    category VARCHAR(255),
    category_code VARCHAR(50),
    barcode VARCHAR(50),
    top_brand BOOLEAN,
    cpg VARCHAR(50),
    brand_code VARCHAR(50)
);

-- Receipts Table
CREATE TABLE receipts (
    receipt_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    bonuspointsearned   INT,
    bonuspointsearnedreason VARCHAR(50),
    createdate TIMESTAMP,
    datescanned TIMESTAMP,
    finisheddate TIMESTAMP,
    modifydate  TIMESTAMP,
    pointsawardeddate  TIMESTAMP,
    pointsearned   INT,
    purchasedate  TIMESTAMP,
    purchaseditemcount  INT,
    rewardsreceiptitemlist VARCHAR(50),
    rewardsreceiptstatus  VARCHAR(50),
    totalspent NUMERIC(10,2)
);

-- Receipt Items Table
CREATE TABLE receipt_items (
    receipt_item_id SERIAL PRIMARY KEY,
    receipt_id UUID REFERENCES receipts(receipt_id),
    brand_id UUID REFERENCES brands(brand_id),
    quantity INT,
    price NUMERIC(10,2),
    barcode VARCHAR(50)
);

-- Step 2: SQL Queries for Business Questions

-- 1. Top 5 brands by receipts scanned for the most recent month
WITH latest_month AS (
    SELECT DATE_TRUNC('month', MAX(date_scanned)) AS month_start FROM receipts
)
SELECT b.name, COUNT(r.receipt_id) AS receipt_count
FROM receipts r
JOIN receipt_items ri ON r.receipt_id = ri.receipt_id
JOIN brands b ON ri.brand_id = b.brand_id
WHERE DATE_TRUNC('month', r.date_scanned) = (SELECT month_start FROM latest_month)
GROUP BY b.name
ORDER BY receipt_count DESC
LIMIT 5;

-- 2. Ranking comparison of top 5 brands (current vs previous month)
WITH ranked_brands AS (
    SELECT
        DATE_TRUNC('month', r.date_scanned) AS month,
        b.name AS brand,
        COUNT(r.receipt_id) AS receipt_count,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', r.date_scanned) ORDER BY COUNT(r.receipt_id) DESC) AS rank
    FROM receipts r
    JOIN receipt_items ri ON r.receipt_id = ri.receipt_id
    JOIN brands b ON ri.brand_id = b.brand_id
    WHERE DATE_TRUNC('month', r.date_scanned) >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
    GROUP BY DATE_TRUNC('month', r.date_scanned), b.name
)
SELECT * FROM ranked_brands WHERE rank <= 5;

-- 3. Compare average spend for 'Accepted' vs 'Rejected' receipts
SELECT rewards_receipt_status, AVG(total_spent) AS avg_spend
FROM receipts
WHERE rewards_receipt_status IN ('Accepted', 'Rejected')
GROUP BY rewards_receipt_status;

-- 4. Total number of items purchased for 'Accepted' vs 'Rejected' receipts
SELECT rewards_receipt_status, SUM(purchased_item_count) AS total_items
FROM receipts
WHERE rewards_receipt_status IN ('Accepted', 'Rejected')
GROUP BY rewards_receipt_status;

-- 5. Brand with the most spend among users created in the past 6 months
WITH recent_users AS (
    SELECT user_id FROM users WHERE created_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT b.name, SUM(ri.price * ri.quantity) AS total_spent
FROM receipts r
JOIN receipt_items ri ON r.receipt_id = ri.receipt_id
JOIN brands b ON ri.brand_id = b.brand_id
WHERE r.user_id IN (SELECT user_id FROM recent_users)
GROUP BY b.name
ORDER BY total_spent DESC
LIMIT 1;

-- 6. Brand with the most transactions among users created in the past 6 months
WITH recent_users AS (
    SELECT user_id FROM users WHERE created_date >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT b.name, COUNT(r.receipt_id) AS transaction_count
FROM receipts r
JOIN receipt_items ri ON r.receipt_id = ri.receipt_id
JOIN brands b ON ri.brand_id = b.brand_id
WHERE r.user_id IN (SELECT user_id FROM recent_users)
GROUP BY b.name
ORDER BY transaction_count DESC
LIMIT 1;
