-- Advance Analytics

-- Change over time (Trends)

-- Total Sales by Year
select
year(fs.order_date) YearName,
sum(fs.sales_amount) TotalSales,
count(distinct(fs.customer_key)) CustomerCount,
sum(fs.quantity) TotalQuantity
from gold.fact_sales fs
group by year(fs.order_date)
having year(fs.order_date) is not null
order by year(fs.order_date)

-- Monthly Analysis
select
year(fs.order_date) YearName,
FORMAT(fs.order_date,'MMM') MonthName,
sum(fs.sales_amount) TotalSales,
count(distinct(fs.customer_key)) CustomerCount,
sum(fs.quantity) TotalQuantity
from gold.fact_sales fs
group by year(fs.order_date), month(fs.order_date), FORMAT(fs.order_date,'MMM')
having year(fs.order_date) is not null
order by year(fs.order_date), month(fs.order_date)
--

select
t.Month_Name,
t.TotalSales,
sum(t.TotalSales) over(partition by year(t.Month_Name) order by year(t.Month_Name), month(t.Month_Name)) as RunningTotal
from
(
select
CONCAT(FORMAT(fs.order_date,'MMM'),' ',year(fs.order_date)) as Month_Name,
sum(fs.sales_amount) as TotalSales
from gold.fact_sales fs
where fs.order_date is not null
group by year(fs.order_date), month(fs.order_date), FORMAT(fs.order_date,'MMM')
) t

-- Analyze the yearly performance of products by comparing their sales.
select top 5 * from gold.fact_sales
select top 5 * from gold.dim_products

with yearlySales as
(
select
year(fs.order_date) as YearName,
dp.product_name,
sum(sales_amount) as TotalSales
from gold.dim_products as dp
inner join gold.fact_sales as fs
on dp.product_key = fs.product_key
where fs.order_date is not null
group by year(fs.order_date), dp.product_key, dp.product_name
)
select
YearName,
product_name,
TotalSales,
avg(TotalSales) over(partition by product_name) as AvgSales,
TotalSales - avg(TotalSales) over(partition by product_name) as AvgDiff,
case
when 
	TotalSales - avg(TotalSales) over(partition by product_name) > 0 then 'Above Avg'
when 
	TotalSales - avg(TotalSales) over(partition by product_name) < 0 then 'Below Avg'
else
	'Avg'
end as AvgStatus,
lag(TotalSales) over(partition by product_name order by YearName) as prev_sales,
case
when 
	TotalSales - lag(TotalSales) over(partition by product_name order by YearName) > 0 then 'Increasing'
when 
	TotalSales - lag(TotalSales) over(partition by product_name order by YearName) < 0 then 'Decreasing'
else
	'No Change'
end as YearlyChange
from yearlySales
order by product_name

-- which categories contribute to the most to overall sales
select top 5 * from gold.dim_products

with productSales as
(
select 
dp.category,
sum(fs.sales_amount) as TotalSales
from gold.dim_products dp
inner join gold.fact_sales fs
on dp.product_key = fs.product_key
group by dp.category)
select 
category,
TotalSales,
sum(TotalSales) over() as GrandTotal,
concat(
ROUND(
(
CAST(TotalSales as float)
/
sum(TotalSales) over()
) * 100
,2)
,'%')
as Contribution
from productSales
order by Contribution desc

-- Segment products into cost ranges and count how many products fall into each segment
select top 5 * from gold.dim_products

with productSegments as
(
select
dp.product_key,
dp.product_name,
dp.cost,
case
	when dp.cost between 0 and 723 then 'Low Cost'
	when dp.cost between 724 and 1447 then 'Medium Cost'
else
	'High Cost'
end as CostSegments
from gold.dim_products dp
)
select
CostSegments,
count(product_key) as ProductCount
from productSegments
group by CostSegments
order by ProductCount desc

-- Group customers into three segments based on their spending behavior
-- VIP => Atleast 12 months of history and spending more than 5000
-- Regular => Atleast 12 months of history and spending 5000 or less
-- New => lifespan less than 12 months
-- Total no of customers by each group

