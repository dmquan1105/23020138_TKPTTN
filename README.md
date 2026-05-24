# Analysis of Cross-Validation and `max_depth` Effects on Random Forest for Churn Prediction

This repository contains the full experimental workflow and statistical analysis for a churn prediction task using `RandomForestClassifier`. The main goals are:

- Evaluate the effect of the number of cross-validation folds `k`.
- Evaluate the effect of `max_depth` and its interaction with `k`.
- Compare configurations using `F1-score` with both frequentist and Bayesian analysis.

## Workflow Overview

1. Load the `mlc_churn.csv` dataset.
2. Remove charge variables that are highly correlated with their corresponding minute variables:
   - `total_day_charge`
   - `total_eve_charge`
   - `total_night_charge`
   - `total_intl_charge`
3. Build a modeling pipeline with:
   - `ColumnTransformer`
   - `OneHotEncoder(handle_unknown="ignore")` for categorical features
   - `RandomForestClassifier`
4. Run `RepeatedStratifiedKFold` with:
   - `k in {3, 5, 10}`
   - `repeats = 10`
   - `seed = 1234`
5. Evaluate performance using `F1-score` for the positive class `churn = "yes"`.
6. Export intermediate results to `results/` and perform statistical analysis in R.

## Repository Structure

```text
.
|-- analysis/
|   |-- 01_crd_analysis.R
|   `-- 02_crfd_analysis.R
|-- data/
|   `-- mlc_churn.csv
|-- figures/
|   |-- corr.png
|   |-- crd_mean_ci.png
|   |-- crd_mean_ci_r.png
|   |-- crd_tukey.png
|   |-- crfd_interaction.png
|   `-- crfd_interaction_r.png
|-- model/
|   `-- random_forest.ipynb
`-- results/
    |-- crd_*.csv / *.txt / *.rds
    `-- crfd_*.csv / *.txt / *.rds
```

## Main Components

- model/random_forest.ipynb: notebook that runs the Random Forest experiments and generates result tables and figures in Python.
- analysis/01_crd_analysis.R: CRD analysis for the factor `k`.
- analysis/02_crfd_analysis.R: CRFD analysis for the factors `k` and `max_depth`.
- results/: summary tables, hypothesis tests, linear model output, Bayesian output, `emmeans`, and saved `.rds` models.
- figures/: correlation plots, confidence interval plots, Tukey plots, and interaction plots.

## Experimental Designs

### 1. CRD

Only the factor `k` is varied, with `max_depth = None`.

- `k = 3`
- `k = 5`
- `k = 10`

Main output files:

- `results/crd_results.csv`
- `results/crd_fold_details.csv`
- `results/crd_summary_python.csv`
- `results/crd_summary_r.csv`
- `results/crd_lm.txt`
- `results/crd_brm.txt`
- `results/crd_brm_emmeans.txt`

### 2. CRFD

Two factors are varied simultaneously:

- `k in {3, 5, 10}`
- `max_depth in {3, 5, None}`

Main output files:

- `results/crfd_results.csv`
- `results/crfd_fold_details.csv`
- `results/crfd_summary_python.csv`
- `results/crfd_summary_r.csv`
- `results/crfd_lm.txt`
- `results/crfd_brm.txt`
- `results/crfd_brm_emmeans.txt`

## How to Reproduce

### Python

Required packages:

```bash
pip install numpy pandas scipy matplotlib seaborn scikit-learn jupyter
```

Then open and run the notebook:

```bash
cd model
jupyter notebook random_forest.ipynb
```

The notebook will regenerate:

- result tables in `results/`
- figures in `figures/`

### R

Required packages:

```r
install.packages(c("dplyr", "ggplot2", "car", "brms", "emmeans"))
```

Run the CRD analysis:

```bash
Rscript analysis/01_crd_analysis.R
```

Run the CRFD analysis:

```bash
Rscript analysis/02_crfd_analysis.R
```

Notes:

- `brms` requires a Stan backend, so additional setup may be needed on a new machine.
- The R scripts read from `results/crd_results.csv` and `results/crfd_results.csv`, so the Python notebook should be run first.

## Summary of Results

### CRD: Effect of `k`

Mean `F1-score` from the R summary output:

| k   | Mean F1 |           95% CI |
| --- | ------: | ---------------: |
| 3   |  0.7397 | [0.7347, 0.7447] |
| 5   |  0.7520 | [0.7457, 0.7583] |
| 10  |  0.7547 | [0.7518, 0.7576] |

Key observations:

- `k = 5` and `k = 10` perform clearly better than `k = 3`.
- The linear model indicates a statistically significant effect of `k` (`p = 9.47e-05`).
- In the Bayesian `emmeans` output, the contrasts `k3 - k5` and `k3 - k10` exclude 0 in the 95% HPD interval.

### CRFD: Effects of `k` and `max_depth`

Selected mean `F1-score` values:

| k   | max_depth | Mean F1 |
| --- | --------- | ------: |
| 3   | 3         |  0.0023 |
| 3   | 5         |  0.0646 |
| 3   | None      |  0.7397 |
| 5   | 3         |  0.0028 |
| 5   | 5         |  0.0670 |
| 5   | None      |  0.7520 |
| 10  | 3         |  0.0025 |
| 10  | 5         |  0.0653 |
| 10  | None      |  0.7547 |

Key observations:

- `max_depth = None` strongly outperforms both `max_depth = 3` and `max_depth = 5`.
- `max_depth = 3` almost eliminates useful detection of the positive class under `F1-score`.
- The two-factor ANOVA shows statistically significant effects for `k`, `max_depth`, and the interaction `k:max_depth`.
- The Bayesian `emmeans` results are consistent with the frequentist analysis.

## Important Outputs

- figures/corr.png: correlation matrix for numeric variables.
- figures/crd_mean_ci.png: mean `F1-score` with 95% CI for CRD from Python.
- figures/crd_mean_ci_r.png: CRD plot generated in R.
- figures/crd_tukey.png: Tukey HSD comparison for CRD.
- figures/crfd_interaction.png: interaction plot of `k` and `max_depth` from Python.
- figures/crfd_interaction_r.png: interaction plot generated in R.

## Notes

- The repository currently does not include `requirements.txt` or `environment.yml`, so dependencies are listed directly in this README.
- The dataset, generated results, and figures are already committed, so the repository can be inspected without rerunning the experiments.
