# Regex PII Classification

This repository contains a **simplified example** of a project that classifies database column names and sample data using regex patterns. It is intended for **demonstration purposes only** and is not a fully working pipeline. 

Some functions and connections are referenced from another personal repository ([Personal-Automation](https://github.com/DeaganAnalytics/Personal-Automation)) and will **not run directly** without those dependencies.

---

## Files in this folder

### `01_regex_classification_example.Rmd`
- Main R Markdown script demonstrating the workflow.
- Steps included:
  1. Load packages and helper functions (`read_sql.R`, `clean_df.R` from [Personal-Automation](https://github.com/DeaganAnalytics/Personal-Automation)).
  2. Import column metadata from `information_schema.sql`.
  3. Apply regex patterns to classify column names into categories like **names**, **addresses**, **emails**, **financial details**, etc.
  4. Load example `.rds` sample files from a local folder.
  5. Apply regex patterns to sample data and combine results.

> ⚠️ References to `read_sql.R`, `clean_df.R`, and `server_connection.R` are only for illustration. They are located in [Personal-Automation](https://github.com/DeaganAnalytics/Personal-Automation).

---

### `02_get_sample_data.R`
- Example script to extract sample string data from a database.
- Queries the tables defined in `information_schema.sql` and saves top 500 non-null string rows as `.rds` files.
- Demonstrates data extraction logic and logging, but relies on a live database connection (`con_name`) which is **not included**.

---

### `information_schema.sql`
- Example SQL query to retrieve table schema information:

## Notes
- This is a simplified showcase of regex-based column and data classification.
- It will not run as-is because it depends on external functions and a database connection.
- The intent is to show the structure, regex logic, and workflow, rather than provide a fully operational tool.
