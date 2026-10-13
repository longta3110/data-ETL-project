# Interview walkthrough

## 60-second introduction

I built a personal retail analytics pipeline using Python, PostgreSQL, and Docker.
The source is a public UCI transaction dataset, not data from my employer.
Python validates the workbook, separates records unsuitable for sales reporting,
and keeps a trace back to each original row. PostgreSQL stores the accepted lines
and computes monthly sales and cancellation values using SQL.
The interesting part was defining the rules: cancellations are valid negative
transactions, missing customers do not automatically invalidate sales, and identical
lines are only potential duplicates because the source has no unique line identifier.

## STAR structure

- Situation: A public retail workbook mixes sales, cancellations, incomplete fields,
  and adjustment-like records. Blind aggregation would hide those distinctions.
- Task: Build a reproducible pipeline whose row counts and monetary totals can be checked.
- Action: Define explicit rules in Python, retain signed cancellations, quarantine
  questionable records, calculate with Decimal, bulk-load with PostgreSQL COPY,
  and use source hash plus row number to prevent duplicate loads.
- Result: Quote RESULTS.md. State which tests actually ran. Do not invent commercial impact.

## Questions you should be able to answer

1. What is the grain? One original workbook line per source-file version.
2. Why not deduplicate invoice plus product? An invoice can have repeated product lines;
   removing them could remove real transactions.
3. Why Decimal? Binary floating point can introduce rounding differences in monetary sums.
4. Why staging? It separates loading from analytical views and preserves lineage.
5. What makes reruns safe? The primary key is (dataset_id, source_row), and INSERT uses
   ON CONFLICT DO NOTHING. This covers exact source reruns, not arbitrary incremental updates.
6. What does a transaction do? Database changes commit together; failed reconciliation rolls back.
7. Why a window function? LAG compares each monthly total to the previous observed month
   without collapsing the monthly rows into one result.
8. WHERE vs HAVING? WHERE selects source rows before aggregation; HAVING filters groups.
9. What are the limitations? No inventory or cost data; partial endpoint months; duplicate
   candidates remain included; local batch pipeline rather than production orchestration.
10. How would AWS fit? As a future design only: S3 for raw files, a scheduled container or
    Glue job for processing, and RDS PostgreSQL for storage. No AWS deployment was performed.

## Demo

1. Open pipeline.py and explain validate() using a positive sale and a C-prefixed cancellation.
2. Show reports/quality.json and verify accepted + quarantined = source rows.
3. Open sql/schema.sql and explain keys, signed values, and the fact grain.
4. Open sql/analysis.sql and explain GROUP BY, conditional aggregates, and LAG.
5. Show reports/monthly_analysis.csv, noting incomplete December periods.
6. Rerun the pipeline and verify the database count remains unchanged.

Understand and run these steps yourself before claiming ownership in an interview.
