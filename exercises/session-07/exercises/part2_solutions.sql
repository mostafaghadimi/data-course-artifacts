-- Session 2 exercise solutions
-- Try to solve them yourself first, then check here.

-- ============================================================ More traps

-- 1) Integer division: average quantity per order line
SELECT SUM(quantity) / COUNT(*)                  AS wrong_int_division,
       SUM(quantity)::numeric / COUNT(*)         AS right_decimal
FROM order_items;

-- 2) Average of averages: average order amount
-- Wrong: plain average of city averages (small and large cities get equal weight)
SELECT AVG(city_avg) AS avg_of_avgs
FROM (
    SELECT c.city, AVG(o.order_amount) AS city_avg
    FROM orders o JOIN customers c USING (customer_id)
    WHERE o.status = 'paid'
    GROUP BY c.city
) t;
-- Right: ratio of sums
SELECT SUM(order_amount) / COUNT(*) AS true_avg
FROM orders
WHERE status = 'paid';

-- 3) Division by zero: conversion rate per device = purchase / checkout
SELECT device,
       COUNT(*) FILTER (WHERE event_type = 'purchase')::numeric
         / NULLIF(COUNT(*) FILTER (WHERE event_type = 'checkout'), 0) AS conversion
FROM events
GROUP BY device;

-- 4) Default window frame: running total of order amounts, day by day
-- With ORDER BY on the date (no time), all orders of a day get the same value and the running total jumps
SELECT order_id, order_at::date AS d, order_amount,
       SUM(order_amount) OVER (ORDER BY order_at::date)                         AS default_range,
       SUM(order_amount) OVER (ORDER BY order_at::date, order_id
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rows_frame
FROM orders
WHERE order_at >= '2026-09-01' AND order_at < '2026-09-03'
ORDER BY order_at::date, order_id
LIMIT 20;

-- ============================================================ Classic patterns

-- 5) Top-N per group: top 3 products in each category
WITH product_revenue AS (
    SELECT p.category, p.product_name, SUM(i.quantity * i.unit_price) AS revenue
    FROM order_items i
    JOIN orders o   ON o.order_id = i.order_id AND o.status = 'paid'
    JOIN products p ON p.product_id = i.product_id
    GROUP BY p.category, p.product_name
)
SELECT *
FROM (
    SELECT *, DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
    FROM product_revenue
) t
WHERE rnk <= 3
ORDER BY category, rnk;

-- 6) Deduplication: latest version of each order in orders_staging
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC, batch_id DESC) AS rn
    FROM orders_staging
) t
WHERE rn = 1;

-- 7) MoM: monthly revenue growth versus the previous month
WITH monthly AS (
    SELECT date_trunc('month', order_at) AS month, SUM(order_amount) AS revenue
    FROM orders
    WHERE status = 'paid'
    GROUP BY 1
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
       ROUND(100 * (revenue / LAG(revenue) OVER (ORDER BY month) - 1), 1) AS growth_pct
FROM monthly
ORDER BY month;

-- 8) Running total: cumulative daily revenue in September 2026
SELECT d, revenue,
       SUM(revenue) OVER (ORDER BY d ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM (
    SELECT order_at::date AS d, SUM(order_amount) AS revenue
    FROM orders
    WHERE status = 'paid' AND order_at >= '2026-09-01' AND order_at < '2026-10-01'
    GROUP BY 1
) t
ORDER BY d;

-- 9) Funnel: how many customers reached each step in September 2026
SELECT
    COUNT(DISTINCT customer_id) FILTER (WHERE event_type = 'page_view')   AS viewed,
    COUNT(DISTINCT customer_id) FILTER (WHERE event_type = 'add_to_cart') AS added,
    COUNT(DISTINCT customer_id) FILTER (WHERE event_type = 'checkout')    AS checked_out,
    COUNT(DISTINCT customer_id) FILTER (WHERE event_type = 'purchase')    AS purchased
FROM events
WHERE event_at >= '2026-09-01' AND event_at < '2026-10-01';

