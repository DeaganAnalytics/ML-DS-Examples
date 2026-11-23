# Export up to 500 rows per table from a caller-provided SQL Server connection.
sample_database <- function(connection, metadata, sample_dir) {
  names(metadata) <- tolower(names(metadata))
  string_types <- c("nchar", "ntext", "nvarchar", "varchar", "char", "text")
  columns <- metadata[tolower(metadata$data_type) %in% string_types, ]
  tables <- unique(columns[c("table_schema", "table_name")])
  dir.create(sample_dir, showWarnings = FALSE, recursive = TRUE)

  hex_key <- function(value) paste(format(charToRaw(enc2utf8(value))), collapse = "")

  for (i in seq_len(nrow(tables))) {
    schema <- tables$table_schema[[i]]
    table <- tables$table_name[[i]]
    path <- file.path(sample_dir, paste0(hex_key(schema), "-", hex_key(table), ".rds"))
    if (file.exists(path)) next

    names_in_table <- columns$column_name[
      columns$table_schema == schema & columns$table_name == table
    ]
    quoted_columns <- DBI::dbQuoteIdentifier(connection, names_in_table)
    quoted_table <- DBI::dbQuoteIdentifier(connection, DBI::Id(schema = schema, table = table))
    query <- sprintf(
      "SELECT TOP (500) %s FROM %s WHERE %s",
      paste(quoted_columns, collapse = ", "),
      quoted_table,
      paste(paste(quoted_columns, "IS NOT NULL"), collapse = " OR ")
    )

    data <- DBI::dbGetQuery(connection, query)
    saveRDS(list(table_schema = schema, table_name = table, data = data), path)
  }

  invisible(sample_dir)
}

read_samples <- function(sample_dir) {
  lapply(list.files(sample_dir, pattern = "[.]rds$", full.names = TRUE), readRDS)
}
