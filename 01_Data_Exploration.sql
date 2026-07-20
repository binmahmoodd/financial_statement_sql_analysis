--Data cleaning

--To ensure no data lost during import
select 
	count(*)
from financialdata f;

--To check for any duplicate companies
select 
	f.symbol, 
	count(*)
from financialdata f 
group by symbol
having count(*) > 1;

--To check for any nulls
select
    count(*) filter (where  is null) as null_symbol,
    count(*) filter (where "shortName" is null) as null_name,
    count(*) filter (where "industry" is null) as null_industry,
    count(*) filter (where "profitMargins" is null) as null_profitmargins,
    count(*) filter (where "debtToEquity" is null) as null_debttoequity,
    count(*) filter (where "marketCap" is null) as null_marketcap
from financialdata f; /*Nothing too catastrophic, a few nulls here and there that can be handled later*/

--To double check the values
select
    min(f."profitMargins"), max(f."profitMargins"),
    min("debtToEquity"), max(f."debtToEquity"), /*max(debttoequity) is really high, so we'll be looking into that*/
    min(f."marketCap"), max(f."marketCap")
from financialdata f ;
--debttoequity outlier
select 
	f."shortName",
	f."totalDebt",
	f."debtToEquity"
from financialdata f 
where f."debtToEquity" is not null
order by f."debtToEquity" desc;
limit 5 /*it's a formatting issue that can be fixed when I split the raw data*/

--Checking other ratios
select
	f."currentRatio",
	f."quickRatio",
	f."profitMargins",
	f."ebitdaMargins",
	f."grossMargins",
	f."operatingMargins",
	f."returnOnAssets",
	f."returnOnEquity",
	f."pegRatio" 
from financialdata f; /*everything else looks fine*/

--So, Sr.NO goes up to 240 but I have only 226 rows, lets try to figure out why
select 	
	gs as missing_number,
	f.*
from generate_series(1,240) gs
left join financialdata f 
on f."Sr.NO" = gs
where f."Sr.NO" is null
order by gs
/*the missing numbers are spread out and so the creator of this data probably filtered it out due to unknown causes*/