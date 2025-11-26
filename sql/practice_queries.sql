Use cp_tb

#  Create Table sales :--
CREATE TABLE sales (
    id INT,
    category VARCHAR(20),
    product VARCHAR(50),
    sales_amount INT
);

INSERT INTO sales VALUES
(1, 'Electronics', 'Mobile A', 500),
(2, 'Electronics', 'Mobile B', 700),
(3, 'Electronics', 'Laptop A', 1500),
(4, 'Clothing', 'Shirt A', 200),
(5, 'Clothing', 'Shirt B', 300),
(6, 'Clothing', 'Jacket A', 800),
(7, 'Grocery', 'Milk', 50),
(8, 'Grocery', 'Sugar', 80),
(9, 'Grocery', 'Oil', 120);

select * from sales;  #---------------

#---------------------------Window Function---------------------------#
select category , product ,sales_amount, 
ROW_number() over (partition by category order by sales_amount desc) AS rn
from sales;

select category , product , sales_amount,
rank() over (partition by category order by sales_amount desc) AS rnk
from sales;

# LEAD() with Window Function :--
select product , sales_amount,
lead(sales_amount) over (order by sales_amount desc) As next_sales
from sales
order by sales_amount asc;

INSERT INTO sales VALUES
(10, 'Electronics', 'Headphone A', 700);

# LAG() with Window Function :--
SELECT
    product,
    sales_amount,
    LAG(sales_amount) OVER (ORDER BY sales_amount DESC) AS previous_sales
FROM sales
ORDER BY sales_amount DESC;

select product ,sales_amount,
lead(sales_amount) over(order by sales_amount) AS rn,
sales_amount - lead(sales_amount) over(order by sales_amount) AS rnk
from sales
order by sales_amount DESC;


select product , sales_amount, next_sales , sales_diff
from (
	select product , sales_amount,
    lead(sales_amount) over (order by sales_amount desc) AS next_sales,
    sales_amount - lead(sales_amount) over (order by sales_amount desc) AS sales_diff
    from sales
) AS subquery_sales
where sales_diff > 300
order by sales_amount desc;

# --- Find Top 2 selling products per category :--
select * 
from ( 
	select category , sales_amount, product,
    rank() over (partition by category order by sales_amount desc) AS rnk
    from sales
) AS ranked_sales
where rnk <= 2
order by category , rnk;

# only 2nd rank category products (Subquery / inner query)
select * from (
	select category , sales_amount, product,
	DENSE_RANK() over (partition by category order by sales_amount desc) AS rnk
    from sales
) AS ranked_sales
where rnk = 2
order by category , rnk, product;

# using aggregate functions with window functions
select product , sales_amount, 
SUM(sales_amount)  over (order by sales_amount)AS sum_sales
from sales;

select product ,  category ,sales_amount, 
SUM(sales_amount)  over (partition by category order by sales_amount)AS sum_sales
from sales;

select product , sales_amount,
sum(sales_amount) over() AS total_sales,
sales_amount/sum(sales_amount) over() *100 AS percetage
from sales
order by percetage desc;

SELECT *
FROM (
    SELECT
        product,
        sales_amount,
        sales_amount * 100.0 / SUM(sales_amount) OVER () AS pct
    FROM sales
) AS t
WHERE pct > 5
ORDER BY pct DESC;

# ------------------------- JOIN ----------------#
# Create Tables 
CREATE TABLE customers (
    customer_id INT,
    name VARCHAR(50)
);

INSERT INTO customers (customer_id, name) VALUES
(1, 'John'),
(2, 'Sara'),
(3, 'Akhil');

# Create Tables -2 :--
CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    amount INT
);

INSERT INTO orders (order_id, customer_id, amount) VALUES
(101, 1, 500),
(102, 1, 800),
(103, 2, 300);

select * from orders, customers;

select c.customer_id , c.name
from customers c
left join orders o 
	on c.customer_id = o.customer_id
where o.customer_id IS NULL;

# Group By with HAVING Clause :--
select sum(amount) , customer_id
from orders
group by customer_id;

select sum(amount) , customer_id
from orders
group by customer_id having sum(amount) > 1000;

select count(order_id) AS count ,customer_id
from orders
group by customer_id having count(order_id) >1;

select customer_id , avg(amount)
from orders
group by customer_id having avg(amount)>400;

# -----------------  CASE - END Clause -----------------#
# Sample to understand the CASE - END clause :--
select order_id , amount,
CASE
	WHEN amount>400 then 'High'
    WHEN amount BETWEEN 300 and 400 then 'Medium'
    ELSE 'LOW'
