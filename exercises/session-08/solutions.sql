-- SQL Practice 80, Part 1: solutions
-- Run against the "shop" database from the sql-course folder.
-- Try each exercise yourself first. Other correct solutions are possible.

-- ============================================================ A. SELECT and sorting

-- 1
SELECT * FROM products LIMIT 10;

-- 2
SELECT product_name, category, unit_price FROM products;

-- 3
SELECT DISTINCT category FROM products;

-- 4
SELECT DISTINCT country FROM customers ORDER BY country;

-- 5
SELECT product_name, unit_price FROM products ORDER BY unit_price DESC LIMIT 5;

-- 6
SELECT product_name AS product,
       unit_price,
       ROUND(unit_price * 1.09, 2) AS price_with_tax
FROM products;

-- 7
SELECT country, city, full_name FROM customers ORDER BY country, city, full_name;

-- 8
SELECT order_id, customer_id, order_at, order_amount
FROM orders
ORDER BY order_at DESC
LIMIT 5;

-- 9
SELECT product_name, unit_price
FROM products
ORDER BY unit_price
LIMIT 10 OFFSET 10;

-- 10
SELECT DISTINCT country, city FROM customers ORDER BY country, city;

-- ============================================================ B. Filtering

-- 11
SELECT COUNT(*) FROM orders WHERE status = 'cancelled';

-- 12
SELECT product_name, unit_price FROM products WHERE category = 'Books' AND unit_price < 15;

-- 13
SELECT COUNT(*) FROM customers WHERE city = 'Shiraz' OR city = 'Tabriz';
SELECT COUNT(*) FROM customers WHERE city IN ('Shiraz', 'Tabriz');

-- 14
SELECT COUNT(*) FROM orders WHERE status NOT IN ('paid', 'refunded');

-- 15
SELECT COUNT(*) FROM customers WHERE email LIKE 'sara.%';

-- 16
SELECT product_name FROM products WHERE product_name LIKE '%Set%';

-- 17
SELECT product_name FROM products WHERE product_name LIKE '____';

-- 18
SELECT COUNT(*) FROM orders WHERE order_amount BETWEEN 200 AND 300;

-- 19
SELECT COUNT(*) FROM customers WHERE city IS NULL;
SELECT COUNT(*) FROM customers WHERE city IS NOT NULL AND country IS NOT NULL;

-- 20
SELECT COUNT(*) FROM orders
WHERE (status = 'paid' OR status = 'refunded') AND order_amount > 500;

SELECT COUNT(*) FROM orders
WHERE status = 'paid' OR status = 'refunded' AND order_amount > 500;

-- ============================================================ C. Functions and CASE

-- 21
SELECT UPPER(product_name) AS name_upper, LENGTH(product_name) AS name_length
FROM products
ORDER BY name_length DESC;

-- 22
SELECT product_name || ' (' || category || ')' AS label FROM products;

-- 23
SELECT SPLIT_PART(full_name, ' ', 1) AS first_name, COUNT(*) AS customers
FROM customers
GROUP BY 1
ORDER BY customers DESC;

-- 24
SELECT product_name, unit_price,
       ROUND(unit_price) AS rounded,
       CEIL(unit_price)  AS rounded_up,
       FLOOR(unit_price) AS rounded_down
FROM products;

-- 25
SELECT CASE WHEN unit_price < 20  THEN 'cheap'
            WHEN unit_price < 100 THEN 'mid'
            ELSE 'premium' END AS price_band,
       COUNT(*) AS products
FROM products
GROUP BY 1
ORDER BY products DESC;

-- 26
SELECT CASE WHEN order_amount < 100 THEN 'small'
            WHEN order_amount < 300 THEN 'medium'
            ELSE 'large' END AS size,
       COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY orders DESC;

-- 27
SELECT full_name, COALESCE(city, 'unknown') AS city FROM customers;

-- 28
SELECT COALESCE(city, country, 'unknown') AS location, COUNT(*) AS customers
FROM customers
GROUP BY 1
ORDER BY customers DESC;

-- 29
SELECT ROUND(AVG(order_amount), 2)             AS avg_all,
       ROUND(AVG(NULLIF(order_amount, 0)), 2)  AS avg_without_zero
FROM orders;

-- 30
SELECT ROUND(AVG(CASE WHEN status = 'paid' THEN 1 ELSE 0 END), 3) AS paid_rate FROM orders;

-- ============================================================ D. Aggregation

-- 31
SELECT COUNT(*) AS customers, MIN(signup_at) AS first_signup, MAX(signup_at) AS last_signup
FROM customers;

-- 32
SELECT SUM(order_amount) AS total, ROUND(AVG(order_amount), 2) AS average
FROM orders
WHERE status = 'paid';

-- 33
SELECT category, COUNT(*) AS products, ROUND(AVG(unit_price), 2) AS avg_price
FROM products
GROUP BY category
ORDER BY category;

-- 34
SELECT status, COUNT(*) AS orders FROM orders GROUP BY status ORDER BY orders DESC;

-- 35
SELECT city, COUNT(*) AS customers
FROM customers
GROUP BY city
HAVING COUNT(*) > 400
ORDER BY customers DESC;

