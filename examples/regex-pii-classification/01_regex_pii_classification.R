# Classify column names and optional per-table samples.
library(dplyr)
library(purrr)
library(stringr)
library(tibble)

column_patterns <- list(
  # ══════════════════════════════════════
  #           NAMES
  # ══════════════════════════════════════

  # ──────── Names ────────
  # ── Matches exact column names commonly used for names (strict match)
  names_exact = "(?i)^(firstname|fullname|lastname|middlename|nickname|preferredname)$",

  # ── Matches columns containing name-related substrings (excludes terms like 'exact', 'partial', etc.)
  names_partial = "(?i)^(?!.*(exact|partial|required)).*(firstname|fullname|middlename|preferredname|username)",

  # ══════════════════════════════════════
  #           ADDRESSES
  # ══════════════════════════════════════

  # ──────── Address ────────
  # ── Matches columns containing "address" (anywhere in the name); excludes if certain disqualifying terms are present
  address = "(?i)^(?!.*(email|fax|flag)).*address",

  # ──────── Post Code ────────
  # ── Matches columns ending in "postcode" or "postalcode" (optionally with prefix/underscores); excludes if "flag" is present
  postcode = "(?i)^(?!.*flag)(\\w+_?)?post(?:al)?_?code$",

  # ──────── City ────────
  # ── Contains the word "city" or "_city"
  city = "(?i)(^|[^a-zA-Z0-9])_?city([^a-zA-Z0-9]|$)",

  # ──────── Latitude / Longitude ────────
  # Matches columns containing "latitude" or "longitude" anywhere in the name
  latitude_longitude = "(?i).*(latitude|longitude).*",

  # ══════════════════════════════════════
  #           PHONE & EMAIL
  # ══════════════════════════════════════

  # ──────── Phone Number ────────
  # ── Matches columns containing common phone-related terms (e.g. mobilephone, contactphone); excludes disqualifiers like 'code' or 'flag'
  phone_number = "(?i)^(?!.*(code|flag|name)).*(businessphone|businessmobile|contactphone|homephone|mobilephone|phonenumber|telephone).*",

  # ──────── Email Address ────────
  # ── Matches columns with common email-related terms; excludes disqualifiers like 'flag'
  emails = "(?i)^(?!.*(flag)).*(CCEmail|emailaddress|email_recipient).*",

  # ══════════════════════════════════════
  #           FINANCIAL DETAILS
  # ══════════════════════════════════════

  # ──────── Bank Account Number ────────
  # ── Matches common bank account number column names (e.g. bank_acct_num, bankaccountnumber)
  bank_account = "(?i).*(bank_acct_num|bankacctnum).*",

  # ──────── Bank Name ────────
  # ── Matches the word "bankname"
  bank_name = "(?i)bankname",

  # ──────── BSB Number ────────
  # ── Matches columns containing "bsb"; excludes those with "id" to avoid false positives like IDs
  bsb = "(?i)^(?!.*id).*bsb.*",

  # ──────── Card Expiry ────────
  # ── Matches columns containing both "card" and "expiry" anywhere in the name
  card_expiry = "(?i)(?=.*card)(?=.*expiry).*",

  # ──────── Card Number ────────
  # ── Matches column names containing "cardnumber"
  card_number = "(?i)cardnumber",

  # ══════════════════════════════════════
  #           BUSINESS DETAILS
  # ══════════════════════════════════════

  # ──────── ABN ────────
  # ── Matches exactly "abn"
  abn = "(?i)^abn$",

  # ──────── ACN ────────
  # ── Matches exactly "acn"
  acn = "(?i)^acn$",

  # ══════════════════════════════════════
  #           OTHER PII
  # ══════════════════════════════════════

  # ──────── Gender ────────
  # ── Matches columns containing "gender" anywhere in the name
  gender = "(?i).*gender.*",

  # ──────── Date of Birth ────────
  # ── Matches columns containing both "birth" and "date" anywhere in the name
  birthday = "(?i)(?=.*birth)(?=.*date)"
)

