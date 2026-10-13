# Measured local results

Full UCI workbook processed locally on October 13, 2026.
SHA-256: `43465a06f2ccf7c8b5bd2892bc7defb52f97487934fe93b16ae4c3936424676d`

| Metric | Observed value |
| --- | ---: |
| Source rows | 541,909 |
| Accepted rows | 539,392 |
| Quarantined rows | 2,517 |
| Possible repeated normalized rows, retained | 5,268 |
| Rows with missing customer IDs (all source rows) | 135,080 |

All quarantined rows had nonpositive/invalid prices; 1,336 also had inconsistent
invoice/quantity signs. Reason counts overlap. Warnings include quarantined rows.
These are results of our explicit reporting rules, not proof every quarantined row is corrupt.

Gross positive transaction value: GBP 10,666,684.544.
Cancellation value: GBP 896,812.49.
Net accepted transaction value: GBP 9,769,872.054.
Precision is retained from source prices; amounts are not audited revenue, profit, or money saved.
Potential duplicate lines remain included; December endpoints are partial periods.

## Verification

- Five Python unit/end-to-end fixture tests passed locally.
- All six tests passed inside Docker, including the PostgreSQL repeated-load test.
- The complete public workbook was downloaded and validated.
- Docker image execution and the full PostgreSQL load passed. Database reconciliation
  confirmed 539,392 rows and GBP 9,769,872.0540 in net transaction value.
- Monthly SQL output was generated and inspected.
- A second full-file load completed successfully with the same row count and monetary total.
- GitHub Actions has not run remotely yet; publication is pending.

## Honest interview result

"In this personal project, I processed 541,909 public retail transaction rows using
Python. My validation rules separated 2,517 rows for review and retained 539,392
for reporting. I also flagged 5,268 possible duplicate rows without assuming they
were errors. I reconciled the accepted and quarantined row counts to the source."

PostgreSQL integration and container execution were verified during development.
Walk through the implementation and explain the tradeoffs before presenting it as your work.