select top 5 * from gold.dim_customers

with customerDetail as
(select
dc.customer_key,
sum(fs.sales_amount) TotalSales,
DATEDIFF(month,min(fs.order_date), max(fs.order_date)) as OrderMonths
from
gold.dim_customers dc
inner join gold.fact_sales fs
on dc.customer_key = fs.customer_key
group by dc.customer_key),
CustomerSegment as
(select
customer_key,
case
	when OrderMonths > 12 and TotalSales > 5000 then 'VIP'
	when OrderMonths >= 12 and TotalSales <= 5000 then 'Regular'
	else 'New'
end as CustomerSegments
from customerDetail)
select 
CustomerSegments,
count(customer_key) as CustomerCount
from CustomerSegment
group by CustomerSegments
order by CustomerCount desc

-- Customer Report
create view gold.report_customers as
with base_query as (
Select
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
concat(c.first_name,' ',c.last_name) as Customer_Name,
DATEDIFF(year,c.birthdate,getdate()) as Age
from gold.dim_customers c
inner join gold.fact_sales f
on c.customer_key = f.customer_key
where f.order_date is not null),
customer_aggregation as 
(select
customer_key,
Customer_Name,
Age,
count(distinct(order_number)) as TotalOrders,
sum(sales_amount) as TotalSales,
count(distinct(product_key)) as TotalProducts,
max(order_date) as LastOrderDate,
DATEDIFF(month,min(order_date),max(order_date)) as LifeSpan
from base_query
group by
customer_key,
Customer_Name,
Age)

select
customer_key,
Customer_Name,
Age,
case
	when Age < 20 then 'Under 20'
	when Age between 20 and 29 then '20-29'
	when Age between 30 and 39 then '30-39'
	when Age between 40 and 49 then '40-49'
	else '50 and above'
end as AgeGroup,
case
	when LifeSpan > 12 and TotalSales > 5000 then 'VIP'
	when LifeSpan >= 12 and TotalSales <= 5000 then 'Regular'
	else 'New'
end as CustomerSegments,
DATEDIFF(month,LastOrderDate,getdate()) as Recency,
case
	when TotalOrders = 0 then 0
else	TotalSales / TotalOrders 
end as AvgOrderValue,
case
	when LifeSpan = 0 then 0
else TotalSales / LifeSpan
end as AvgMonthlySpent,
TotalOrders,
TotalSales,
TotalProducts,
LastOrderDate,
LifeSpan
from customer_aggregation

-- calling view of customers
select top 5 * from gold.report_customers

-- Product Report

create view gold.vwProductReport as
with basequery as (
select 
p.product_key,
p.product_name,
p.category,
p.cost,
f.order_number,
f.order_date,
f.sales_amount,
f.quantity,
f.customer_key
from gold.dim_products p
inner join gold.fact_sales f
on p.product_key = f.product_key
),
product_aggregation as
(select 
product_key,
product_name,
category,
sum(cost) as TotalCost,
count(order_number) as TotalOrders,
sum(sales_amount) as TotalSales,
sum(quantity) as TotalQuantity,
count(distinct(customer_key)) as CustomerCount,
max(order_date) as LastOrderDate,
DATEDIFF(month,min(order_date),max(order_date)) as LifeSpan
from basequery
group by
product_key,
product_name,
category)

select
product_key,
product_name,
category,
TotalCost,
TotalOrders,
TotalSales,
TotalQuantity,
CustomerCount,
LifeSpan,
case
	when TotalSales between 1 and 1194 then 'Low Performer'
	when TotalSales between 1195 and 2386 then 'Mid Range'
else 'High Performer' 
end as ProductSegments,
DATEDIFF(month,LastOrderDate,getdate()) as Recency,
case 
	when TotalOrders = 0 then 0
	else TotalSales / TotalOrders
end as AverageOrderRevenue,
case
	when LifeSpan = 0 then 0
else TotalSales / LifeSpan
end as AvgMonthlyRevenue
from 
product_aggregation

--

select * from gold.vwProductReport