# List of reserved SQL keywords or problematic column names to exclude
reserved_words <- c("column", "date", "group", "identity", "key", "object", "order", "primary", "rowversion", "status",  "table", "timestamp", "user", "version")

# Filter columns to include only usable string types and exclude reserved names
string_cols <- column_names %>%
  clean_df() %>% 
  filter(data_type %in% c("nchar", "ntext", "nvarchar", "varchar", "char")) %>% 
  filter(!tolower(column_name) %in% reserved_words)

# Get unique schema + table combinations
tables <- string_cols %>%
  distinct(table_schema, table_name) 

# Set folder where .rds sample files will be saved
dir.create(folder_path, showWarnings = FALSE, recursive = TRUE)

# Initialise log file
log_file <- file.path(folder_path, "query_log.txt")

# Loop over each table and extract a sample of non-null string values
for(i in seq_len(nrow(tables))) {
  schema <- tables$table_schema[i]
  table <- tables$table_name[i]
  
  # File path to save output
  file_path <- file.path(folder_path, paste0(schema, "_", table, ".rds"))
  
  # Skip if the file already exists (resume-friendly)
  if(file.exists(file_path)) {
    message(sprintf("Skipping %s.%s, file already exists.", schema, table))
    next
  }
  
  # Get relevant string column names for the current table
  cols <- string_cols %>%
    filter(table_schema == schema, table_name == table) %>%
    pull(column_name)
  
  # If no usable columns, skip this table
  if(length(cols) == 0) {
    message(sprintf("No columns found for %s.%s, skipping.", schema, table))
    next
  }
  
  # Build SELECT clause and WHERE clause with non-null filters
  col_list <- paste(sprintf("[%s]", cols), collapse = ", ")
  where_clause <- paste(sprintf("[%s] IS NOT NULL", cols), collapse = " OR ")
  
  # Construct the SQL query to get top 500 non-null rows
  query <- sprintf("
    SELECT TOP 500 %s
    FROM [%s].[%s]
    WHERE %s
  ", col_list, schema, table, where_clause)
  
  # Print the table being queried
  message(sprintf("Querying %s.%s...", schema, table))
  
  # Append the query to the log file with a timestamp
  cat(
    sprintf("[%s] Query for %s.%s:\n%s\n\n", Sys.time(), schema, table, query),
    file = log_file,
    append = TRUE
  )
  
  # Run the query, catching any errors
  df <- tryCatch({
    dbGetQuery(con_name, query)
  }, error = function(e) {
    message(sprintf("Error querying %s.%s: %s", schema, table, e$message))
    NULL
  })
  
  # Save results if query returned data
  if(!is.null(df) && nrow(df) > 0) {
    saveRDS(df, file_path)
    message(sprintf("Saved sample for %s.%s to %s", schema, table, file_path))
  } else {
    message(sprintf("No data returned for %s.%s", schema, table))
  }
}
