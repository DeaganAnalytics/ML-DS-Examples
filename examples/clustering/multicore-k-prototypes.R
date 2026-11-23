# Run k-prototypes with multiple parallel initializations on synthetic mixed data.
worker_setting <- Sys.getenv("CLUSTER_WORKERS", "2")
workers <- suppressWarnings(as.integer(worker_setting))
if (!grepl("^[0-9]+$", worker_setting) || is.na(workers) || workers < 1L) {
  stop("CLUSTER_WORKERS must be a positive integer.")
}

set.seed(1)
group <- rep(seq_len(5), each = 20)
clustering_input <- data.frame(
  parcel_area = rnorm(length(group), mean = group * 100, sd = 15),
  daily_water_use = rnorm(length(group), mean = group, sd = 0.2),
  land_use = factor(rep(c("House", "Unit", "Flat", "House", "Unit"), each = 20))
)

fit_parallel <- function(data, workers) {
  previous_plan <- future::plan(future::multisession, workers = workers)
  on.exit(future::plan(previous_plan), add = TRUE)

  results <- furrr::future_map(
    seq_len(25),
    function(run) clustMixType::kproto(data, k = 5, nstart = 1),
    .options = furrr::furrr_options(seed = 1)
  )
  results[[which.min(purrr::map_dbl(results, "tot.withinss"))]]
}

best_model <- fit_parallel(clustering_input, workers)
print(best_model)
