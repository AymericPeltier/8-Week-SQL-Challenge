# 8 Week SQL Challenge

Thanks @DataWithDanny for the excellent SQL case studies! 👋🏻
* Find his challenge website on **[#8WeekSQLChallenge](https://8weeksqlchallenge.com)**
* Furthermore, I would recommend his course for anyone looking to get advanced SQL skills **[Serious-SQL](https://www.datawithdanny.com/courses/serious-sql)**

## 📕 Table of Contents
- [Case Study #1: Danny's Diner](#case-study-1-dannys-diner)
- [Case Study #2: Pizza Runner](#case-study-2-pizza-runner)

## Case Study #1: Danny's Diner 
<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Image" width="450" height="450">

[Link to case study](https://8weeksqlchallenge.com/case-study-1/)

### Business Problem:
Danny just started a japonese food business. He wants to leverage the data that he collected by creating some Dataset and answer a few questions regarding his customer, their habits and whether to expand the customer loyalty program or not.

### Entity Relationship Diagram:

![Entity diagram](/images/ER_case_1.png?raw=true "ER case 1")

### Case Study Questions:
<details>
<summary>
Click here to expand!
</summary>

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
10. What is the total items and amount spent for each member before they became a member?
11. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
12. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

 + some bonus questions!
</details>



## Case Study #2: Pizza Runner 
<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" alt="Image" width="450" height="450">

[Link to case study](https://8weeksqlchallenge.com/case-study-2/)

### Business Problem:
Danny decided to expand his Pizza business and Uberize it. Thus, he launches "Pizza Runner": he recruited runners to deliver pizza from his Headquarters and is developping an app.

He has many questions to be answered related to different general topic:
* Pizza Metrics
* Runner and Customer Experience
* Ingredient Optimisation
* Pricing and Ratings

### Entity Relationship Diagram:

![Entity diagram](/images/ER_case_2.png?raw=true "ER case 2")

### Case Study Questions:
<details>
<summary>
Click here to expand!
</summary>

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

</details>
  
#### B. Runner and Customer Experience

<details>
<summary>
Click here to expand!
</summary>

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?

</details>
  
#### C. Ingredient Optimisation

<details>
<summary>
Click here to expand!
</summary>

1. What are the standard ingredients for each pizza?
2. What was the most commonly added extra?
3. What was the most common exclusion?
4. Generate an order item for each record in the customers_orders table in the format of one of the following:
  - Meat Lovers
  - Meat Lovers - Exclude Beef
  - Meat Lovers - Extra Bacon
  - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
6. For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
7. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
  
</details>

#### D. Pricing and Ratings

<details>
<summary>
Click here to expand!
</summary>

1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
2. What if there was an additional $1 charge for any pizza extras?
  - Add cheese is $1 extra
3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
  - customer_id
  - order_id
  - runner_id
  - rating
  - order_time
  - pickup_time
  - Time between order and pickup
  - Delivery duration
  - Average speed
  - Total number of pizzas
5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

</details>

#### E. Bonus Questions

<details>
<summary>
Click here to expand!
</summary>

If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

</details>
