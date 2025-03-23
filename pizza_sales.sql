-- SQL Basic Questions
-- 1. Retrieve the total number of orders placed.
-- To read Data
SELECT *FROM orders;

SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;
    
-- 2.  Calculated The total revenue generated from pizza sales
-- To read Data
SELECT *FROM pizzas;
SELECT *FROM orders_details;

SELECT 
    ROUND(SUM(orders_details.quantity * pizzas.price),
            2) AS total_sales
FROM
    orders_details
        JOIN
    pizzas ON pizzas.pizza_id = orders_details.pizza_id;
    
-- 3. Identify the heighest-priced pizza
SELECT * FROM pizza_types;
SELECT * FROM pizzas;

SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;

-- 4.  Identify the most common pizza size ordered.
SELECT quantity, count(order_details_id)
FROM orders_details group by quantity;

SELECT 
    pizzas.size,
    COUNT(orders_details.order_details_id) AS order_count
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC;

-- 5. List the top 5 most ordered pizza types along with their quantities.
-- Join 3 tables
SELECT 
    pizza_types.name, SUM(orders_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;

-- SQL Intermediate Questions
-- 1. Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pizza_types.category,
    SUM(orders_details.quantity) AS total_quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY total_quantity DESC;

-- 2. Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) AS hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(order_time)
ORDER BY hour;

-- 3. Join revelent tables to find the category wise distribution of pizzas.
SELECT 
    category, COUNT(pizza_type_id) AS Distribution
FROM
    pizza_types
GROUP BY category;

-- 4. Group the orders by date and calculate the average number of the pizzas ordered per day.
SELECT 
    ROUND(AVG(quantity), 0) As Avg_pizza_ordered_per_day
FROM
    (SELECT 
        orders.order_date, SUM(orders_details.quantity) AS quantity
    FROM
        orders
    JOIN orders_details ON orders.order_id = orders_details.order_id
    GROUP BY orders.order_date) AS order_quantity;
    
-- Note: 1. Round about 0 decimal because its in average value. 
-- 		 2. First create a sub queries to find out sum of quantity according to each date.

-- 5. Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_types.name,
    SUM(orders_details.quantity * pizzas.price) revenue
FROM
    orders_details
        JOIN
    pizzas ON orders_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;

-- SQL Advanced Questions
-- 1. Calculate the percentage contribution of each pizza type to total revenue.

-- 1st step to find a category and total sales/revenue
SELECT 
    pizza_types.category,
    SUM(pizzas.price * orders_details.quantity) AS total_sales
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.category
ORDER BY total_sales DESC;

-- Whole SQL query for percentage
SELECT 
    pizza_types.category,
    ROUND(SUM(pizzas.price * orders_details.quantity) / (SELECT 
                    ROUND(SUM(pizzas.price * orders_details.quantity),
                                2) AS total_sales
                FROM
                    pizzas
                        JOIN
                    orders_details ON pizzas.pizza_id = orders_details.pizza_id) * 100,
            2) AS total_sales
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.category
ORDER BY total_sales DESC;

-- 2. Analyze the cumulative revenue generated over time.
-- USE Subquery and Windows Function
SELECT 
order_date, SUM(total_revenue) OVER (ORDER BY order_date) AS cumul_revenue 
FROM
 (SELECT 
    orders.order_date,
    SUM(pizzas.price * orders_details.quantity) AS total_revenue
 FROM
    orders_details
        JOIN
    pizzas ON orders_details.pizza_id = pizzas.pizza_id
        JOIN
    orders ON orders.order_id = orders_details.order_id
 GROUP BY orders.order_date
 ORDER BY orders.order_date) AS sales;
 
 -- 3. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT 
	name, revenue , ranks
FROM
(SELECT 
	category, name , revenue,
	RANK() OVER (partition by category order by revenue desc) as ranks
FROM
(SELECT 
    pizza_types.category,
    pizza_types.name,
    ROUND(SUM(orders_details.quantity * pizzas.price),
            0) AS revenue
FROM
    orders_details
        JOIN
    pizzas ON orders_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category , pizza_types.name) as a) as b
where ranks <= 3;

-- 4. Monthly Revenue Trends – How does revenue fluctuate month by month?
-- Using Common Table Expressions (CTEs)
WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(orders.order_date, '%Y-%m') AS month,
        ROUND(SUM(pizzas.price * orders_details.quantity),2) AS total_revenue
    FROM orders
    JOIN orders_details ON orders.order_id = orders_details.order_id
    JOIN pizzas ON orders_details.pizza_id = pizzas.pizza_id
    GROUP BY month
)
SELECT month, total_revenue, 
       ROUND(SUM(total_revenue) OVER (ORDER BY month),2) AS cumulative_revenue
FROM MonthlySales;