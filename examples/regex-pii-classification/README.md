# Regex PII Classification

This R example uses regex heuristics to flag column names and sample values that may contain personally identifiable information. Treat its results as candidates for review.

| File | Purpose |
|---|---|
| [01_regex_pii_classification.R](01_regex_pii_classification.R) | Defines `classify_pii(metadata, samples)`. |
| [02_get_sample_data.R](02_get_sample_data.R) | Defines SQL Server sampling and reads the resulting RDS bundles. |
| [sql/information_schema.sql](sql/information_schema.sql) | Reads table and column metadata from SQL Server. |

## Try it with synthetic data

Start R from the repository root after installing the packages listed in the [root README](../../README.md).

```r
source("examples/regex-pii-classification/01_regex_pii_classification.R")

metadata <- tibble(
  table_schema = "demo_schema",
  table_name = "contacts",
  column_name = c("street_address", "contact_value"),
  data_type = "varchar"
)
samples <- list(list(
  table_schema = "demo_schema",
  table_name = "contacts",
  data = tibble(
    street_address = c("10 Example Road", "2 Example Street"),
    contact_value = c("alex@example.com", NA_character_)
  )
))

classify_pii(metadata, samples)
```

The result has one row per metadata column, with column-name categories, the best value pattern and its match fraction, and an `any_match` flag. Omit `samples` to classify column names alone.

## Optional SQL Server sampling

Create a DBI connection named `con_name` using a SQL Server driver such as `odbc` and a data source or authentication configured outside the repository. Run these commands from the repository root:

```r
source("examples/regex-pii-classification/02_get_sample_data.R")

sql_file <- "examples/regex-pii-classification/sql/information_schema.sql"
metadata <- DBI::dbGetQuery(con_name, paste(readLines(sql_file), collapse = "\n"))
sample_dir <- "examples/regex-pii-classification/table_samples"
sample_database(con_name, metadata, sample_dir)
classify_pii(metadata, read_samples(sample_dir))
```

The sampler saves up to 500 rows per table with at least one non-null selected text field. SQL Server chooses the rows because the query has no ordering key. Existing RDS bundles are reused. Use a new directory to refresh a sample. Each bundle includes the schema and table names alongside its data.

Bundles may contain raw PII. Keep database extracts in an approved local location and out of Git. The example's default documentation path is Git-ignored.
