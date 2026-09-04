-- Olist E-Commerce Data Warehouse — SQLite schema
-- 9 relational source tables, loaded as provided by Olist (raw layer).
-- Foreign keys are declared for documentation + join-integrity checks,
-- even though SQLite doesn't enforce them unless PRAGMA foreign_keys=ON.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS geolocation;
DROP TABLE IF EXISTS category_translation;

CREATE TABLE category_translation (
    product_category_name          TEXT PRIMARY KEY,
    product_category_name_english  TEXT
);

-- customer_id is re-issued per order; customer_unique_id is the real person.
CREATE TABLE customers (
    customer_id                TEXT PRIMARY KEY,
    customer_unique_id         TEXT NOT NULL,
    customer_zip_code_prefix   INTEGER,
    customer_city              TEXT,
    customer_state             TEXT
);
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX idx_customers_state ON customers(customer_state);

-- Zip-code-prefix -> lat/lng lookup. Multiple samples per prefix in the raw
-- file; deduplicated to state centroids during cleaning.
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat             REAL,
    geolocation_lng             REAL,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);
CREATE INDEX idx_geo_zip ON geolocation(geolocation_zip_code_prefix);

CREATE TABLE sellers (
    seller_id               TEXT PRIMARY KEY,
    seller_zip_code_prefix  INTEGER,
    seller_city             TEXT,
    seller_state            TEXT
);

CREATE TABLE products (
    product_id                   TEXT PRIMARY KEY,
    product_category_name        TEXT,
    product_name_lenght          REAL,
    product_description_lenght   REAL,
    product_photos_qty           REAL,
    product_weight_g             REAL,
    product_length_cm            REAL,
    product_height_cm            REAL,
    product_width_cm             REAL,
    FOREIGN KEY (product_category_name) REFERENCES category_translation(product_category_name)
);

CREATE TABLE orders (
    order_id                        TEXT PRIMARY KEY,
    customer_id                     TEXT NOT NULL,
    order_status                    TEXT,
    order_purchase_timestamp        TEXT,
    order_approved_at               TEXT,
    order_delivered_carrier_date    TEXT,
    order_delivered_customer_date   TEXT,
    order_estimated_delivery_date   TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase_ts ON orders(order_purchase_timestamp);

CREATE TABLE order_items (
    order_id             TEXT NOT NULL,
    order_item_id        INTEGER NOT NULL,
    product_id           TEXT,
    seller_id            TEXT,
    shipping_limit_date  TEXT,
    price                REAL,
    freight_value        REAL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);
CREATE INDEX idx_items_product ON order_items(product_id);
CREATE INDEX idx_items_seller ON order_items(seller_id);

CREATE TABLE order_payments (
    order_id               TEXT NOT NULL,
    payment_sequential     INTEGER NOT NULL,
    payment_type           TEXT,
    payment_installments   INTEGER,
    payment_value          REAL,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id                 TEXT,
    order_id                  TEXT NOT NULL,
    review_score              INTEGER,
    review_comment_title      TEXT,
    review_comment_message    TEXT,
    review_creation_date      TEXT,
    review_answer_timestamp   TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE INDEX idx_reviews_order ON order_reviews(order_id);
CREATE INDEX idx_reviews_score ON order_reviews(review_score);
