CREATE SCHEMA IF NOT EXISTS retail;
CREATE TABLE IF NOT EXISTS retail.dataset (
    dataset_id TEXT PRIMARY KEY,
    source_url TEXT NOT NULL,
    row_count INTEGER NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Grain: one original workbook row within one immutable source file.
CREATE TABLE IF NOT EXISTS retail.staging_line (
    dataset_id TEXT REFERENCES retail.dataset,
    source_row INTEGER NOT NULL,
    invoice_no TEXT NOT NULL,
    stock_code TEXT NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL CHECK (quantity <> 0),
    invoice_date TIMESTAMP NOT NULL,
    unit_price NUMERIC(18,4) NOT NULL CHECK (unit_price > 0),
    customer_id TEXT,
    country TEXT NOT NULL,
    line_type TEXT NOT NULL CHECK (line_type IN ('sale', 'cancellation')),
    PRIMARY KEY (dataset_id, source_row)
);
-- A cancellation is kept as a signed value, not discarded as bad data.
CREATE OR REPLACE VIEW retail.fact_sales AS
SELECT *, invoice_date::date AS date_key,
       quantity * unit_price AS signed_value_gbp
FROM retail.staging_line;
CREATE OR REPLACE VIEW retail.dim_date AS
SELECT DISTINCT invoice_date::date AS date_key,
       extract(year FROM invoice_date)::int AS year,
       extract(month FROM invoice_date)::int AS month
FROM retail.staging_line;
-- Descriptions can vary. This is a latest-observed label, not an authoritative catalog.
CREATE OR REPLACE VIEW retail.dim_product AS
SELECT DISTINCT ON (dataset_id, stock_code)
       dataset_id, stock_code, description
FROM retail.staging_line
ORDER BY dataset_id, stock_code, invoice_date DESC, source_row DESC;
