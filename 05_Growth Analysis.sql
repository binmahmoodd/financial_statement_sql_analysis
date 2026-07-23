--Growth Analysis

--Step 1: Baseline checks to have a look at the average revenue and earning growths and the min/max for both quantities
select 
	avg(rm.revenue_growth) as avg_revenuegrowth,
	avg(rm.earnings_growth) as avg_earningsgrowth,
	min(rm.revenue_growth) as min_revenuegrowth,
	max(rm.revenue_growth) as max_revenuegrowth,
	min(rm.earnings_growth) as min_earningsgrowth,
	max(rm.earnings_growth) as max_earningsrowth
from ratio_metrics rm ;
--revenue growth has an average of 36% but a min of -19.7% and a max of 3065% and earnings growth has an average of 212%, a min of -10% and a max of 24878%

--the values span a very large range, and I'm afraid there might be a few outliers affecting the average, so lets go for a median for both values
select
	PERCENTILE_CONT(0.5) within group(order by rm.revenue_growth ) as median_rg,
	PERCENTILE_CONT(0.5) within group(order by rm.earnings_growth) as median_eg
from ratio_metrics rm 
--These look more reasonable and so I'll be using them as my baseline

--Step 2: Top 10 fastest growing companies and slowest growing companies
select 
	rm.symbol,
	rm.revenue_growth 
from ratio_metrics rm 
order by revenue_growth desc
limit 10; /* Top 10*/

select 
	rm.symbol,
	rm.revenue_growth 
from ratio_metrics rm 
order by revenue_growth asc
limit 10; /* Bottom 10*/

--These queries reveal two important details:
-- 1. The revenue growth stat has one outlier in the pharmaceutical company MRNA which was affecting the average
-- 2. Earnings growth column has many nulls and many outliers, making it a very unreliable statistic to rely on, thus I'll be conducting this analysis based solely only revenue growth

--Step 3: Show how each company in the dataset compares to the median
with median_calc as (
    select
        percentile_cont(0.5) within group (order by revenue_growth) as median_revenue_growth
    from ratio_metrics
)
select
    rm.symbol,
    rm.revenue_growth,
    mc.median_revenue_growth,
    rm.revenue_growth - mc.median_revenue_growth as diff_from_median
from ratio_metrics rm
cross join median_calc mc;

--Step 4: Lets see if the fastest growing companies are also the most profitable
with cte_tiers as 
(
select 
	rm.symbol,
	rm.profit_margins,
	avg(rm.profit_margins) over() as avg_profitmargins,
	case 
		when rm.profit_margins >= 0.2272 then 'Excellent'
		when rm.profit_margins >= 0.1461 then 'Good'
		when rm.profit_margins >= 0.0859 then 'Moderate'
		when rm.profit_margins >= 0 then 'Poor'
		else 'Negative'
	end as category	
from ratio_metrics rm 
where rm.symbol != 'MRNA' /* to remove the outlier*/
)
select 
	t.category,
	avg(rm.revenue_growth) avg_revenuegrowth_bytier
from ratio_metrics rm 
join cte_tiers t
on rm.symbol = t.symbol 
group by category 
order by avg_revenuegrowth_bytier desc;
-- Excluding MRNA (identified earlier as an outlier), the profitability-growth link mostly disappears: Good, Moderate, Poor, and Excellent tiers all show
-- similar average growth (~21-25%). Only Negative-margin companies clearly lag (7.4%), suggesting financial distress affects growth more than profitability
