--Split raw import into normalized companies + financials tables
-- Applies fixes identified during exploration:
--   - debtToEquity divided by 100 (corrects scaling issue)
--   - ratio/margin columns cast to numeric for precision
-- ==================================================================

--Reference table, contains company names and static info
create table companies as
(
select distinct
	f."symbol",
	f."shortName" as companyname,
	f."industry"
from financialdata f
);

--raw_metrics (direct dollar/share figures as reported, nothing calculated), cleaned and cast
create table raw_metrics as
(
select
    "symbol",
    "marketCap",
    "enterpriseValue",
    "totalRevenue",
    "grossProfits",
    "ebitda",
    "operatingCashflow",
    "freeCashflow",
    "totalCash",
    "totalDebt",
    "sharesOutstanding",
    "currentPrice"::numeric(12,2)      as current_price,
    "revenuePerShare"::numeric(10,2)   as revenue_per_share,
    "totalCashPerShare"::numeric(10,2) as total_cash_per_share,
    "bookValue"::numeric(10,2)         as book_value,
    "forwardEps"::numeric(10,2)        as forward_eps,
    "trailingEps"::numeric(10,2)       as trailing_eps
from financialdata
);

--ratio_metrics (all derived/calculated figures), cleaned and cast
create table ratio_metrics as
(
select
    "symbol",
    "grossMargins"::numeric(10,4)              as gross_margins,
    "operatingMargins"::numeric(10,4)          as operating_margins,
    "ebitdaMargins"::numeric(10,4)              as ebitda_margins,
    "profitMargins"::numeric(10,4)              as profit_margins,
    "revenueGrowth"::numeric(10,4)              as revenue_growth,
    "earningsGrowth"::numeric(10,4)             as earnings_growth,
    "earningsQuarterlyGrowth"::numeric(10,4)    as earnings_quarterly_growth,
    "returnOnAssets"::numeric(10,4)             as return_on_assets,
    "returnOnEquity"::numeric(10,4)             as return_on_equity,
    "heldPercentInsiders"::numeric(10,4)        as held_percent_insiders,
    ("debtToEquity" / 100.0)::numeric(10,2)     as debt_to_equity,
    "currentRatio"::numeric(10,2)               as current_ratio,
    "quickRatio"::numeric(10,2)                 as quick_ratio,
    "priceToBook"::numeric(10,2)                as price_to_book,
    "forwardPE"::numeric(10,2)                  as forward_pe,
    "pegRatio"::numeric(10,2)                   as peg_ratio,
    "enterpriseToRevenue"::numeric(10,2)        as enterprise_to_revenue,
    "enterpriseToEbitda"::numeric(10,2)         as enterprise_to_ebitda
from financialdata
)
 