-- 10) Pivot: revenue per category by quarter in 2026 (conditional aggregation)
SELECT p.category,
       SUM(i.quantity * i.unit_price) FILTER (WHERE o.order_at <  '2026-04-01')                              AS q1,
       SUM(i.quantity * i.unit_price) FILTER (WHERE o.order_at >= '2026-04-01' AND o.order_at < '2026-07-01') AS q2,
       SUM(i.quantity * i.unit_price) FILTER (WHERE o.order_at >= '2026-07-01')                              AS q3
FROM order_items i
JOIN orders o   ON o.order_id = i.order_id AND o.status = 'paid'
JOIN products p ON p.product_id = i.product_id
WHERE o.order_at >= '2026-01-01' AND o.order_at < '2026-10-01'
GROUP BY p.category
ORDER BY p.category;

-- 11) Gaps & Islands: longest streak of consecutive active days per customer
WITH active_days AS (
    SELECT DISTINCT customer_id, event_at::date AS d
    FROM events
),
grouped AS (
    SELECT customer_id, d,
           d - (ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY d))::int AS island
    FROM active_days
)
SELECT customer_id, MIN(d) AS streak_start, MAX(d) AS streak_end, COUNT(*) AS days
FROM grouped
GROUP BY customer_id, island
ORDER BY days DESC
LIMIT 10;

-- 12) Sessionization: split customer 42's events into sessions (a gap over 30 minutes = new session)
WITH ordered AS (
    SELECT event_id, event_at, event_type,
           CASE WHEN event_at - LAG(event_at) OVER (ORDER BY event_at) <= INTERVAL '30 minutes'
                THEN 0 ELSE 1 END AS is_new_session
    FROM events
    WHERE customer_id = 42 AND event_at >= '2026-09-01' AND event_at < '2026-10-01'
)
SELECT event_id, event_at, event_type,
       SUM(is_new_session) OVER (ORDER BY event_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS session_no
FROM ordered
ORDER BY event_at;

-- 13) Cohort: customers grouped by month of first order, and how many bought again in later months
WITH firsts AS (
    SELECT customer_id, date_trunc('month', MIN(order_at)) AS cohort
    FROM orders WHERE status = 'paid'
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT o.customer_id, f.cohort,
           (EXTRACT(YEAR FROM age(date_trunc('month', o.order_at), f.cohort)) * 12
            + EXTRACT(MONTH FROM age(date_trunc('month', o.order_at), f.cohort)))::int AS month_no
    FROM orders o JOIN firsts f USING (customer_id)
    WHERE o.status = 'paid'
)
SELECT cohort,
       COUNT(*) FILTER (WHERE month_no = 0) AS m0,
       COUNT(*) FILTER (WHERE month_no = 1) AS m1,
       COUNT(*) FILTER (WHERE month_no = 2) AS m2,
       COUNT(*) FILTER (WHERE month_no = 3) AS m3
FROM activity
WHERE cohort >= '2026-01-01' AND cohort < '2026-07-01'
GROUP BY cohort
ORDER BY cohort;

-- 14) Date spine: daily orders of customer 1 in September 2026, with zero for days without orders
SELECT d::date AS day, COUNT(o.order_id) AS orders
FROM generate_series(DATE '2026-09-01', DATE '2026-09-30', INTERVAL '1 day') AS d
LEFT JOIN orders o
       ON o.customer_id = 1
      AND o.order_at >= d AND o.order_at < d + INTERVAL '1 day'
GROUP BY d
ORDER BY d;

-- 15) Point-in-time join: the customer's segment at the moment of the order
-- Using the current segment to build features leaks future information into the model
SELECT o.order_id, o.order_at, s.segment AS segment_at_order_time, cur.segment AS current_segment
FROM orders o
JOIN customer_segments s
  ON s.customer_id = o.customer_id
 AND s.valid_from <= o.order_at
 AND (s.valid_to IS NULL OR o.order_at < s.valid_to)
JOIN customer_segments cur
  ON cur.customer_id = o.customer_id AND cur.valid_to IS NULL
WHERE o.customer_id = 1
ORDER BY o.order_at
LIMIT 20;

