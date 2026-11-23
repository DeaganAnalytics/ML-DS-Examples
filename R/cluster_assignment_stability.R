library(dplyr)
library(tidyr)
library(purrr)

cluster_assignment_stability <- function(benchmark_model, new_model, weight_prop = 0.5, weight_centroid = 0.5) {
 
  # ============================================================
  # Function Inputs:
  #   benchmark_model : k-prototypes object (reference model)
  #   new_model       : k-prototypes object (to compare)
  #   weight_prop     : weight for cluster proportion similarity
  #   weight_centroid : weight for centroid similarity
  # ============================================================
   
  # Ensure both models use the same variables
  if (!identical(colnames(benchmark_model$centers), colnames(new_model$centers))) {
    stop("Benchmark and new models must use the same variables (same names and order).")
  }
  
  # Ensure weights sum to 1
  if (!is.numeric(weight_prop) || !is.numeric(weight_centroid) || (weight_prop + weight_centroid != 1)) {
    stop("weight_prop and weight_centroid must be numeric and sum to 1")
  }

  # Compute cluster proportions for each model (i.e. for each cluster size, calculate the percentage of total)
  get_cluster_props <- function(clusters) {
    tibble(cluster = clusters) %>%
      count(cluster) %>% # creates column n
      mutate(prop = n / sum(n))
  }
  
  prop_bench <- get_cluster_props(benchmark_model$cluster)
  prop_new   <- get_cluster_props(new_model$cluster)
  
  # Detect numeric vs categorical variables
  numeric_vars <- colnames(benchmark_model$centers)[sapply(benchmark_model$centers, is.numeric)]
  categorical_vars <- setdiff(colnames(benchmark_model$centers), numeric_vars)
  
  # Calculate numeric and categorical centroids for each model
  extract_centroids <- function(model, vars) {
    as.data.frame(model$centers) %>%
      select(any_of(vars))
  }
  
  bench_centroids_num <- extract_centroids(benchmark_model, numeric_vars)
  new_centroids_num   <- extract_centroids(new_model, numeric_vars)
  
  bench_centroids_cat <- extract_centroids(benchmark_model, categorical_vars)
  new_centroids_cat   <- extract_centroids(new_model, categorical_vars)
  
  # Build similarity table
  cluster_map <- expand.grid(bench = prop_bench$cluster, 
                             new = prop_new$cluster)
  
  # Calculate cluster proportional similarity
  cluster_map <- cluster_map %>%
    rowwise() %>%
    mutate(prop_sim = 1 - abs(prop_bench$prop[prop_bench$cluster == bench] - prop_new$prop[prop_new$cluster == new]))
  
  # Calculate numeric centroid similarity (inverse Euclidean distance)
  cluster_map <- cluster_map %>%    
    mutate(
      centroid_sim_num = if(length(numeric_vars) > 0) {
        bench_vec <- as.numeric(bench_centroids_num[bench, ])
        new_vec <- as.numeric(new_centroids_num[new, ])
        1 / (1 + sqrt(sum((bench_vec - new_vec)^2)))
      } else { 1 })
  
  # Calculate categorical similarity
  cluster_map <- cluster_map %>%    
    mutate(
      centroid_sim_cat = if(length(categorical_vars) > 0) {
        bench_vec <- as.character(bench_centroids_cat[bench, ])
        new_vec <- as.character(new_centroids_cat[new, ])
        mean(bench_vec == new_vec)
      } else { 1 })
      
  # Calculate centroid similarity and total similarity (total is based on parameterised weightings)
  cluster_map <- cluster_map %>%    
    mutate(
      centroid_sim = (centroid_sim_num + centroid_sim_cat) / 2,
      total_sim = weight_prop * prop_sim + weight_centroid * centroid_sim
    ) %>%
    ungroup()
  
  # Select best match per benchmark cluster
  best_match <- cluster_map %>%
    group_by(bench) %>%
    slice_max(order_by = total_sim, n = 1, with_ties = FALSE) %>%
    select(bench, new, total_sim)
  
  # Overall stability score
  stability_score <- mean(best_match$total_sim)
  
  list(
    best_match = best_match,
    stability_score = stability_score
  )
}
