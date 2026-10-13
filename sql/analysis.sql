-- A source version is always explicit: never sum overlapping workbook versions.
-- Monthly sales/cancellation values and month-on-month net change.
WITH monthly AS (
    SELECT date_trunc('month', invoice_date)::date AS month,
           COALESCE(sum(signed_value_gbp) FILTER (WHERE line_type = 'sale'), 0) AS gross_sales_gbp,
           -COALESCE(sum(signed_value_gbp) FILTER (WHERE line_type = 'cancellation'), 0) AS cancellations_gbp,
           sum(signed_value_gbp) AS net_transaction_value_gbp
    FROM retail.fact_sales
    WHERE dataset_id = %(dataset_id)s
    GROUP BY 1
)
SELECT *, net_transaction_value_gbp - lag(net_transaction_value_gbp) OVER (ORDER BY month)
    AS change_from_previous_month_gbp
FROM monthly ORDER BY month;