END AS amount_category 
from orders;

#   Find total sales by category (High/Medium/Low)  :--
select
CASE
	WHEN amount>400 then 'High'
    WHEN amount BETWEEN 300 and 400 then 'Medium'
    ELSE 'LOW'
END AS category ,
sum(amount)
from orders
group by category;

# Find total sales for High orders (amount > 600) :--
select
	SUM(
		CASE 
			WHEN amount > 600 THEN amount
			ELSE 0
		END
        ) AS total_amount
FROM orders;

# Count how many orders are High (amount > 600) :--
select 
	count(
		CASE 
			WHEN amount > 600 THEN 1
            ELSE null
		END
        ) AS high_order_amount
FROM orders;

# Count high, medium, and low orders in one query. :--
SELECT 
	COUNT(CASE WHEN amount > 600 THEN 1 END) AS high_count,
    COUNT(CASE WHEN amount BETWEEN 300 AND 600 THEN 1 END) AS medium_count,
    COUNT(CASE WHEN amount < 300 THEN 1 END) AS low_count
from orders;

# -----------------------------------
SELECT * FROM orders;
select * from customers;

# Find total sales from each order category :--
SELECT 
	SUM(CASE WHEN amount > 600 THEN amount END) AS high_sales,
    SUM(CASE WHEN amount BETWEEN 300 AND 600 THEN amount END) AS medium_sales,
    coalesce(SUM(CASE WHEN amount < 300 THEN amount END),0) AS low_sales
from orders;

# ----------------------------------   CTE - Common Table Expression -------------------------#
# CTE = A CTE is like creating a temporary result that you can use in your next query
# Sample Query of CTE 
WITH temp_tb AS (
	SELECT 
		customer_id ,
        SUM(amount) AS total_amount
	FROM orders 
    group by customer_id
)
select * from temp_tb;

#  Find customers whose total orders are > 500 :--
WITH temp_tb AS (
	SELECT customer_id ,
    SUM(amount) AS total_amount
    from orders
    group by customer_id
)
select * from temp_tb
where total_amount > 500;

# Find the customer who has the highest total order amount :--
WITH temp_tb AS (
	SELECT customer_id , 
    SUM(amount) AS total_amount
    from orders
    group by customer_id
)
SELECT * FROM temp_tb
order by total_amount DESC
LIMIT 1;

# Another method by using CTE
WITH temp_tb AS (
	SELECT customer_id, 
		SUM(amount) AS total_amount
        from orders
        group by customer_id
),
max_val AS (SELECT MAX(total_amount) AS max_value from temp_tb)
select * from temp_tb
JOIN max_val mx ON temp_tb.total_amount = mx.max_value;

#Find customers whose total order amount is ABOVE :--
#   the average total order amount across all customers
WITH total_cs AS(
	SELECT 
    customer_id , 
    SUM(amount) AS total_amount
    FROM orders
    group by customer_id
),
avg_amount AS (
	SELECT AVG(total_amount) AS avg_amount FROM total_cs)
SELECT o.customer_id , o.total_amount
FROM total_cs o 
cross join avg_amount a
where o.total_amount > a.avg_amount;

# ------------------------------- DATE Functions------------------------#
# Create table for Date Functions 
CREATE TABLE orders_date (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount INT
);

INSERT INTO orders_date VALUES
(1, 1, '2023-01-10', 500),
(2, 1, '2023-02-15', 800),
(3, 2, '2023-02-20', 300),
(4, 3, '2023-03-05', 700);

SELECT * FROM orders_date;

# Extract year , month form table :--
SELECT order_id , customer_id , order_date , 
	year(order_date) AS Year,
    month(order_date) AS MONTH
FROM orders_date;

# DATE_FORMAT() - Extract year, month together from table :--
SELECT order_id , order_date , 
	DATE_FORMAT(order_date , '%Y-%m') AS year_months
FROM orders_date;

# DATEDIFF() (Calculate Days Between Two Dates)
SELECT order_id , order_date,
	datediff(NOW() , order_date) AS days_since_order
FROM orders_date;

SELECT order_id , order_date ,
	datediff('2023-03-10' , order_date) AS days_since_order
FROM orders_date;

# Grouping by month
SELECT SUM(amount) AS total_sales, 
	date_format(order_date , '%Y-%m') AS order_month
FROM orders_date
group by order_month
order by order_month;