value_patterns <- list(
  # ── Addresses
  # Matches Australian state abbreviation followed by a 4-digit postcode, with at least one space in between
  state_postcode = "(?i)\\b(NSW|QLD|TAS|VIC|ACT|WA|NT|SA)\\b\\s+\\d{4}",

  # Matches the word "lot", "lt", or "unit" at the start of a string or after a space, followed by at least one space
  lots_units = "(?i)(^|\\s)(lot|lt|unit)\\s+",

  # Matches common street suffixes (e.g., "St", "Road", "Ave"), surrounded by word boundaries or spaces
  streets = "(?i)(^|\\s)(av|ave|avenue|boulevard|blvd|cres|cr|ct|dr|drive|hwy|parade|pde|pl|place|rd|road|st|street|tce|terrace)(\\s|$)",

  # ── Phone numbers
  # Matches Australian phone numbers in the format "+61 123 456 789"
  mobile_number_spacing = "(?i)\\+61\\s\\d{3}\\s\\d{3}\\s\\d{3}",
  # Java 8: (?i)\+61\s\d{3}\s\d{3}\s\d{3}

  # Matches Australian landline numbers in the format "(02) 1234 5678" or "1234 5678"
  phone_number_spacing = "(\\(0[2-478]\\)\\s\\d{4}\\s\\d{4})|(\\d{4}\\s\\d{4})",
  # Java 8: (\(0[2-478]\)\s\d{4}\s\d{4})|(\d{4}\s\d{4})

  # ── Emails
  # Matches standard email addresses (e.g. user@example.com)
  email = "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b",
  # Java 8: ^[a-zA-Z0-9._%\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,6}$

  # ── Finance data
  # Matches a pattern of 6 digits, followed by three literal dots, then 3 digits (e.g., "123456...789")
  masked_credit_card = "\\d{6}\\.{3}\\d{3}"
)

classify_column_names <- function(metadata) {
  metadata <- as_tibble(metadata)
  names(metadata) <- tolower(names(metadata))

  metadata %>%
    transmute(
      table_schema, table_name, column_name, data_type,
      names = str_detect(column_name, column_patterns$names_exact) |
        str_detect(column_name, column_patterns$names_partial),
      addresses = str_detect(column_name, column_patterns$address) |
        str_detect(column_name, column_patterns$postcode) |
        str_detect(column_name, column_patterns$city) |
        str_detect(column_name, column_patterns$latitude_longitude),
      emails = str_detect(column_name, column_patterns$emails),
      phone_number = str_detect(column_name, column_patterns$phone_number),
      financial_details = str_detect(column_name, column_patterns$bsb) |
        str_detect(column_name, column_patterns$bank_account) |
        str_detect(column_name, column_patterns$bank_name) |
        str_detect(column_name, column_patterns$card_number) |
        str_detect(column_name, column_patterns$card_expiry),
      business = str_detect(column_name, column_patterns$abn) |
        str_detect(column_name, column_patterns$acn),
      gender = str_detect(column_name, column_patterns$gender),
      birthday = str_detect(column_name, column_patterns$birthday)
    ) %>%
    rowwise() %>%
    mutate(colname_match = {
      flags <- pick(names:birthday)
      categories <- names(flags)[which(unlist(flags))]
      if (length(categories)) paste(categories, collapse = " | ") else NA_character_
    }) %>%
    ungroup() %>%
    select(table_schema:data_type, colname_match)
}

classify_sample <- function(sample) {
  sample$data %>%
    select(where(is.character) & where(~ !all(is.na(.)))) %>%
    imap(function(values, column) {
      scores <- map_dbl(value_patterns, ~ mean(str_detect(values, .x), na.rm = TRUE))
      category_scores <- c(
        email = scores[["email"]],
        masked_credit_card = scores[["masked_credit_card"]],
        phone_combined = max(scores[c("mobile_number_spacing", "phone_number_spacing")]),
        address_combined = max(scores[c("state_postcode", "lots_units", "streets")])
      )
      best <- which.max(category_scores)
      score <- category_scores[[best]]
      tibble(
        table_schema = sample$table_schema, table_name = sample$table_name,
        column_name = column,
        best_match = if (score > 0) names(category_scores)[best] else NA_character_,
        best_match_score = if (score > 0) score else NA_real_
      )
    }) %>%
    list_rbind()
}

classify_pii <- function(metadata, samples = list()) {
  empty_scores <- tibble(
    table_schema = character(), table_name = character(), column_name = character(),
    best_match = character(), best_match_score = double()
  )
  scores <- bind_rows(empty_scores, map(samples, classify_sample))
  classify_column_names(metadata) %>%
    left_join(scores, by = c("table_schema", "table_name", "column_name")) %>%
    mutate(any_match = !is.na(colname_match) | !is.na(best_match))
}
