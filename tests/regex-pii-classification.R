source("examples/regex-pii-classification/01_regex_pii_classification.R")

# Compile every pattern with the same regex engine used by the classifier.
invisible(map(c(column_patterns, value_patterns), ~ str_detect("", .x)))
stopifnot(identical(
  str_detect(c("street_address", "emailaddress", "address_flag", "city"), column_patterns$address),
  c(TRUE, FALSE, FALSE, FALSE)
))

metadata <- tibble(
  TABLE_SCHEMA = c("demo_schema", "demo_schema", "demo", "demo_schema"),
  TABLE_NAME = c("contacts", "contacts", "schema_contacts", "contacts"),
  COLUMN_NAME = c("street_address", "contact_value", "contact_value", "empty"),
  DATA_TYPE = "varchar"
)
samples <- list(list(
  table_schema = "demo_schema",
  table_name = "contacts",
  data = tibble(
    street_address = "10 Example Road",
    contact_value = "alex@example.com",
    empty = NA_character_
  )
))

result <- classify_pii(metadata, samples)
stopifnot(
  nrow(result) == nrow(metadata),
  identical(result$colname_match, c("addresses", NA_character_, NA_character_, NA_character_)),
  identical(result$best_match, c("address_combined", "email", NA_character_, NA_character_)),
  identical(result$best_match_score, c(1, 1, NA_real_, NA_real_)),
  identical(result$any_match, c(TRUE, TRUE, FALSE, FALSE)),
  all(is.na(classify_pii(metadata)$best_match)),
  all(is.na(classify_pii(metadata, list(list(data = tibble(empty = NA_character_))))$best_match))
)
