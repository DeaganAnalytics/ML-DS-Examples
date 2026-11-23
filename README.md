# ML-DS-Examples

R examples for mixed-data clustering, model utilities, and regex-based classification of personally identifiable information (PII).

## Setup

Install R and the packages used by the examples:

```r
install.packages(c(
  "clustMixType", "DBI", "dplyr", "furrr", "future", "purrr",
  "stringr", "tibble", "tidyr", "VIM"
))
```

## Clustering examples

Run from the repository root:

```sh
Rscript --vanilla examples/clustering/knn-and-k-prototypes.R
CLUSTER_WORKERS=2 Rscript --vanilla examples/clustering/multicore-k-prototypes.R
```

- [KNN and k-prototypes](examples/clustering/knn-and-k-prototypes.R) generates 1,000 synthetic property records, imputes missing values with KNN, and fits a five-cluster model. It writes the elbow plot to `Rplots.pdf` and prints cluster summaries.
- [Multicore k-prototypes](examples/clustering/multicore-k-prototypes.R) generates a small mixed-data fixture, fits 25 initialized models in parallel, and prints the model with the lowest within-cluster cost. Set `CLUSTER_WORKERS=1` to run with one worker.

## Model helpers

Source the helpers in [R/](R/) within the current R session. For example, after running the KNN example with `source()`:

```r
source("R/cluster_assignment_stability.R")
source("R/model_utils.R")

cluster_assignment_stability(kproto_model, kproto_model)$stability_score
model_dir <- tempfile("clustering-model-")
save_model(kproto_model, "properties", nrow(normalised_features),
           names(normalised_features), path = model_dir)
restored_model <- load_model(list.files(model_dir, full.names = TRUE)[[1]])
```

For meaningful stability scores, compare models fitted with the same feature names, order, and scaling. Each benchmark cluster is matched independently to its best candidate.

## Regex PII classification

See the [PII example README](examples/regex-pii-classification/README.md) for a synthetic demo and optional SQL Server sampling instructions.
