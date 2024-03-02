-- design schema, create table and import data from csv file
DROP TABLE IF EXISTS OLYMPICS_HISTORY;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
id		INT,
name		VARCHAR,
sex		VARCHAR,
age		VARCHAR,
height		VARCHAR,
weight		VARCHAR,
team		VARCHAR,
noc		VARCHAR,
games		VARCHAR,
year		INT,
season		VARCHAR,
city		VARCHAR,
sport		VARCHAR,
event		VARCHAR,
medal		VARCHAR
);

DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_REGIONS;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS
(
noc		VARCHAR,
region		VARCHAR
);

select * from OLYMPICS_HISTORY;
select * from OLYMPICS_HISTORY_NOC_REGIONS;

-- 1. Identify the sport which was played in all summer olympics
	
with t1 as (
	select count(distinct games) as total_summer_games
	from OLYMPICS_HISTORY
	where season = 'Summer'),
	t2 as (
	select distinct sport, games
	from OLYMPICS_HISTORY
	where season = 'Summer'
	order by games),
	t3 as (
	select sport, count(games) as no_of_games
	from t2
	group by sport)
select * 
from t3
join t1 on t1.total_summer_games = t3.no_of_games;

-- 2. Fetch top 5 athletes who have won the most gold medals
with t1 as (
	select name, count(1) as total_medals
	from OLYMPICS_HISTORY
	where medal = 'Gold'
	group by name
	order by count(1) desc),
t2 as (
	select *, dense_rank() over(order by total_medals desc) as rnk
	from t1
)
select * 
from t2
where rnk <=5;

-- 3. list down total gold, silver and bronze medals won by each country

-- solution 1: create 3 different tables for gold, silver, bronze medal and join them together to create pivot table
with t1 as(
	select nr.region as country, medal
	from OLYMPICS_HISTORY oh
	join OLYMPICS_HISTORY_NOC_REGIONS nr on nr.noc = oh.noc
	where medal <> 'NA'),
t2 as (
	select country, count(medal) as gold
	from t1
	where medal = 'Gold'
	group by country
	order by gold desc),
t3 as (
	select country, count(medal) as silver
	from t1
	where medal = 'Silver'
	group by country
	order by silver desc),
t4 as (
	select country, count(medal) as bronze
	from t1
	where medal = 'Bronze'
	group by country
	order by bronze desc)

select distinct t1.country, coalesce (gold, 0) as gold, coalesce (silver, 0) as silver, coalesce (bronze, 0) as bronze
from t1
left join t2 on t1.country = t2.country
left join t3 on t1.country = t3.country
left join t4 on t1.country = t4.country
order by gold desc, silver desc, bronze desc;

-- solution 2: used crosstab to create pivot table
create extension tablefunc;

select country,
coalesce (gold, 0) as gold,
coalesce (silver, 0) as silver,
coalesce (bronze, 0) as bronze
from crosstab ('select nr.region as country, medal, count (1) as total_medals
				from OLYMPICS_HISTORY oh
				join OLYMPICS_HISTORY_NOC_REGIONS nr on nr.noc = oh.noc
				where medal <> ''NA''
				group by nr.region, medal
				order by nr.region, medal',
			  	'values (''Bronze''), (''Gold''), (''Silver'')')
			  as result (country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, silver desc, bronze desc;

