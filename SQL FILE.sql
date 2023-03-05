-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

SELECT 
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';
        
        
-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg


With unique_products as(
SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_product_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_product_2021
FROM
    fact_sales_monthly)
    
select *,
(unique_product_2021-unique_product_2020)*100/unique_product_2020 as percentage_change 
   from unique_products;
   
   
-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains 2 fields,
-- segment
-- product_count
SELECT segment,count(distinct(p.product_code))  as product_count 
from fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
group by segment 
order by product_count desc;


-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

with unique_product as (
SELECT segment,
 count(distinct case when fiscal_year=2020 then p.product_code end) as Unique_product_2020,
 count(distinct case when fiscal_year=2021 then p.product_code end) as unique_product_2021 
 from fact_sales_monthly s
join dim_product p on
s.product_code=p.product_code
group by segment)
select  *,
(unique_product_2021 - unique_product_2020) as new_products,
((unique_product_2021 - unique_product_2020)*100/unique_product_2020) as percentage_change from unique_product
order by new_products desc;



-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost
select product,fm.* from fact_manufacturing_cost fm
join dim_product p 
on fm.product_code=p.product_code
where 
    manufacturing_cost = (select max(manufacturing_cost) as max_cost from fact_manufacturing_cost) 

union all

select product,fm.* from fact_manufacturing_cost fm
join dim_product p 
on fm.product_code=p.product_code
where 
   manufacturing_cost = (select min(manufacturing_cost) as max_cost from fact_manufacturing_cost);


-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select c.customer_code,c.customer,
avg(pre_invoice_discount_pct*100)  as avg_discount
   from dim_customer c 
join fact_pre_invoice_deductions fp
      on 
c.customer_code=fp.customer_code
where market="india" and fiscal_year=2021
group by customer_code
order by avg_discount desc
limit 5;


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount


select monthname(s.date) as month,s.fiscal_year,
round(sum(sold_quantity*gross_price)/1000000,2) as gross_sales_amount_mln
from fact_sales_monthly s 
join fact_gross_price g 
   on
s.product_code=g.product_code and
s.fiscal_year=g.fiscal_year
join dim_customer c
on s.customer_code=c.customer_code
where customer ="Atliq Exclusive"
group by 1,2
order by 1,3 desc ;


-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity


select 
case
    when month(date) in (9,10,11) then  "Q1"
    when month(date) in (12,1,2) then "Q2"
    when month(date) in (3,4,5) then "Q3"
    else "Q4"
end as quarter,
sum(sold_quantity) as qty
from 
     fact_sales_monthly
where 
	fiscal_year=2020
group by 1
order by 2 DESC;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with sales_amount as (
select channel,
sum(sold_quantity*gross_price)/1000000 as gross_sales_in_mln from fact_sales_monthly s 
join dim_customer c
on s.customer_code=c.customer_code
join fact_gross_price p
on s.product_code=p.product_code 
and
s.fiscal_year=p.fiscal_year
where p.fiscal_year=2021
group by channel)
select*,
(gross_sales_in_mln*100)/sum(gross_sales_in_mln) over()
 as percentage_contribution from sales_amount
 order by percentage_contribution desc;
 
 
 -- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code

with sold_qty as (select p.division,p.product_code,p.product,
sum(sold_quantity) as total_qty from dim_product p
join fact_sales_monthly s 
on p.product_code=s.product_code
where s.fiscal_year=2021
group by 1,2,3),
rankr as (
select *,
dense_rank()over(partition by division order by total_qty desc) as rank_order from sold_qty)
select
  division,product_code,product,total_qty,rank_order 
  from rankr
  where rank_order<=3
  order by  division ;

