--Global_Profitability_Analysis

--Step 1: Find average gross, operating, EBITDA, and profit margins
select 
	avg(rm.gross_margins)*100     avg_grossmargins,
	avg(rm.operating_margins)*100  avg_operatingmargins,
	avg(rm.ebitda_margins)*100     avg_ebitdamargins,
	avg(rm.profit_margins)*100     avg_profitmargins 
from ratio_metrics rm ;
--I will be using profit margins as my leading metric for this analysis, and the average for this dataset is 16.99%

--Step 2: Just see how each company compares to average, this is just as a sanity-check, we'll be using percentile ranks for tiering the companies
select
	rm.symbol,
	rm.profit_margins,
	round(avg(rm.profit_margins) over(), 4) as avg_profitmargins
	from ratio_metrics rm ;

--Step 3:Figure out the 25th, 50th, and 75th percentile profit margins and use them as cutoff for categories
select 
	PERCENTILE_CONT(0.25)
		within group (order by rm.profit_margins) as first_quartile,
	PERCENTILE_CONT(0.5)
		within group (order by rm.profit_margins) as median,
	PERCENTILE_CONT(0.75)
		within group (order by rm.profit_margins) as third_quartile
from ratio_metrics rm ;
--first_quartile = 8.59%, median = 14.61%, third_quartile = 22.72%

--Step 4: We use these values to categorize our companies into 5 tiers: Excellent, Good, Moderate, Low, and Negative, I hardcoded the code since the database will not be updated and wrapped it as a cte to use in our next step
with cte_tiers as 
(
select 
	rm.symbol,
	rm.profit_margins,
	round(avg(rm.profit_margins) over(), 4) as avg_profitmargins,
	case 
		when rm.profit_margins >= 0.2272 then 'Excellent'
		when rm.profit_margins >= 0.1461 then 'Good'
		when rm.profit_margins >= 0.0859 then 'Moderate'
		when rm.profit_margins >= 0 then 'Poor'
		else 'Negative'
	end as category
from ratio_metrics rm 
)
--Step 5: Analyse the distribution of the companies under our tiering system
select 
	category,
	count(*) as companies
from cte_tiers 
group by category
order by 
	case category
		when 'Excellent' then 1
		when 'Good' then 2
		when 'Moderate' then 3
		when 'Poor' then 4
		when 'Negative' then 5
	end ;
 
