save_model <- function(model, model_id, sample_size, features, notes = "", path) {
  
  # Create output folder if it doesn't exist
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
  
  # Create metadata package
  model_package <- list(
    model = model,
    date_trained = Sys.time(),
    model_id = model_id,
    sample_size = sample_size,
    features = features,
    notes = notes
  )
  
  # Create descriptive filename
  date <- format(Sys.Date(), "%Y%m%d")
  file_name <- sprintf("%s_%s_n%s.rds", date, model_id, sample_size)
  
  # Save RDS
  saveRDS(model_package, file.path(path, file_name))
  
  message("Model saved to: ", file.path(path, file_name))
}


load_model <- function(file_path, metadata = FALSE) {
  
  if (!file.exists(file_path)) stop("File does not exist: ", file_path)
  
  model_package <- readRDS(file_path)
  message("Loaded model from: ", file_path)
  
  if (metadata) {
    return(model_package)
  } else {
    return(model_package$model)
  }
}