-- 36
SELECT customer_id, COUNT(*) AS orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 30
ORDER BY orders DESC;

-- 37
SELECT method, COUNT(*) AS payments, SUM(amount) AS total
FROM payments
GROUP BY method
ORDER BY total DESC;

-- 38
SELECT COUNT(DISTINCT customer_id)
FROM orders
WHERE order_at >= '2026-01-01' AND order_at < '2027-01-01';

-- 39
SELECT method,
       SUM(CASE WHEN amount > 500 THEN 1 ELSE 0 END)  AS above_500,
       SUM(CASE WHEN amount <= 500 THEN 1 ELSE 0 END) AS up_to_500
FROM payments
GROUP BY method;

-- 40
SELECT category, COUNT(*) AS products, ROUND(AVG(unit_price), 2) AS avg_price
FROM products
GROUP BY category
HAVING COUNT(*) > 5 AND AVG(unit_price) > 30;

-- ============================================================ E. Dates

-- 41
SELECT date_trunc('month', order_at) AS month, COUNT(*) AS orders
FROM orders
WHERE order_at >= '2026-01-01' AND order_at < '2027-01-01'
GROUP BY 1
ORDER BY 1;

-- 42
SELECT COUNT(*) FROM customers WHERE signup_at >= '2026-08-01' AND signup_at < '2026-09-01';

-- 43
SELECT EXTRACT(YEAR FROM order_at) AS year, COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY 1;

-- 44
SELECT TO_CHAR(order_at, 'Day') AS weekday, COUNT(*) AS orders
FROM orders
GROUP BY 1
ORDER BY orders DESC;

-- 45
SELECT COUNT(*)
FROM customers
WHERE signup_at < TIMESTAMP '2026-09-30' - INTERVAL '2 years';

-- 46
SELECT full_name, signup_at, AGE(TIMESTAMP '2026-09-30', signup_at) AS account_age
FROM customers
WHERE customer_id = 1;

-- ============================================================ F. JOINs

-- 47
SELECT o.order_id, c.full_name, c.city
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id;

-- 48
SELECT i.line_no, p.product_name, i.quantity, i.unit_price,
       i.quantity * i.unit_price AS line_total
FROM order_items i
JOIN products p ON p.product_id = i.product_id
WHERE i.order_id = 100
ORDER BY i.line_no;

-- 49
SELECT p.category, SUM(i.quantity * i.unit_price) AS revenue
FROM order_items i
JOIN orders o   ON o.order_id = i.order_id
JOIN products p ON p.product_id = i.product_id
WHERE o.status = 'paid'
GROUP BY p.category
ORDER BY revenue DESC;

-- 50
SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS orders
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY orders;

-- 51
SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS orders
FROM orders o
RIGHT JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY orders;

-- 52
SELECT COUNT(*)
FROM orders o
LEFT JOIN order_items i ON i.order_id = o.order_id
WHERE i.order_id IS NULL;

-- 53
SELECT o.status, COUNT(*) AS orders_without_payment
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_id IS NULL
GROUP BY o.status;

-- 54
SELECT s1.customer_id,
       s1.segment    AS from_segment,
       s2.segment    AS to_segment,
       s2.valid_from AS changed_at
FROM customer_segments s1
JOIN customer_segments s2
  ON s2.customer_id = s1.customer_id
 AND s2.valid_from  = s1.valid_to
ORDER BY s1.customer_id, s2.valid_from;

-- 55
SELECT COALESCE(a.city, b.city) AS city,
       a.customers AS customers_iran,
       b.customers AS customers_turkey
FROM (SELECT city, COUNT(*) AS customers FROM customers WHERE country = 'Iran' GROUP BY city) a
FULL JOIN (SELECT city, COUNT(*) AS customers FROM customers WHERE country = 'Turkey' GROUP BY city) b
  ON a.city = b.city;

-- 56
SELECT c.city, SUM(o.order_amount) AS revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid'
GROUP BY c.city
ORDER BY revenue DESC;

-- 57
SELECT p.product_name, SUM(i.quantity) AS units
FROM customers c
JOIN orders o      ON o.customer_id = c.customer_id
JOIN order_items i ON i.order_id = o.order_id
JOIN products p    ON p.product_id = i.product_id
WHERE c.city = 'Istanbul'
GROUP BY p.product_name
ORDER BY units DESC;

-- 58
SELECT c.category, m.method
FROM (SELECT DISTINCT category FROM products) c
CROSS JOIN (SELECT DISTINCT method FROM payments) m
ORDER BY c.category, m.method;

-- ============================================================ G. Subqueries, EXISTS, set operations and CTE

-- 59
SELECT product_name, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY unit_price DESC;

-- 60
SELECT customer_id, full_name
FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders WHERE order_amount > 1000);

-- 61
SELECT COUNT(*)
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id AND o.status = 'refunded');

-- 62
SELECT COUNT(*)
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- 63
SELECT city FROM customers WHERE country = 'Iran'
UNION
SELECT city FROM customers WHERE country = 'Turkey';

