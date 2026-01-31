use app_simulation;
with 
base_stats as (select
					channel, count(distinct user_id) as total_users,
					sum(activated) as activated_users
					from users
					group by channel
),
revenue_stats as(
		select 
			u.channel, count(distinct o.user_id) as paying_users,
			sum(o.amount) as total_gmv,
			sum(case when datediff(date(o.order_time), u.install_date) between 0 and 6 then o.amount else 0 end) as gmv_7,
			sum(case when datediff(date(o.order_time), u.install_date) between 0 and 29 then o.amount else 0 end) as gmv_30
		from users u 
		left join orders o on u.user_id = o.user_id
		group by u.channel
),
repurchase_stats as (
		select 
			u.channel, 
			count(distinct case when purchase_cnt>=2 then u.user_id end) as repeat_users
		from (
			select user_id, count(*) as purchase_cnt from orders group by user_id) t
			join users u on t.user_id = u.user_id
		group by u.channel
)

select 
	b.channel as 渠道, 
-- ======================
-- Acuqisition 获客
-- ======================
	b.total_users as 总用户数,
	round(b.total_users * 1.0/ (select count(*) from users),4) as 用户占比,

-- ======================
-- Activation 激活
-- ======================
	round(b.activated_users*1.0/total_users*100,4) as 激活率,

-- ======================
-- Revenue 变现
-- ======================
	ifnull(rv.paying_users,0) as 付费用户数,
	round(ifnull(rv.paying_users,0)*1.0/b.total_users, 4) as 付费转化率,
	round(ifnull(rv.total_gmv,0),4) as 总GMV,
	round(ifnull(rv.total_gmv,0)/ifnull(rv.paying_users,0),4) as ARPPU,
-- LTV
	round(ifnull(rv.gmv_7,0)/b.total_users,4) as LTV_7,
	round(ifnull(rv.gmv_30,0)/b.total_users,4) as LTV_30,
	round(ifnull(rv.total_gmv,0)/b.total_users,4) as LTV_total,
-- 复购
	round(ifnull(rp.repeat_users,0)*1.0/nullif(rv.paying_users,0),4) as 复购率
from base_stats b left join revenue_stats rv on b.channel = rv.channel
left join repurchase_stats rp on b.channel = rp.channel;


-- ======================
-- Retention 留存
-- ======================
select u.channel as 渠道, date(u.install_date) as 注册日期, count(distinct u.user_id) as 新增用户数,
	round(count(distinct case when DATEDIFF(ll.login_date, u.install_date) = 1 then ll.user_id end)/count(distinct u.user_id),4) as 次日留存率,
	round(count(distinct case when DATEDIFF(ll.login_date, u.install_date) = 7 then ll.user_id end)/count(distinct u.user_id),4) as '7日留存率',
	round(count(distinct case when DATEDIFF(ll.login_date, u.install_date) = 30 then ll.user_id end)/count(distinct u.user_id),4) as '30日留存率'
from users u 
left join login_log ll on u.user_id = ll.user_id
group by u.install_date, u.channel
order by u.install_date asc;

-- ======================
-- Referral 传播
-- ======================
select
	count(case when channel = 'Friend_Referral' then user_id end) as 推荐渠道新增用户数,
	round(COUNT(case when channel = 'Friend_Referral' then user_id end) * 1.0 /count(distinct user_id),4) as K,
	ROUND(COUNT(case when channel = 'Friend_Referral' then user_id end) * 1.0 / COUNT(DISTINCT inviter_id), 2) AS 人均拉新数
from users;