-- Monthly revenue + order volume trend (delivered orders only).

SELECT
    strftime('%Y-%m', o.order_purchase_timestamp)        AS year_month,
    COUNT(DISTINCT o.order_id)                            AS n_orders,
    ROUND(SUM(oi.price), 2)                               AS revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)  AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY year_month
ORDER BY year_month;