SELECT COUNT(*) FROM (
    SELECT city FROM customers WHERE country = 'Iran'
    UNION ALL
    SELECT city FROM customers WHERE country = 'Turkey'
) t;

-- 64
SELECT COUNT(*) FROM products
WHERE category = 'Home'
  AND unit_price > ANY (SELECT unit_price FROM products WHERE category = 'Fashion');

SELECT COUNT(*) FROM products
WHERE category = 'Home'
  AND unit_price > ALL (SELECT unit_price FROM products WHERE category = 'Fashion');

-- 65
SELECT COUNT(*) FROM (
    SELECT customer_id FROM orders WHERE status = 'refunded'
    INTERSECT
    SELECT customer_id FROM orders WHERE status = 'cancelled'
) t;

-- 66
SELECT COUNT(*) FROM (
    SELECT customer_id FROM customers
    EXCEPT
    SELECT customer_id FROM orders
) t;

-- 67
SELECT p.category, p.product_name, p.unit_price
FROM products p
WHERE p.unit_price = (SELECT MAX(unit_price) FROM products WHERE category = p.category)
ORDER BY p.category;

-- 68
SELECT ROUND(AVG(order_count), 2) AS avg_orders_per_customer
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) t;

-- 69
WITH spend AS (
    SELECT customer_id, SUM(order_amount) AS total
    FROM orders
    WHERE status = 'paid'
    GROUP BY customer_id
)
SELECT c.full_name, s.total
FROM spend s
JOIN customers c ON c.customer_id = s.customer_id
ORDER BY s.total DESC
LIMIT 10;

-- 70
WITH by_category AS (
    SELECT p.category, SUM(i.quantity * i.unit_price) AS revenue
    FROM order_items i
    JOIN orders o   ON o.order_id = i.order_id
    JOIN products p ON p.product_id = i.product_id
    WHERE o.status = 'paid'
    GROUP BY p.category
)
SELECT category, revenue,
       ROUND(100 * revenue / (SELECT SUM(revenue) FROM by_category), 1) AS pct
FROM by_category
ORDER BY pct DESC;

-- ============================================================ H. Tables, data changes and transactions

-- 71
CREATE TABLE vip_customers (
    customer_id  INT PRIMARY KEY REFERENCES customers (customer_id),
    full_name    TEXT NOT NULL,
    total_spent  NUMERIC(12,2) NOT NULL CHECK (total_spent >= 0),
    added_at     TIMESTAMP DEFAULT now()
);

-- 72
INSERT INTO vip_customers (customer_id, full_name, total_spent)
SELECT c.customer_id, c.full_name, SUM(o.order_amount)
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.full_name
HAVING SUM(o.order_amount) > 3000;

SELECT COUNT(*) FROM vip_customers;

-- 73 (each of these statements is expected to fail)
-- INSERT INTO vip_customers (customer_id, full_name, total_spent) VALUES (4999, 'Test', -10);       -- CHECK
-- INSERT INTO vip_customers (customer_id, full_name, total_spent) VALUES (99999, 'Test', 10);       -- FOREIGN KEY
-- INSERT INTO vip_customers (customer_id, full_name, total_spent) VALUES (1, 'Duplicate', 10);      -- PRIMARY KEY
-- INSERT INTO vip_customers (customer_id, total_spent) VALUES (4999, 10);                           -- NOT NULL

-- 74
ALTER TABLE vip_customers ADD COLUMN tier TEXT;

UPDATE vip_customers
SET tier = CASE WHEN total_spent > 5000 THEN 'gold' ELSE 'silver' END;

SELECT tier, COUNT(*) FROM vip_customers GROUP BY tier;

-- 75
CREATE VIEW monthly_paid_revenue AS
SELECT date_trunc('month', order_at) AS month, SUM(order_amount) AS revenue
FROM orders
WHERE status = 'paid'
GROUP BY 1;

SELECT * FROM monthly_paid_revenue ORDER BY month DESC LIMIT 3;
SELECT COUNT(*) FROM monthly_paid_revenue;

-- 76
CREATE TABLE orders_sep_2026 AS
SELECT *
FROM orders
WHERE order_at >= '2026-09-01' AND order_at < '2026-10-01';

SELECT COUNT(*) FROM orders_sep_2026;

-- 77
BEGIN;
DELETE FROM vip_customers WHERE tier = 'silver';
SELECT COUNT(*) FROM vip_customers;
ROLLBACK;
SELECT COUNT(*) FROM vip_customers;

-- 78
DROP VIEW monthly_paid_revenue;
DROP TABLE orders_sep_2026;
DROP TABLE vip_customers;

-- ============================================================ I. Window functions

-- 79
SELECT order_id, order_at, order_amount,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_at)      AS nth_order,
       LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_at) AS prev_amount,
       SUM(order_amount) OVER (PARTITION BY customer_id ORDER BY order_at
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM orders
WHERE customer_id = 1
ORDER BY order_at;

-- 80
SELECT COUNT(*)
FROM (
    SELECT customer_id,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_at) AS rn
    FROM orders
) t
WHERE rn = 1;