# Find the number of days between the earliest order and the latest order :--
WITH date_diff AS (
	SELECT
    MAX(order_date) AS first_order,
    min(order_date) AS last_order
    FROM orders_date
)
SELECT datediff(first_order , last_order) AS no_of_days
from date_diff;


# ------------------------------------    SUBQUERY - (IN , EXISTS , NOT EXISTS) ----------------------#
# Find customers who have placed an order :--
select * from customers;
select * from orders;
SELECT name 
from customers
where customer_id IN(select distinct customer_id from orders);

# Find customers who did NOT place any order :--
select name
from customers
where customer_id NOT IN(select distinct customer_id from orders);

# Find customers who placed orders greater than 500 :--
select name
from customers
where customer_id in (select customer_id from orders where amount > 500);

# -------  EXISTS / NOT EXISTS ----
# Find customers who placed at least one order--
SELECT name
FROM customers
WHERE EXISTS (
	select customer_id from orders where customers.customer_id = orders.customer_id);

# using NOT EXISTS then NOT IN :--
select name 
from customers c
where not exists ( select o.customer_id from orders o where c.customer_id = o.customer_id);

# Find customers with total order amount greater than 500 :-- 
# Subquery in FROM()
select *
from ( 
		SELECT customer_id , SUM(amount) AS total_amount
        FROM orders
        group by customer_id
	) AS ts                    # (ts - act as temporary table)
where total_amount > 500;



# Create new table with products name :--
CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(100),
  price INT
);

INSERT INTO products (product_id, product_name, price) VALUES
(10, 'Laptop', 50000),
(11, 'Mouse', 800),
(12, 'Bag', 1200);

# Create table with orderss name :--
CREATE TABLE orderss (
  order_id INT PRIMARY KEY,
  customer_id INT,
  product_id INT,
  quantity INT
);

INSERT INTO orderss (order_id, customer_id, product_id, quantity) VALUES
(101, 1, 10, 1),
(102, 1, 12, 2),
(103, 2, 11, 3);

SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orderss;

# Find total revenue generated by each customer :--
# First join customer + orders
select c.customer_id , 
	c.name, o.order_id , o.product_id , o.quantity
from customers c 
JOIN orderss o 
	ON c.customer_id = o.customer_id;
    
# JOIN all three tables :--
select c.name ,
	o.order_id , o.quantity, 
    p.price , p.product_name
from customers c
JOIN orderss o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id;

# compute revenue and aggregate it by customer :--
SELECT c.customer_id , c.name,
	SUM(p.price * o.quantity) AS total_revenue
FROM customers c
JOIN orderss o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id= p.product_id
GROUP BY c.customer_id , c.name
ORDER BY total_revenue DESC;

# Find each customer's most expensive product :--
SELECT c.customer_id , c.name , o.product_id , p.price,
	sum(p.price * o.quantity) AS revenue
FROM customers c
JOIN orderss o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id;

# Most expensive product per customer. :--
SELECT c.customer_id , c.name , o.product_id , p.product_name,
	(p.price * o.quantity) AS total_revenue,
    row_number() over(partition by o.customer_id order by (p.price * o.quantity) DESC) AS rnk
FROM customers c
JOIN orderss o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id;

 # capture only those top orders (rn = 1) :--
 SELECT customer_id , name , product_name , COALESCE(revenue , 0) AS revenue
 FROM (
	SELECT c.customer_id , c.name , p.product_name,
	(p.price * o.quantity) AS revenue,
    row_number() over(partition by o.customer_id order by (p.price * o.quantity) DESC) AS rnk
	FROM customers c
	LEFT JOIN orderss o ON c.customer_id = o.customer_id
	LEFT JOIN products p ON o.product_id = p.product_id
    ) AS t
WHERE rnk = 1
order by customer_id;

# 2nd Method :--
WITH ranked_orders AS (
    SELECT
        c.customer_id,
        c.name,
        p.product_name,
        (p.price * o.quantity) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id
            ORDER BY (p.price * o.quantity) DESC
        ) AS rn
    FROM customers c
    LEFT JOIN orderss o ON c.customer_id = o.customer_id
    LEFT JOIN products p ON o.product_id = p.product_id
)
SELECT
    customer_id,
    name,
    product_name,
    COALESCE(revenue, 0) AS revenue
FROM ranked_orders
WHERE rn = 1
ORDER BY customer_id;

# Find the customer with the HIGHEST total number of orders :--
# NOTE -------- Always include all non-aggregated columns in the GROUP BY clause.-0  
SELECT customers.name, 
       orderss.customer_id,
       COUNT(*) AS order_count
