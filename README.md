# data-analysis-project

A Python + PostgreSQL retail data-quality and analytics pipeline, packaged with Docker Compose.
Personal portfolio work by Long Ta, not an employer project. No dashboard or AWS deployment is claimed.

## Source and scope

Chen, D. (2015). Online Retail [Dataset]. UCI Machine Learning Repository.
https://doi.org/10.24432/C5BW33
https://archive.ics.uci.edu/dataset/352/online+retail
Dataset license: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
The source covers UK retail transactions from December 2010 to December 2011.
It has no inventory balances or cost data; stock levels, profit and stockouts cannot be inferred.
Raw data and generated outputs stay outside Git. The downloader fetches the public workbook locally.

## Architecture

```text
UCI ZIP -> immutable XLSX (SHA-256 identity)
        -> Python validation -> quarantine CSV + quality JSON
                             -> accepted CSV -> PostgreSQL staging
                                             -> fact/dimension views
                                             -> monthly SQL analytics CSV
```

## Business rules

- Preserve cancellations as signed transactions; a C-prefixed invoice must have negative quantity.
- Quarantine missing required identifiers, invalid dates, zero/fractional quantities,
  nonpositive prices, and inconsistent cancellation signs. Quarantine is a reporting policy,
  not a claim that all these source records are erroneous (some may be adjustments).
- Missing customers/descriptions produce warnings, not automatic sales deletion.
- Flag exact normalized duplicate candidates but retain them: the source has no unique line ID
  proving that repeated lines are erroneous.
- Use Decimal for GBP amounts. Net transaction value is not audited accounting revenue.
- Each accepted row retains source row and source SHA-256. Repeating the same source load does
  not add rows. Different workbook versions coexist; analysis must select ONE dataset ID.
- Database loading is transactional and checks counts and monetary totals before commit.
- Fact grain: one original workbook line. Product/date dimensions are views, not a full SCD warehouse.
- Source timestamps have no documented timezone. Do not pretend they are UTC.
- December 2010/2011 are partial periods; monthly comparisons need that caveat.

## Run with Docker

Install/start Docker Desktop with Linux containers first. From this folder in PowerShell:

For a repeatable local setup, run `powershell -File .\start.ps1`. It creates a git-ignored
`.env` with a generated local database password, or reuses the existing project's container
password, then builds, tests and runs the pipeline. Keep `.env` private.

Alternatively, manage the environment variable yourself:

```powershell
$env:POSTGRES_PASSWORD = [guid]::NewGuid().ToString('N')
docker compose up --build --abort-on-container-exit --exit-code-from pipeline
```

Keep the same password for an existing database volume. Store it privately if needed;
never commit it. The database is not exposed on a host network port.
Run the same command again to demonstrate idempotence. `docker compose down` stops containers
without deleting the database volume. Do not use `down -v` unless intentionally deleting it.

Outputs: `reports/quality.json`, `accepted.csv`, `quarantine.csv`, `monthly_analysis.csv`.
Treat generated CSVs as data, not executable spreadsheet content; source descriptions are untrusted.

## Local validation (without PostgreSQL)

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python -m unittest discover -s tests -v
.\.venv\Scripts\python pipeline.py
```

This validates the complete public dataset but does not prove database integration works.
SQL loading is explicitly requested with `--load` and standard PGHOST/PGUSER/PGPASSWORD/PGDATABASE.

## Interview preparation

Explain the problem (trustworthy retail reporting), the row grain, the cancellation policy,
and why duplicates are flagged rather than blindly deleted. Walk through one valid and one
quarantined record, then show reconciliation and a repeated run.

STAR result: quote actual counts from `reports/quality.json` only after running it.
Do not claim business savings, production deployment, or experience at Kalotoys from this project.
Be ready to explain SQL WHERE vs HAVING, LEFT JOIN, GROUP BY, window LAG, Python generators,
Decimal, transactions, and the difference between file-level idempotence and true CDC.

## GitHub

Target public repository: `longta3110/data-analysis-project`. Publication is pending repository creation.
Before pushing: run tests, inspect `git diff --cached`, and ensure no data, passwords or personal files
are staged. This project does not require any Gmail data.