-- ============================================================ SQL in the pipeline

-- 16) Idempotent load: move the latest staging version of each order into orders_clean.
-- Run this statement twice; the row count must not change.
WITH latest AS (
    SELECT *
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC, batch_id DESC) AS rn
        FROM orders_staging
    ) t
    WHERE rn = 1
)
INSERT INTO orders_clean (order_id, customer_id, order_at, status, order_amount, updated_at)
SELECT order_id, customer_id, order_at, status, order_amount, updated_at
FROM latest
ON CONFLICT (order_id) DO UPDATE
SET status       = EXCLUDED.status,
    order_amount = EXCLUDED.order_amount,
    updated_at   = EXCLUDED.updated_at
WHERE orders_clean.updated_at < EXCLUDED.updated_at;

SELECT COUNT(*) FROM orders_clean;

-- 17) Data quality tests: every query should return zero rows
-- Unique key
SELECT order_id, COUNT(*) FROM orders_clean GROUP BY order_id HAVING COUNT(*) > 1;
-- not null
SELECT * FROM orders_clean WHERE customer_id IS NULL OR order_at IS NULL;
-- Referential integrity
SELECT oc.order_id FROM orders_clean oc
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = oc.customer_id);
-- Reconciliation: paid order amounts must equal the sum of their payments
SELECT o.order_id
FROM orders o
LEFT JOIN (SELECT order_id, SUM(amount) AS paid FROM payments GROUP BY order_id) p USING (order_id)
WHERE o.status = 'paid' AND o.order_amount IS DISTINCT FROM p.paid;

-- ============================================================ SQL in Scale (PostgreSQL)

-- 18) Index: compare EXPLAIN ANALYZE before and after
EXPLAIN ANALYZE SELECT COUNT(*) FROM events WHERE customer_id = 42;
CREATE INDEX IF NOT EXISTS idx_events_customer ON events (customer_id);
EXPLAIN ANALYZE SELECT COUNT(*) FROM events WHERE customer_id = 42;

-- 19) Sargable predicate: a function on the column prevents index use
CREATE INDEX IF NOT EXISTS idx_events_event_at ON events (event_at);
EXPLAIN ANALYZE SELECT COUNT(*) FROM events WHERE event_at::date = '2026-09-15';
EXPLAIN ANALYZE SELECT COUNT(*) FROM events WHERE event_at >= '2026-09-15' AND event_at < '2026-09-16';

-- 20) Shrink before JOIN: revenue per city
EXPLAIN ANALYZE
SELECT c.city, SUM(p.amount)
FROM customers c
JOIN orders o   ON o.customer_id = c.customer_id
JOIN payments p ON p.order_id = o.order_id
GROUP BY c.city;

-- 21) If EXCEPT is empty in both directions, the two queries return the same result
(SELECT customer_id, COUNT(*) FROM events WHERE event_at::date = '2026-09-15' GROUP BY 1
 EXCEPT
 SELECT customer_id, COUNT(*) FROM events WHERE event_at >= '2026-09-15' AND event_at < '2026-09-16' GROUP BY 1)
UNION ALL
(SELECT customer_id, COUNT(*) FROM events WHERE event_at >= '2026-09-15' AND event_at < '2026-09-16' GROUP BY 1
 EXCEPT
 SELECT customer_id, COUNT(*) FROM events WHERE event_at::date = '2026-09-15' GROUP BY 1);

-- ============================================================ SQL in Scale (ClickHouse)
-- Run this part in ClickHouse (http://localhost:8123/play), not in PostgreSQL.
-- Run the same query in both databases and compare the time:
--
--   SELECT device, count() AS views
--   FROM shop.events
--   WHERE event_type = 'page_view'
--   GROUP BY device;
--
-- And see how much less data is read when filtering on a column in the table's ORDER BY:
--
--   SELECT count() FROM shop.events WHERE event_type = 'purchase';      -- on the sorting key
--   SELECT count() FROM shop.events WHERE device = 'tablet';            -- not on the sorting key
--
-- Compare read_rows in the play output or in system.query_log.
