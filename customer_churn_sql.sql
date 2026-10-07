create database churn_db;
select COUNT(*) from churn_db.customer_data;

--  autopay enabled churn less than those without it


select
    autopay_enabled,
    COUNT(*)  as customers,
    SUM(churned)  as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from customer_data
group by autopay_enabled;



-- payment method (credit card, PayPal, bank transfer, manual/invoice)

 
select
    payment_method,
    COUNT(*)  as customers,
    SUM(churned)  as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from customer_data
group by payment_method
order by churn_rate_pct desc;


-- total customers are there, and what percentage have churned

select
    COUNT(*)   as total_customers,
    SUM(churned)  as churned_customers,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from customer_data;



-- (Basic, Standard, Premium) has the highest churn rate

select
    plan_type,
    COUNT(*)  as customers,
    SUM(churned)  as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from customer_data
group by plan_type
order by churn_rate_pct desc;

-- contract type (Month-to-month, One year, Two year) has the highest churn rate?

SELECT
    contract_type,
    COUNT(*) as customers,
    SUM(churned)  as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from  customer_data
group by contract_type
order by churn_rate_pct desc;


-- churn rate go up or down as tenure increases (Group customers into 0-6mo, 6-12mo, 12-24mo, 24mo+)


select
    case
        when tenure_months < 6  then '0-6mo'
        when tenure_months < 12 then '6-12mo'
        when tenure_months < 24 then '12-24mo'
        else '24mo+'
    end as tenure_bucket,
    COUNT(*) as customers,
    SUM(churned) as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)   as churn_rate_pct
from customer_data
group by tenure_bucket
order by MIN(tenure_months);




-- total revenue came from churned customers vs. retained customers


select
    case when churned = 1 then 'Churned' else 'Retained' end as segment,
    COUNT(*)   as customers,
    ROUND(SUM(total_revenue), 2)   as total_revenue,
    ROUND(AVG(total_revenue), 2)   as avg_revenue_per_customer
from  customer_data
group by segment;


-- percentage of all revenue came from customers who eventually churned?

select
    ROUND(100.0 * SUM(case when churned = 1 then total_revenue else 0 end)
          / SUM(total_revenue), 1) as pct_revenue_from_churned
from customer_data;


-- churned customers use the product less than retained customers? (Compare usage_score, logins_per_month, features_used)


select
    case when churned = 1 then 'Churned' else 'Retained' end as segment,
    ROUND(avg(usage_score), 1)   as avg_usage_score,
    ROUND(avg(logins_per_month), 1) as avg_logins_per_month,
    ROUND(avg(features_used), 1)  as avg_features_used
from customer_data
group by segment;



-- churned customers file more support tickets than retained customers

select
    case when churned = 1 then 'Churned' else 'Retained' end as segment,
    ROUND(avg(usage_score), 1)  as avg_usage_score,
    ROUND(avg(logins_per_month), 1)  as avg_logins_per_month,
    ROUND(avg(features_used), 1)  as avg_features_used
from customer_data
group by segment;


-- churned customers file more support tickets than retained customers

select
    case when churned = 1 then 'Churned' else 'Retained' end as segment,
    ROUND(avg(support_tickets_6m), 2) as avg_support_tickets
from customer_data
group by segment;

-- unresolved complaint increase someone's chance of churning
select
    complaint_unresolved,
    COUNT(*)  as customers,
    SUM(churned) as  churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1) as churn_rate_pct
from customer_data
group by complaint_unresolved;

-- What's the churn rate for customers who are Month-to-month, have usage_score under 40, AND have an unresolved complaint — all three at once?
select
    COUNT(*)  as customers,
    SUM(churned)  as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from customer_data
where contract_type = 'Month-to-month'
  and usage_score < 40
  and complaint_unresolved = 1;
  
  -- Does the year someone signed up affect their churn rate?
  select
    year(signup_date) as signup_year,
    COUNT(*) as  customers,
    SUM(churned)   as churned,
    ROUND(100.0 * SUM(churned) / COUNT(*), 1)  as churn_rate_pct
from customer_data
group by signup_year
order by signup_year;



-- 50 currently-active customers are most at risk of churning next

select
    customer_id,
    plan_type,
    contract_type,
    tenure_months,
    usage_score,
    support_tickets_6m,
    complaint_unresolved,
    total_revenue,
    (case contract_type when 'Month-to-month' then 2 when 'One year' then 1 else 0 END)
    + (case when usage_score < 40 then 2 when usage_score < 55 then 1 else 0 end)
    + (case when complaint_unresolved = 1 then 3 else 0 end)
    + (case when support_tickets_6m >= 2 then 1 else 0 end)
    + (case when tenure_months < 12 then 1 else 0 end)  as risk_score
from customer_data
where churned = 0
order by risk_score desc
limit 50;


