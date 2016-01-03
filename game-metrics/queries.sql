.mode csv
.headers on
.import item_purchases.csv purchases
.import app_installs.csv installs

.output daily_installs.csv

select
date(time) as day,
count(distinct player_id) as daily_installs
from installs
group by day
order by day;

.import daily_installs.csv daily_installs

.output daily_cumulative_installs.csv

select
t1.day,
t1.daily_installs,
(
    select sum(t2.daily_installs)
    from daily_installs t2
    where t2.day <= t1.day
) as cumulative
from daily_installs t1;

.import daily_cumulative_installs.csv daily_cumulative_installs

.output daily_revenue.csv

select
date(time) as day,
sum(cast(item_cost as int)) as daily_revenue
from purchases
group by day
order by day;

.import daily_revenue.csv daily_revenue

.output daily_cumulative_revenue.csv

select
t1.day,
t1.daily_revenue,
(
    select sum(t2.daily_revenue)
    from daily_revenue t2
    where t2.day <= t1.day
) as cumulative
from daily_revenue t1;

.import daily_cumulative_revenue.csv daily_cumulative_revenue

.output arpu.csv

create view cumulative_join as
select
t1.day,
t1.cumulative as cumulative_installs,
t2.cumulative as cumulative_revenue
from
daily_cumulative_installs t1
join
daily_cumulative_revenue t2
on t1.day = t2.day;

select
day,
cumulative_revenue*1.0 / cumulative_installs as arpu
from cumulative_join;

.output first_purchase_times.csv

select
player_id as pid,
date(time) as day
from purchases
where day = (
    select min(date(time))
    from purchases
    where player_id = pid
)
group by pid;

.import first_purchase_times.csv first_purchase_times

.output daily_first_purchases.csv

select
day,
count(*) as first_purchases
from first_purchase_times
group by day;

.import daily_first_purchases.csv daily_first_purchases

.output daily_cumulative_first_purchases.csv

select
t1.day,
t1.first_purchases,
(
    select sum(t2.first_purchases)
    from daily_first_purchases t2
    where t2.day <= t1.day
) as cumulative
from daily_first_purchases t1;

.import daily_cumulative_first_purchases.csv daily_cumulative_first_purchases

.output conversion.csv

create view cumulative_join_2 as
select
t1.day,
t1.cumulative as cumulative_installs,
t2.cumulative as cumulative_first_purchases
from
daily_cumulative_installs t1
join
daily_cumulative_first_purchases t2
on t1.day = t2.day;

select
day,
cumulative_first_purchases*1.0 / cumulative_installs as conversion
from cumulative_join_2;

.import conversion.csv conversion

.output daily_conversion_percent_change.csv

select
t2.day,
(t2.conversion/t1.conversion)-1 as percent_change
from
conversion t1
join
conversion t2
on date(t2.day) = date(t1.day,'+1 day');