-- Session 1 exercise solutions
-- Try to solve them yourself first, then check here.

-- 1) Last 10 paid orders with an amount above 500
SELECT order_id, customer_id, order_at, order_amount
FROM orders
WHERE status = 'paid'
  AND order_amount > 500
ORDER BY order_at DESC
LIMIT 10;

-- 2) Number of customers per country; NULL shown as 'unknown'
SELECT COALESCE(country, 'unknown') AS country, COUNT(*) AS customers
FROM customers
GROUP BY COALESCE(country, 'unknown')
ORDER BY customers DESC;

-- 3) Monthly revenue of paid orders in 2026, only months with revenue above 400,000
SELECT date_trunc('month', order_at) AS month, SUM(order_amount) AS revenue
FROM orders
WHERE status = 'paid'
  AND order_at >= '2026-01-01' AND order_at < '2027-01-01'
GROUP BY date_trunc('month', order_at)
HAVING SUM(order_amount) > 400000
ORDER BY month;

-- 4) Product price bands with CASE
SELECT product_name, unit_price,
       CASE WHEN unit_price < 20  THEN 'cheap'
            WHEN unit_price < 100 THEN 'mid'
            ELSE 'premium' END AS price_band
FROM products
ORDER BY unit_price;

-- 5) Order count and total spend per customer, including customers with no orders
SELECT c.customer_id, c.full_name,
       COUNT(o.order_id)                AS orders,
       COALESCE(SUM(o.order_amount), 0) AS total_amount
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_amount DESC;

-- 6) Customers who never placed an order (anti-join)
SELECT COUNT(*) AS never_ordered
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- 7) Fan-out trap
-- Wrong: orders with several items and installments are counted multiple times
SELECT SUM(o.order_amount) AS total_orders, SUM(p.amount) AS total_paid
FROM orders o
JOIN order_items i ON i.order_id = o.order_id
JOIN payments p    ON p.order_id = o.order_id
WHERE o.status = 'paid';

-- Right: aggregate each table to the order grain first, then JOIN
WITH paid_per_order AS (
    SELECT order_id, SUM(amount) AS paid
    FROM payments
    GROUP BY order_id
)
SELECT SUM(o.order_amount) AS total_orders, SUM(p.paid) AS total_paid
FROM orders o
JOIN paid_per_order p ON p.order_id = o.order_id
WHERE o.status = 'paid';

-- Grain check after JOIN: if these two numbers differ, you have fan-out
SELECT COUNT(*) AS rows_after_join, COUNT(DISTINCT o.order_id) AS distinct_orders
FROM orders o
JOIN payments p ON p.order_id = o.order_id;

-- 8) LEFT JOIN trap: number of paid orders per customer, including zeros
-- Wrong: WHERE removes customers without a paid order
SELECT COUNT(DISTINCT c.customer_id) AS customers_in_result
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'paid';

-- Right: put the condition on the right-hand table inside ON
SELECT c.customer_id, COUNT(o.order_id) AS paid_orders
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'paid'
GROUP BY c.customer_id
ORDER BY paid_orders;

-- 9) NULL traps
-- Customers outside Iran: <> also drops rows where country is NULL
SELECT COUNT(*) FROM customers WHERE country <> 'Iran';
SELECT COUNT(*) FROM customers WHERE country IS DISTINCT FROM 'Iran';

-- NOT IN returns no rows when the subquery contains a NULL
SELECT COUNT(*) AS not_in_result
FROM customers
WHERE city NOT IN (SELECT city FROM customers WHERE country = 'Turkey');

SELECT COUNT(*) AS not_exists_result
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM customers t
    WHERE t.country = 'Turkey' AND t.city = c.city
);

-- COUNT(*) is different from COUNT(column)
SELECT COUNT(*) AS all_rows, COUNT(city) AS rows_with_city FROM customers;

-- 10) Date range trap: revenue for September 2026
-- Wrong: the whole of day 30 is missed, because '2026-09-30' means midnight at the start of that day
SELECT SUM(order_amount) FROM orders
WHERE order_at BETWEEN '2026-09-01' AND '2026-09-30';

-- Still wrong: order 777 at 23:59:59.5 is missed
SELECT SUM(order_amount) FROM orders
WHERE order_at BETWEEN '2026-09-01' AND '2026-09-30 23:59:59';

-- Right: half-open interval
SELECT SUM(order_amount) FROM orders
WHERE order_at >= '2026-09-01' AND order_at < '2026-10-01';

-- 11) Safe UPDATE: check with SELECT first, then change inside a transaction
BEGIN;
SELECT COUNT(*) FROM orders WHERE status = 'pending' AND order_at < '2025-02-01';
UPDATE orders SET status = 'cancelled' WHERE status = 'pending' AND order_at < '2025-02-01';
ROLLBACK;  -- this is only practice, so undo it

-- 12) Window: first order of each customer
SELECT customer_id, order_id, order_at
FROM (
    SELECT customer_id, order_id, order_at,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_at) AS rn
    FROM orders
) t
WHERE rn = 1;
