-- "Shop" online store: practice dataset for the SQL course
-- This file only creates the table structure. Data is generated in 02_data.sql.

CREATE TABLE customers (
    customer_id  INT PRIMARY KEY,
    full_name    TEXT NOT NULL,
    email        TEXT NOT NULL,
    city         TEXT,                 -- some rows are NULL
    country      TEXT,                 -- some rows are NULL
    signup_at    TIMESTAMP NOT NULL
);

CREATE TABLE products (
    product_id    INT PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category      TEXT NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);

-- Grain: one row = one order
CREATE TABLE orders (
    order_id      INT PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers (customer_id),
    order_at      TIMESTAMP NOT NULL,
    status        TEXT NOT NULL CHECK (status IN ('paid', 'pending', 'cancelled', 'refunded')),
    order_amount  NUMERIC(12,2) NOT NULL
);

-- Grain: one row = one line item in an order (an order can have several rows)
CREATE TABLE order_items (
    order_id    INT NOT NULL REFERENCES orders (order_id),
    line_no     INT NOT NULL,
    product_id  INT NOT NULL REFERENCES products (product_id),
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, line_no)
);

-- Grain: one row = one payment (some orders are paid in installments)
CREATE TABLE payments (
    payment_id  INT PRIMARY KEY,
    order_id    INT NOT NULL REFERENCES orders (order_id),
    paid_at     TIMESTAMP NOT NULL,
    method      TEXT NOT NULL,
    amount      NUMERIC(12,2) NOT NULL
);

-- Grain: one row = one website event (~2 million rows, for the SQL in Scale section)
-- Intentionally has no index on customer_id.
CREATE TABLE events (
    event_id     BIGINT PRIMARY KEY,
    customer_id  INT NOT NULL,
    event_at     TIMESTAMP NOT NULL,
    event_type   TEXT NOT NULL,        -- page_view, add_to_cart, checkout, purchase
    page         TEXT NOT NULL,
    device       TEXT NOT NULL,
    referrer     TEXT
);

-- Raw order feed from the source system: duplicates and multiple versions per order
-- Used for deduplication and idempotent-load exercises
CREATE TABLE orders_staging (
    order_id      INT NOT NULL,
    customer_id   INT NOT NULL,
    order_at      TIMESTAMP NOT NULL,
    status        TEXT NOT NULL,
    order_amount  NUMERIC(12,2) NOT NULL,
    updated_at    TIMESTAMP NOT NULL,
    batch_id      INT NOT NULL
);

-- Customer segment history (SCD Type 2) for point-in-time join exercises
CREATE TABLE customer_segments (
    customer_id  INT NOT NULL REFERENCES customers (customer_id),
    segment      TEXT NOT NULL,        -- bronze, silver, gold
    valid_from   TIMESTAMP NOT NULL,
    valid_to     TIMESTAMP             -- NULL means current version
);

-- Target table for the load exercise (empty at start)
CREATE TABLE orders_clean (
    order_id      INT PRIMARY KEY,
    customer_id   INT NOT NULL,
    order_at      TIMESTAMP NOT NULL,
    status        TEXT NOT NULL,
    order_amount  NUMERIC(12,2) NOT NULL,
    updated_at    TIMESTAMP NOT NULL
);