FROM orderss
JOIN customers ON customers.customer_id = orderss.customer_id
GROUP BY customers.customer_id, customers.name
ORDER BY order_count DESC
LIMIT 1;

# Find the month with the highest revenue :--
SELECT 
    order_id,
    order_date,
    amount
FROM orders_date;

select * from orders_date; # :--

SELECT date_format(order_date , '%Y-%m') AS order_month,
	sum(amount) AS Revenue
FROM orders_date
group by order_month
order by Revenue DESC;

# Revenue per customer per month
SELECT c.customer_id , c.name , 
	date_format(d.order_date , '%Y-%m') AS order_month,
    SUM(d.amount) AS Revenue
FROM customers c
LEFT JOIN orders_date d ON c.customer_id = d.customer_id
group by c.customer_id , c.name, order_month
order by c.customer_id , order_month;

# Pivot it so months are columns (customer × month matrix) :--
# Note - always include all the non aggregated columns in the group by clause
SELECT c.customer_id , c.name , 
	COALESCE(SUM(CASE WHEN date_format(o.order_date , '%Y-%m') = '2023-01' THEN o.amount END),0) AS '2023-01',
    COALESCE(SUM(CASE WHEN date_format(o.order_date , '%Y-%m') = '2023-02' THEN o.amount END),0) AS '2023-02',
    COALESCE(SUM(CASE WHEN date_format(o.order_date , '%Y-%m') = '2023-03' THEN o.amount END),0) AS '2023-03'
FROM customers c
LEFT JOIN orders_date o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
order by c.customer_id;

# Export pivot table to CSV :--
CREATE OR REPLACE VIEW customer_month_revenue AS
SELECT c.customer_id , c.name , 
	COALESCE(SUM(CASE WHEN date_format(o.order_date , '%Y-%m') = '2023-01' THEN o.amount END),0) AS '2023-01',
    COALESCE(SUM(CASE WHEN date_format(o.order_date , '%Y-%m') = '2023-02' THEN o.amount END),0) AS '2023-02',
    COALESCE(SUM(CASE WHEN date_format(o.order_date , '%Y-%m') = '2023-03' THEN o.amount END),0) AS '2023-03'
FROM customers c
LEFT JOIN orders_date o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
order by c.customer_id;

# Export above date as .csv file :--
SELECT *
INTO OUTFILE 'C:/Users/akhil/Downloads/customer_month_revenue.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM customer_month_revenue;

# Windows Function 
SELECT customer_id , order_id , 
	amount, order_date,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rnk
FROM orders_date
WHERE rnk = 1;

# Extract ONLY the latest order per customer :--
SELECT customer_id , order_id, 
	amount , order_date , rnk
FROM ( SELECT customer_id , order_id , 
	amount, order_date,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rnk
    FROM orders_date
) AS temp_tb
WHERE rnk = 1
order by customer_id;
    
