-- Random but reproducible data (setseed gives everyone exactly the same dataset)
SELECT setseed(0.42);

-- ---------------------------------------------------------------- customers (5,000)
INSERT INTO customers (customer_id, full_name, email, city, country, signup_at)
SELECT
    g,
    fn || ' ' || ln,
    lower(fn) || '.' || lower(ln) || g || '@example.com',
    CASE WHEN r_city < 0.08 THEN NULL ELSE c.city END,
    CASE WHEN r_ctry < 0.03 THEN NULL ELSE c.country END,
    date_trunc('second', TIMESTAMP '2024-06-01' + (random() * 820) * INTERVAL '1 day')
FROM (
    SELECT g,
           (ARRAY['Ali','Sara','Reza','Maryam','Hossein','Zahra','Amir','Niloofar','Mehdi','Fatemeh',
                  'Kian','Leila','Arash','Shirin','Omid','Parisa','Babak','Yasaman','Navid','Elham'])[1 + floor(random() * 20)::int] AS fn,
           (ARRAY['Ahmadi','Rezaei','Mohammadi','Hosseini','Karimi','Moradi','Jafari','Rahimi','Kazemi','Ebrahimi',
                  'Sadeghi','Mousavi','Ghasemi','Hashemi','Nazari'])[1 + floor(random() * 15)::int] AS ln,
           1 + floor(random() * 10)::int AS city_idx,
           random() AS r_city,
           random() AS r_ctry
    FROM generate_series(1, 5000) AS g
) s
JOIN (VALUES
    (1, 'Tehran', 'Iran'), (2, 'Tehran', 'Iran'), (3, 'Tehran', 'Iran'),
    (4, 'Isfahan', 'Iran'), (5, 'Shiraz', 'Iran'), (6, 'Tabriz', 'Iran'),
    (7, 'Mashhad', 'Iran'), (8, 'Istanbul', 'Turkey'), (9, 'Dubai', 'UAE'), (10, 'Toronto', 'Canada')
) AS c (idx, city, country) ON c.idx = s.city_idx;

-- ---------------------------------------------------------------- products (60)
INSERT INTO products (product_id, product_name, category, unit_price)
SELECT
    row_number() OVER (ORDER BY cat.ord, n),
    cat.names[n],
    cat.category,
    round((cat.base * (0.5 + random()))::numeric, 2)
FROM (VALUES
    (1, 'Electronics', 120.0, ARRAY['Headphones','Keyboard','Mouse','Monitor','Charger','Power Bank','Speaker','Webcam','USB Hub','SSD']),
    (2, 'Books',        15.0, ARRAY['SQL Basics','Python Guide','Data Stories','Clean Code','Statistics 101','Novel A','Novel B','Poetry Set','Cookbook','Atlas']),
    (3, 'Home',         40.0, ARRAY['Lamp','Mug Set','Pillow','Blanket','Plant Pot','Clock','Frame','Towel Set','Kettle','Vase']),
    (4, 'Fashion',      35.0, ARRAY['T-Shirt','Jeans','Sneakers','Scarf','Cap','Jacket','Socks Pack','Belt','Backpack','Sunglasses']),
    (5, 'Beauty',       20.0, ARRAY['Shampoo','Face Cream','Perfume','Lip Balm','Sunscreen','Soap Set','Hair Oil','Mask Pack','Lotion','Brush Set']),
    (6, 'Sports',       30.0, ARRAY['Yoga Mat','Dumbbell','Water Bottle','Jump Rope','Resistance Band','Ball','Gloves','Sports Cap','Gym Bag','Gym Towel'])
) AS cat (ord, category, base, names)
CROSS JOIN generate_series(1, 10) AS n;

-- ---------------------------------------------------------------- orders (50,000)
-- Customers 4251 to 5000 never place an order (for anti-join exercises)
INSERT INTO orders (order_id, customer_id, order_at, status, order_amount)
SELECT
    o.order_id,
    o.customer_id,
    date_trunc('second',
        greatest(c.signup_at, TIMESTAMP '2025-01-01')
        + random() * (TIMESTAMP '2026-09-30 23:59:59' - greatest(c.signup_at, TIMESTAMP '2025-01-01'))),
    CASE WHEN r < 0.80 THEN 'paid'
         WHEN r < 0.87 THEN 'pending'
         WHEN r < 0.95 THEN 'cancelled'
         ELSE 'refunded' END,
    0
FROM (
    SELECT g AS order_id,
           1 + floor(power(random(), 1.3) * 4250)::int AS customer_id,
           random() AS r
    FROM generate_series(1, 50000) AS g
) o
JOIN customers c USING (customer_id);

-- Trap: an order in the last half-second of the month
UPDATE orders SET order_at = TIMESTAMP '2026-09-30 23:59:59.5' WHERE order_id = 777;

-- ---------------------------------------------------------------- order_items
-- Each order has 1 to 4 items; about 10% of pending/cancelled orders have no items
INSERT INTO order_items (order_id, line_no, product_id, quantity, unit_price)
SELECT o.order_id, l.line_no, p.product_id, q.quantity, p.unit_price
FROM (
    SELECT order_id, status,
           CASE WHEN status IN ('pending', 'cancelled') AND random() < 0.10 THEN 0
                ELSE 1 + floor(power(random(), 1.6) * 4)::int END AS n_items
    FROM orders
) o
CROSS JOIN LATERAL generate_series(1, o.n_items) AS l (line_no)
CROSS JOIN LATERAL (SELECT 1 + floor(random() * 60)::int + 0 * o.order_id + 0 * l.line_no AS product_id) pick
JOIN products p ON p.product_id = pick.product_id
CROSS JOIN LATERAL (SELECT 1 + floor(power(random(), 2) * 3)::int + 0 * l.line_no AS quantity) q;

