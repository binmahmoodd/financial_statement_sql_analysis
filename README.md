# Financial Statement SQL Analysis

A SQL-based analysis of financial metrics across 226 US companies, exploring profitability, industry-relative performance, and revenue growth using PostgreSQL.

## Project Overview

This project applies SQL (joins, CTEs, window functions, percentile-based statistics) to a real-world financial dataset to answer analyst-style questions:

- How profitable are these companies, and how is that distributed?
- How does profitability compare *within* industries, not just across the whole dataset?
- Which companies are growing fastest, and does faster growth come with stronger profitability?

## Dataset

- **Source:** https://www.kaggle.com/datasets/shoaibzaferkhawaja/financial-statement-data-for-top-200-us-companies?resource=download
- **Shape:** 226 companies, single point-in-time snapshot (not multi-year), ~40 original columns covering company info, margins, growth rates, valuation ratios, and balance sheet metrics
- **Note:** Since this is a snapshot rather than time-series data, year-over-year trend analysis isn't possible

## Database Schema

Raw data was imported into a single staging table (`financialdata`), then split into three normalized tables:

| Table | Description |
|---|---|
| `companies` | symbol, name, industry |
| `raw_metrics` | Directly reported dollar/share figures  |
| `ratio_metrics` | margins, growth rates, and financial ratios |

All three tables join on `symbol`.

## Data Cleaning Notes

- **Row count:** 226 of an expected 240 (`Sr.No` gaps). Gaps are non-consecutive/scattered, ruling out an import failure and so treated as pre-existing in the source data.
- **No duplicate companies** found (unique `symbol` values).
- **Minimal NULLs** across key columns except `revenue_growth`
- **`debtToEquity` scaling issue found and fixed:** raw values were in the hundreds/thousands (max 4,373) across many companies, not just one outlier — indicating the column was stored as ratio × 100. Corrected by dividing by 100 during table creation.
- **Float precision:** ratio/margin columns were imported as `real` (float4); cast to `numeric` with appropriate precision in the cleaned tables to avoid floating-point rounding issues in financial calculations.

## Analysis Files

### `01_data_exploration.sql`
Initial checks on the raw import: row counts, column list, `Sr.No` gap analysis, duplicate check, NULL counts, and numeric range sanity checks (which surfaced the `debtToEquity` scaling issue).

### `02_data_cleaning.sql`
Splits the raw table into `companies`, `raw_metrics`, and `ratio_metrics`, applying the `debtToEquity` fix and numeric type casting.

### `03_profitability_analysis_global.sql`
- Calculated average gross, operating, EBITDA, and profit margins across all companies. **Average profit margin: 16.99%.**
- Used profit margin as the primary metric (true bottom-line profitability).
- Built data-driven tiers (Excellent / Good / Moderate / Poor / Negative) using quartile cutoffs (25th percentile: 8.59%, median: 14.61%, 75th percentile: 22.72%) rather than arbitrary round numbers.

### `04_profitability_analysis_industry.sql`
- Dataset spans 81 industries across 226 companies (~2.8 companies/industry on average); 25 industries contain only 1 company.
- **Decision:** excluded industries with fewer than 3 companies from industry-relative comparisons (46 of 81 industries), since averages/rankings aren't statistically meaningful at very small sample sizes.
- For qualifying industries: calculated industry-average profit margin, ranked industries by profitability, and — for every company — showed its margin alongside its industry average, the difference between the two, and its rank within its own industry.

### `05_growth_analysis.sql`
- Baseline revenue and earnings growth stats revealed extreme ranges (revenue growth: -19.7% to 3,065%; earnings growth: -99.6% to 24,878%), prompting a switch to **median** as the more representative baseline over the (outlier-skewed) mean.
- **Earnings growth excluded from further analysis** — the column has a meaningful NULL rate and extreme instability from percentage-growth math breaking down near zero-value denominators, making it unreliable relative to revenue growth.
- Identified **Moderna Inc. (MRNA)** as a major revenue-growth outlier (3,065%), attributable to real COVID-19 vaccine revenue in 2020-2021.
- Ranked top/bottom 10 companies by revenue growth, and compared every company's growth against the dataset median.
- **Cross-analysis — does profitability predict growth?**
  - *With Moderna included:* appeared to show higher-margin tiers growing faster but this was driven almost entirely by one outlier landing in a high-margin tier.
  - *With Moderna excluded:* the relationship is weak and non-linear. Good, Moderate, Poor, and Excellent tiers all show similar average growth (~21-25%). The one clear pattern: companies in the **Negative** margin tier grow markedly slower (7.4%), suggesting financial distress constrains growth more than profitability itself drives it.

## Key Takeaways

1. Profitability varies meaningfully by industry — global comparisons alone are misleading without industry context.
2. There is no strong, general link between profitability and revenue growth — except that companies with negative margins clearly underperform on growth.
3. Outlier sensitivity checks matter: an initially "clean" finding (profitability drives growth) did not hold up once a single extreme company was excluded.

## Tools Used
- **PostgreSQL** — database and query engine
- **DBeaver** — SQL client for writing/running queries and importing data
- **GitHub Desktop** — version control

## Methodology Notes
- All cleaning decisions and thresholds (quartile cutoffs, minimum industry sample size, outlier handling) are documented as comments within the corresponding `.sql` files.
- Tier boundaries were hardcoded after calculation, since the underlying dataset is a static snapshot and won't be updated.
