-- Top 3 product categories by revenue within each customer state.
-- revenue = SUM(order_items.price); freight excluded (pass-through cost,
-- not merchandise revenue). Delivered orders only.

WITH category_state_revenue AS (
    SELECT
        c.customer_state                                            AS state,
        COALESCE(t.product_category_name_english,
                 p.product_category_name, 'unknown')                AS category,
        SUM(oi.price)                                                AS revenue,
        COUNT(DISTINCT oi.order_id)                                  AS n_orders
    FROM order_items oi
    JOIN orders o           ON o.order_id = oi.order_id
    JOIN customers c        ON c.customer_id = o.customer_id
    JOIN products p         ON p.product_id = oi.product_id
    LEFT JOIN category_translation t
                             ON t.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state, category
),
ranked AS (
    SELECT
        state, category, revenue, n_orders,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY revenue DESC) AS rank_in_state
    FROM category_state_revenue
)
SELECT state, rank_in_state, category, ROUND(revenue, 2) AS revenue, n_orders
FROM ranked
WHERE rank_in_state <= 3
ORDER BY state, rank_in_state;