UPDATE orders o
SET order_amount = s.total
FROM (SELECT order_id, sum(quantity * unit_price) AS total FROM order_items GROUP BY order_id) s
WHERE s.order_id = o.order_id;

-- ---------------------------------------------------------------- payments
-- Paid and refunded orders have payments: 85% single, 12% two installments, 3% three
INSERT INTO payments (payment_id, order_id, paid_at, method, amount)
SELECT
    row_number() OVER (ORDER BY o.order_id, k),
    o.order_id,
    o.order_at + INTERVAL '3 minutes' + (k - 1) * INTERVAL '30 days',
    o.method,
    CASE WHEN k < o.n_pay THEN round(o.order_amount / o.n_pay, 2)
         ELSE o.order_amount - round(o.order_amount / o.n_pay, 2) * (o.n_pay - 1) END
FROM (
    SELECT order_id, order_at, order_amount,
           CASE WHEN r < 0.85 THEN 1 WHEN r < 0.97 THEN 2 ELSE 3 END AS n_pay,
           (ARRAY['card', 'card', 'wallet', 'bank_transfer'])[1 + floor(random() * 4)::int] AS method
    FROM (SELECT *, random() AS r FROM orders WHERE status IN ('paid', 'refunded') AND order_amount > 0) x
) o
CROSS JOIN LATERAL generate_series(1, o.n_pay) AS k;

-- ---------------------------------------------------------------- events (~2,000,000)
INSERT INTO events (event_id, customer_id, event_at, event_type, page, device, referrer)
SELECT
    g,
    1 + floor(random() * 5000)::int,
    date_trunc('second', TIMESTAMP '2025-01-01' + random() * (TIMESTAMP '2026-09-30 23:59:59' - TIMESTAMP '2025-01-01')),
    et.event_type,
    CASE et.event_type
        WHEN 'page_view'   THEN (ARRAY['/home', '/search', '/category', '/product'])[1 + floor(random() * 4)::int]
        WHEN 'add_to_cart' THEN '/product'
        WHEN 'checkout'    THEN '/checkout'
        ELSE '/thank-you' END,
    CASE WHEN r_dev < 0.60 THEN 'mobile' WHEN r_dev < 0.95 THEN 'desktop' ELSE 'tablet' END,
    CASE WHEN r_ref < 0.35 THEN NULL
         WHEN r_ref < 0.65 THEN 'google'
         WHEN r_ref < 0.85 THEN 'instagram'
         ELSE 'telegram' END
FROM (
    SELECT g, random() AS r_type, random() AS r_dev, random() AS r_ref
    FROM generate_series(1, 1980000) AS g
) s
CROSS JOIN LATERAL (
    SELECT CASE WHEN s.r_type < 0.70 THEN 'page_view'
                WHEN s.r_type < 0.85 THEN 'add_to_cart'
                WHEN s.r_type < 0.93 THEN 'checkout'
                ELSE 'purchase' END AS event_type
) et;

-- Trap: about 1% of events were recorded twice (identical except event_id)
INSERT INTO events (event_id, customer_id, event_at, event_type, page, device, referrer)
SELECT 1980000 + row_number() OVER (ORDER BY event_id), customer_id, event_at, event_type, page, device, referrer
FROM events
WHERE event_id % 100 = 7;

-- ---------------------------------------------------------------- orders_staging
-- batch 1: all September 2026 orders with their initial status
INSERT INTO orders_staging (order_id, customer_id, order_at, status, order_amount, updated_at, batch_id)
SELECT order_id, customer_id, order_at,
       CASE WHEN status IN ('paid', 'refunded') THEN 'pending' ELSE status END,
       order_amount, order_at, 1
FROM orders
WHERE order_at >= TIMESTAMP '2026-09-01';

-- batch 2: status updates (pending -> final status)
INSERT INTO orders_staging (order_id, customer_id, order_at, status, order_amount, updated_at, batch_id)
SELECT order_id, customer_id, order_at, status, order_amount, order_at + INTERVAL '2 hours', 2
FROM orders
WHERE order_at >= TIMESTAMP '2026-09-01' AND status IN ('paid', 'refunded');

-- Trap: part of batch 2 was sent again (fully duplicated rows)
INSERT INTO orders_staging
SELECT * FROM orders_staging WHERE batch_id = 2 AND order_id % 20 = 0;

-- ---------------------------------------------------------------- customer_segments (SCD2)
INSERT INTO customer_segments (customer_id, segment, valid_from, valid_to)
SELECT customer_id, segment, valid_from,
       lead(valid_from) OVER (PARTITION BY customer_id ORDER BY valid_from)
FROM (
    SELECT c.customer_id, 'bronze' AS segment, c.signup_at AS valid_from FROM customers c
    UNION ALL
    SELECT c.customer_id, 'silver', date_trunc('second', c.signup_at + (60 + random() * 200) * INTERVAL '1 day')
    FROM customers c WHERE c.customer_id % 3 <> 0
    UNION ALL
    SELECT c.customer_id, 'gold', date_trunc('second', c.signup_at + (300 + random() * 200) * INTERVAL '1 day')
    FROM customers c WHERE c.customer_id % 5 = 1
) v
WHERE valid_from < TIMESTAMP '2026-10-01';

ANALYZE;