# computes cumulative revenue across all orders in chronological order :--
SELECT
  order_id,
  order_date,
  amount,
  SUM(amount) OVER (ORDER BY order_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_global
FROM orders_date
ORDER BY order_date;

# restarts the cumulative sum for each customer :--
SELECT
  customer_id,
  order_id,
  order_date,
  amount,
  SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_by_customer
FROM orders_date
ORDER BY customer_id, order_date;

# UNION and UNION ALL ------
# Create Table :--
CREATE TABLE sales_q1 (product VARCHAR(50));
INSERT INTO sales_q1 VALUES
('Laptop A'), ('Jacket A'), ('Mobile B');

CREATE TABLE sales_q2 (product VARCHAR(50));
INSERT INTO sales_q2 VALUES
('Jacket A'), ('Shirt B'), ('Laptop A');

select * from sales_q1;
select * from sales_q2;

# First UNION ALL (Duplicates in Row) :--
SELECT product FROM sales_q1
UNION ALL
SELECT product FROM sales_q2;

# UNION ( NO Duplicates in row) :--
SELECT product FROM sales_q1
UNION
SELECT product FROM sales_q2;

# Return a list of all products sold in any quarter, but also show
#  which quarter they belong to:--
SELECT product , 'Q1' FROM sales_q1
UNION ALL 
SELECT product , 'Q2' FROM sales_q2;

# Return all products sold in Q1 but NOT sold in Q2 :--
SELECT product
FROM sales_q1
WHERE product NOT IN (SELECT product FROM sales_q2);

# Return all products sold in BOTH Q1 AND Q2 :--
SELECT sales_q1.product FROM sales_q1
JOIN sales_q2 ON sales_q1.product = sales_q2.product; 
# OR 
SELECT product
FROM sales_q1
WHERE product IN (SELECT product FROM sales_q2);


# --------------------   SQL Performance Basics   ------------------#
# Index
# Creating Table :--
DROP TABLE IF EXISTS orders_perf;

CREATE TABLE orders_perf (
    order_id INT PRIMARY KEY,
    customer_id INT,
    amount INT,
    order_date DATE
);

INSERT INTO orders_perf VALUES
(1, 101, 500, '2023-01-05'),
(2, 101, 800, '2023-01-10'),
(3, 102, 300, '2023-02-02'),
(4, 103, 700, '2023-03-10'),
(5, 104, 900, '2023-03-15'),
(6, 105, 400, '2023-04-01');

EXPLAIN SELECT *
FROM orders_perf
WHERE order_date = '2023-03-10';

CREATE INDEX idx_order_date 
ON orders_perf(order_date);

EXPLAIN SELECT *
FROM orders_perf
WHERE order_date = '2023-03-10';

# SQL Performace - Explain + slow query diagnosis :--
EXPLAIN
SELECT *
FROM orders_perf o
JOIN customers c
      ON o.customer_id = c.customer_id;
      
# Create index on above table :--
CREATE INDEX idx_customer_id ON customers(customer_id);
CREATE INDEX idx_orders_perf_customer_id ON orders_perf(customer_id);


EXPLAIN
SELECT *
FROM orders_perf o
JOIN customers c
      ON o.customer_id = c.customer_id;

      
ANALYZE TABLE customers;
ANALYZE TABLE orders_perf;


# -----------------  Data Cleaning (TRIM , UPPER , SUBSTRING, REPLACE)  -------------------#
# TRIM --
# Create Table
CREATE TABLE dirty_names (
  name VARCHAR(100)
);

INSERT INTO dirty_names VALUES
('   John'),
('Sara   '),
('   Akhil   '),
('  Robert  ');
SELECT * FROM dirty_names;

# Trim() :--
SELECT name , TRIM(name) AS clean_name
FROM dirty_names;

# Trim with Upper :--
SELECT name , 
	UPPER(TRIM(name)),
    LOWER(TRIM(name))
FROM dirty_names;

# Replace() :--
SELECT name , 
	REPLACE(name, ' ', '') AS replace_name
FROM dirty_names;

# Substring() :--
SELECT name ,
	substring(name ,1, 3) AS substring_name
FROM dirty_names;

# add the trimmed column permanently :--
UPDATE dirty_names
SET name = TRIM(name);


ALTER TABLE dirty_names ADD COLUMN trimmed_name VARCHAR(255);
UPDATE dirty_names
SET trimmed_name = TRIM(name);

# REGEXP_REPLACE(expression(text/column) , pattern , repalcement) :--
SELECT name , 
	REGEXP_REPLACE(name , '[^A-Za-z]', '') AS new_name
FROM dirty_names;

# Remove Duplicates :--
CREATE TABLE sales_duplicates (
  id INT,
  product VARCHAR(50),
  amount INT
);

INSERT INTO sales_duplicates VALUES
(1, 'Laptop A', 500),
(1, 'Laptop A', 500),
(2, 'Mobile B', 700),
(2, 'Mobile B', 700),
(3, 'Shirt A', 300);

SELECT * FROM sales_duplicates;

SELECT *
FROM ( SELECT id , product , amount,
	ROW_NUMBER() OVER(PARTITION BY id , product , amount ORDER BY id) AS rnk
    FROM sales_duplicates
	) AS sub_query
WHERE rnk > 1;

# Create Backup of the table :--
CREATE TABLE backup_tb AS 
SELECT * FROM sales_duplicates;

# Use of DISTINCT to remove the duplicates row 
# because the DELETE work on Primary Key  :--
CREATE TABLE sales_unique AS 
SELECT DISTINCT id , product , amount 
FROM sales_duplicates;

SELECT COUNT(*) AS before_count FROM sales_duplicates;
SELECT COUNT(*) AS after_count FROM sales_unique;
SELECT * FROM sales_unique;

# Delete the table entire data but remain structure :--
TRUNCATE TABLE sales_duplicates;
# insert the data of table sales_unique into sales_duplicates
INSERT INTO sales_duplicates (id , product , amount)
SELECT id , product , amount FROM sales_unique;












