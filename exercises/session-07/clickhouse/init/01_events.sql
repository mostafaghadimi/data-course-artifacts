-- Column-store copy of the same data, for the SQL in Scale section.
-- Data is copied directly from PostgreSQL, so both databases hold identical data.

CREATE TABLE IF NOT EXISTS shop.events
(
    event_id     UInt64,
    customer_id  UInt32,
    event_at     DateTime,
    event_type   LowCardinality(String),
    page         LowCardinality(String),
    device       LowCardinality(String),
    referrer     Nullable(String)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_at)
ORDER BY (event_type, event_at);

INSERT INTO shop.events
SELECT event_id, customer_id, event_at, event_type, page, device, referrer
FROM postgresql('postgres:5432', 'shop', 'events', 'student', 'student');

CREATE TABLE IF NOT EXISTS shop.customers
(
    customer_id  UInt32,
    full_name    String,
    email        String,
    city         Nullable(String),
    country      Nullable(String),
    signup_at    DateTime
)
ENGINE = MergeTree
ORDER BY customer_id;

INSERT INTO shop.customers
SELECT customer_id, full_name, email, city, country, signup_at
FROM postgresql('postgres:5432', 'shop', 'customers', 'student', 'student');
