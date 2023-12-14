--DANNYS_DINNER
use dannys_diner
-- 1.What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) as total_spent 
from sales join menu on sales.product_id = menu.product_id
group by customer_id

-- 2.How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) from sales 
group by customer_id

-- 3.What was the first item from the menu purchased by each customer?

with cte_rank as (	select customer_id,product_name,sales.order_date,
					ROW_NUMBER() over (partition by customer_id order by order_date) as rn 
					from menu join sales on menu.product_id = sales.product_id)

select customer_id,product_name,order_date from cte_rank where rn =1


-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name, count(sales.product_id) as number_times 
from sales join menu on sales.product_id = menu.product_id
group by product_name

??  = nhau -- 5.Which item was the most popular for each customer?
with cte_popular_cus as (
select product_name, customer_id, count(sales.product_id) as number_times
from sales join menu on sales.product_id = menu.product_id
group by customer_id,product_name)
select top 3* from cte_popular_cus
order by number_times desc

-- 6.Which item was purchased first by the customer after they became a member?
with cte_first_purchase as (select product_name,members.customer_id,order_date,join_date,
ROW_NUMBER() over (partition by members.customer_id order by order_date) as rn 
from sales join menu 
on sales.product_id = menu.product_id join members 
on members.customer_id = sales.customer_id
where join_date<order_date)
select * from cte_first_purchase 
where rn =1 

select * from sales
select * from menu
select * from members

-- 7.Which item was purchased just before the customer became a member?
with cte_purchased_before_mem as 
(select product_name,members.customer_id,order_date,join_date,
row_number() over (partition by members.customer_id order by order_date desc) as rn
from sales join menu 
on sales.product_id = menu.product_id join members 
on members.customer_id = sales.customer_id
where order_date<join_date)
select * from cte_purchased_before_mem 
where rn =1

-- 8.What is the total items and amount spent for each member before they became a member?
select members.customer_id,product_name, count(menu.product_id) as total_items,sum(price) as amount
from sales join menu on sales.product_id = menu.product_id
join members on members.customer_id = sales.customer_id
where order_date < join_date
group by product_name,members.customer_id

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
alter table sales add points int
		-- update
select customer_id,product_name,sum(price) as total_amount 
	into table_9 from sales join menu on sales.product_id = menu.product_id 
	group by product_name, customer_id

with cte_question9 as 
	(
	select customer_id, case when product_name = 'sushi' then  total_amount*10
	else  total_amount*10*2 
	end as points from table_9
	)
select customer_id,sum(points) as total_points 
from cte_question9
group by customer_id

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
---how many points do customer A and B have at the end of January?
--- firstweek *2 for all, after first week?

select customer_id,product_name,sum(price) as total_amount, order_date into table_10
	from sales join menu on sales.product_id = menu.product_id 
	group by product_name, customer_id, order_date 

with cte_question_10 as 
	(
	select table_10.customer_id, points =
	case when (order_date > join_date) and (order_date < dateadd(DAY,7,join_date)) and month(order_date) = 1
		then total_amount*20
		when (order_date>join_date) and (order_date>dateadd(day,7,join_date)) and product_name = 'sushi' and month (order_date)=1
		then total_amount*20 
		when (order_date>join_date) and (order_date>dateadd(day,7,join_date)) and product_name != 'sushi' and month (order_date)=1
		then total_amount*10 
		end
	from table_10 join members on table_10.customer_id = members.customer_id
	)
select customer_id, sum(points) as points from cte_question_10
group by customer_id
