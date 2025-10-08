# ------------------------------------------------------------------------------
# Example: Parallelised k-prototypes clustering using furrr
# ------------------------------------------------------------------------------
# This script demonstrates how to run k-prototypes clustering in parallel
# using the 'furrr' and 'clustMixType' packages.
# 
# Note: This is an example only - it’s not a complete, standalone script.
# You’ll need to define `clustering_input` (your dataset) before running.
# 
# Future versions may include:
#  - Data preprocessing and scaling
# ------------------------------------------------------------------------------

# --- Load required packages ---
library(furrr)         # parallelised map functions
library(purrr)         # functional helpers (e.g., map_dbl)
library(clustMixType)  # k-prototypes clustering for mixed data

# --- Set up parallel workers ---
plan(multisession, workers = 16)  # adjust number of cores as needed

# --- Run k-prototypes with multiple random starts in parallel ---
seeds <- 1:25  # one seed per start for reproducibility

results <- future_map(seeds, ~ {
  set.seed(.x)
  kproto(clustering_input, k = 5, nstart = 1)
})

# --- Pick best model (lowest total within-cluster sum of squares) ---
best_model <- results[[which.min(map_dbl(results, ~ .x$tot.withinss))]]

# --- Inspect results ---
best_model
