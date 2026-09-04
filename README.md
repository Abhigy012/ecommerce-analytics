# E-Commerce Customer & Sales Intelligence

End-to-end analytics project on a real online marketplace — customer segmentation, delivery
performance, and the sellers/categories driving (or draining) satisfaction — built on 99,441
real orders across 9 relational tables.

**Dataset:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(anonymized real orders, Sep 2016 – Aug 2018). Licensed CC BY-NC-SA 4.0 — fine for a portfolio
project; check the license badge on the Kaggle page before any commercial use.

---

## Headline findings

| # | Finding | Number |
|---|---|---|
| 1 | Overall repeat-purchase rate | **3.00%** of 93,358 customers ordered more than once |
| 2 | Month-1 cohort retention (weighted) | **0.48%** |
| 3 | Revenue from one-time buyers who never return | **57.5%** of revenue from 29.8% of customers |
| 4 | Review-score gap, late vs. on-time delivery | **4.28★ → 2.55★** (Cohen's d = -1.44, p ≈ 0) |
| 5 | Orders delivered late | **8.11%** (avg 12.56 days vs. 23.74 days quoted) |
| 6 | "Revenue at risk" sellers (high revenue, low satisfaction) | 83 of 627 qualified sellers, R$3.85M exposed |

Full numeric detail: `results/analysis_results.json`.

---

## Project structure

```
├── data/
│   ├── raw/                  9 original Olist CSVs
│   └── processed/            cleaned parquet/csv tables (notebook 03 output)
├── sql/
│   ├── schema_sqlite.sql      DDL for the warehouse
│   └── queries/                standalone analysis queries
├── notebooks/                the pipeline, run in numeric order (01 → 09)
├── results/                  every analysis output (csv/json) — also the
│                              source tables for the Power BI dashboard
├── dashboard/
│   └── powerbi/               Power BI dashboard (see its README)
├── requirements.txt
└── README.md
```

---

## How to run it

```bash
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

jupyter notebook notebooks/
```

Run the notebooks in order (01 → 09); each reads the previous notebook's output.
`01_load_to_sql` builds `db/olist.db` from the raw CSVs, `03_data_cleaning` onward reads
from `data/processed/`. Then open `dashboard/powerbi/ecommerce_dashboard.pbix` in Power BI
Desktop for the dashboard.

Total runtime for all 9 notebooks on the full dataset: under 2 minutes on a normal laptop.

---

## Methodology

**1. Load into SQL.** All 9 raw CSVs (1,551,698 rows) loaded into SQLite with declared
primary/foreign keys (`sql/schema_sqlite.sql`), so joins happen in SQL rather than as a chain
of pandas `.merge()` calls. FK enforcement is used as an integrity *check* after a permissive
load — it caught 2 category names with no English translation.

**2. Clean and document.** Key decisions (with real counts, in `notebooks/03_data_cleaning`):
`geolocation` has heavy duplication and multiple lat/lng samples per zip prefix, so it's
aggregated to state centroids rather than joined raw; `customer_id` is re-issued per order
while `customer_unique_id` is the real person — get this wrong and every customer looks like
a one-time buyer by construction.

**3. Core analysis.**
- RFM segmentation → KMeans, validated with silhouette score across k=2–8. k=2 technically
  wins (0.71) but it's a trivial "bought once vs. more than once" split; k=4 (silhouette 0.37)
  is the best *actionable* segmentation and is what the dashboard uses. Both are reported.
- Cohort retention: monthly cohorts, retention tracked out to 11 months.
- Delivery performance: estimated vs. actual delivery time by state, with a map.
- Hypothesis testing: does delay predict review score? Welch's t-test, Mann-Whitney U,
  chi-square, and Spearman correlation all agree — yes, strongly — plus a same-state
  (São Paulo) confounder check.
- Seller/category performance: a specific "revenue at risk" seller list (top-quartile
  revenue, below-median review score).

**4. Dashboard.** Power BI — KPIs, filters by state/category/date range, a delivery map,
RFM segment breakdown, and the delay-vs-review chart, built on the tables in `results/` and
`data/processed/`.

---

## Tech stack

Python (pandas, numpy) · SQLite (SQL schema + queries) · scipy (hypothesis testing) ·
scikit-learn (KMeans + silhouette) · matplotlib/seaborn/plotly (charts + interactive map) ·
Jupyter · Power BI (dashboard)

---

## What this does NOT prove

Delay correlates with lower review scores at very high statistical confidence, and the effect
survives a same-state check — but this is observational data, not a randomized experiment.
Category mix, price point, and first-time-vs-repeat-buyer status are not controlled for in a
regression, so some of the effect could still be confounded.
