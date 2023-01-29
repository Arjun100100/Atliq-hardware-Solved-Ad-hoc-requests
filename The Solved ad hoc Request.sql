use gdb023;
show tables;

/*The list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/

select distinct market as Market_List
from dim_customer
where customer = 'Atliq Exclusive' and region='APAC';

/* The percentage of unique product increase in 2021 vs. 2020 */

with temp_t1 as (select
count(distinct product_code) as Unique_Products_2020
from fact_sales_monthly
where fiscal_year=2020),
temp_t2 as ( select
count(distinct product_code) as Unique_Products_2021
from fact_sales_monthly
where fiscal_year=2021)
select a.Unique_Products_2020,
	b.Unique_Products_2021,
    round(100*(b.unique_products_2021-a.unique_products_2020)/a.unique_products_2020,2) as Percentage_Change
from temp_t1 as a
join temp_t2 as b;

/*the unique product counts for each segment */
select Segment,
count( distinct product_code) as Product_Count
from dim_product
group by segment
order by 2 desc;

/* The most increase in unique products in 2021 vs 2020 */

with temp_t1 as (select prod.Segment,
count( distinct case when ms.fiscal_year = 2020 then prod.product_code end) as Unique_Count_2020,
count( distinct case when ms.fiscal_year = 2021 then prod.product_code end) as Unique_Count_2021
from dim_product as prod
join fact_sales_monthly as ms
on prod.product_code=ms.product_code
group by 1)
select *,
	(unique_count_2021-unique_count_2020) as Difference
from temp_t1
order by 4 desc;

/*The products that have the highest and lowest manufacturing costs*/

(select prod.Product_Code,
	prod.Product,
    max(mc.manufacturing_cost) as Manufacturing_Cost
from dim_product as prod
join fact_manufacturing_cost as mc
on prod.product_code= mc.product_code 
group by 1,2
order by 3 desc
limit 1)
union all
(select prod.Product_Code,
	prod.Product,
    min(mc.manufacturing_cost)  as Manufacturing_Cost
from dim_product as prod
join fact_manufacturing_cost as mc
on prod.product_code= mc.product_code 
group by 1,2
order by 3 asc
limit 1);

/*The top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.*/
select cst.Customer_Code,
	cst.Customer,
    round(avg(ivd.pre_invoice_discount_pct),2) as Average_Discount_Percentage
from dim_customer as cst
join fact_pre_invoice_deductions as ivd
on cst.customer_code=ivd.customer_code
where cst.market = 'India' and ivd.fiscal_year=2021
group by 1,2
order by 3 desc
limit 5;

/*The Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions.*/

select monthname(ms.date) as Month,
year(ms.date) as Year,
round(sum(ms.sold_quantity*gpt.gross_price),2) as Gross_Sales
from fact_sales_monthly as ms
join fact_gross_price as gpt
on gpt.product_code=ms.product_code
join dim_customer as cst
on ms.customer_code=cst.customer_code
where cst.customer='Atliq Exclusive'
group by 1,2
order by 2,
CASE 
        WHEN 1 = 'January' THEN '1' 
        WHEN 1 = 'February' THEN '2' 
        WHEN 1 = 'March' THEN '3' 
        WHEN 1 = 'April' THEN '4' 
        WHEN 1 = 'May' THEN '5' 
        WHEN 1 = 'June' THEN '6' 
        WHEN 1 = 'July' THEN '7' 
        WHEN 1 = 'August' THEN '8' 
        WHEN 1 = 'September' THEN '9' 
        WHEN 1 = 'October' THEN '10' 
        WHEN 1 = 'November' THEN '11' 
        WHEN 1 = 'December' THEN '12' 
        ELSE 'Invalid Month' end;
        
/*  In which quarter of 2020, got the maximum total_sold_quantity? */

SELECT 
  CASE 
    WHEN MONTH(ms.date) IN (9,10,11) THEN 1
    WHEN MONTH(ms.date) IN (12,1,2) THEN 2
    WHEN MONTH(ms.date) IN (3,4,5) THEN 3
    WHEN MONTH(ms.date) IN (6,7,8) THEN 4
  END AS Quarter,
  sum(sold_quantity) as Total_Sold_Quantity
from fact_sales_monthly as ms
where fiscal_year=2020
group by 1
order by 2 desc;

/* Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? */
with temp_1 as (
select cst.channel,
	sum(ms.sold_quantity*gpt.gross_price)  sales
from dim_customer as cst
join fact_sales_monthly as ms
on ms.customer_code=cst.customer_code
join fact_gross_price as gpt
on gpt.product_code=ms.product_code
where ms.fiscal_year=2021
group by 1
order by 2)
select Channel,
	round((sales/1000000),2) Gross_sales_mln,
	round(sales*100/sum(sales) over(),2) as Percentage
from temp_1
order by 3 desc;

/* Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021 */

with temp_t1 as (select prod.Division,
	prod.product_code,
    prod.Product,
    sum(ms.sold_quantity) AS Total_Quantity_Sold
from dim_product as prod
join fact_sales_monthly as ms
on prod.product_code=ms.product_code
where ms.fiscal_year=2021
group by 1,2,3
),
temp_t2 as (
select *,
	Rank() over(partition by Division order by Total_Quantity_Sold desc) as Rank_Order
from temp_t1)
select *
from temp_t2
where Rank_Order<=3;







