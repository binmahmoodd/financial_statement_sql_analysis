--Industry-Level Profitability Analysis

--Step 1: Number of companies within each industry
select 
	c.industry,
	count(*) as numberofcompanies
from companies c
group by c.industry 
having count(*) <= 2;
--46 out of 81 industries have less than 3 companies. These industries will be excluded for this analysis.

--Step 2: Find average profit margins for all the industries in our database and rank them in order of profitability
select 
	c.industry,
	avg(rm.profit_margins) as industryprofitmargins,
	count(*) as numberofcompanies
from ratio_metrics rm 
left join companies c 
on rm.symbol = c.symbol
group by c.industry
having count(*) >2
order by avg(rm.profit_margins) desc;

--Step 3: Comparing profit margins of each company within their own industries
with industry_list as 
(
select 
	c.industry,
	count(*) as numberofcompanies
from companies c 
group by c.industry
having count(*)>2
)
select 
	c.*,
	rm.profit_margins,
	avg(rm.profit_margins) over(partition by c.industry) as industrytypical,
	(rm.profit_margins - avg(rm.profit_margins) over(partition by c.industry)) as difference,
	rank() over(partition by c.industry order by rm.profit_margins DESC) as rank_within_industry,
	il.numberofcompanies 
from companies c
join industry_list il 
on c.industry = il.industry 
join ratio_metrics rm 
on c.symbol = rm.symbol;
--The query shows all companies belonging to industries with 3 or more companies, their profit margins, the difference between their profit margin and the industry typical, and their rank within the industry
