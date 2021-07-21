-- Data with Danny - 8 Week Challenge (Week 2)
-- https://8weeksqlchallenge.com/case-study-2/

-- Done with PostgreSQL

PART 4: Pricing and Ratings!


--Questions:
-- 1) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner
--    made so far if there are no delivery fees?
-- 2) What if there was an additional $1 charge for any pizza extras?
-- - Add cheese is $1 extra
-- 3) What if substitutes were allowed at no additional cost but any additional extras were charged at $1?
-- - Exclude Cheese and add Bacon is free
-- - Exclude Cheese but add bacon and beef costs $1 extra
-- 4) What if meat substitutes and vegetable substitutes were allowed but any change outside were charged at $2 and $1 respectively?
-- - Exclude Cheese and add Bacon is $2 extra
-- - Exclude Beef and add mushroom is $1 extra
-- - Exclude Beef and add Bacon is free
-- - Exclude Beef and Mushroom, and add Bacon and Cheese is free
-- 5)The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--   how would you design an additional table for this new dataset - generate a schema for this new table and insert 
--   your own data for ratings for each successful customer order between 1 to 5.
-- 6)Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- - customer_id
-- - order_id
-- - runner_id
-- - rating
-- - order_time
-- - pickup_time
-- - Time between order and pickup
-- - Delivery duration
-- - Average speed
-- - Total number of pizzas
-- 7) If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre
--    traveled - how much money does Pizza Runner have left over after these deliveries?
-- 8) If 1 unit of each ingredient costs $0.50 - how much net revenue will Pizza Runner make if the costs from question 30 are used?


--------------------------------------------------------------------------------------------------------------------------------------------------------

--Previous tables which we will still use for this part:


DROP TABLE IF EXISTS customer_orders_cleaned;
CREATE TEMP TABLE customer_orders_cleaned AS WITH first_layer AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE
      WHEN exclusions = '' THEN NULL
      WHEN exclusions = 'null' THEN NULL
      ELSE exclusions
    END as exclusions,
    CASE
      WHEN extras = '' THEN NULL
      WHEN extras = 'null' THEN NULL
      ELSE extras
    END as extras,
    order_time
  FROM
    customer_orders
)
SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      order_id,
      pizza_id
  ) AS row_number_order,
  order_id,
  customer_id,
  pizza_id,
  exclusions,
  extras,
  order_time
FROM
  first_layer;

---


DROP TABLE IF EXISTS runner_orders_cleaned;
CREATE TEMP TABLE runner_orders_cleaned AS WITH first_layer AS (
  SELECT
    order_id,
    runner_id,
    CAST(
      CASE
        WHEN pickup_time = 'null' THEN NULL
        ELSE pickup_time
      END AS timestamp
    ) AS pickup_time,
    CASE
      WHEN distance = '' THEN NULL
      WHEN distance = 'null' THEN NULL
      ELSE distance
    END as distance,
    CASE
      WHEN duration = '' THEN NULL
      WHEN duration = 'null' THEN NULL
      ELSE duration
    END as duration,
    CASE
      WHEN cancellation = '' THEN NULL
      WHEN cancellation = 'null' THEN NULL
      ELSE cancellation
    END as cancellation
  FROM
    runner_orders
)
SELECT
  order_id,
  runner_id,
  CASE
    WHEN order_id = '3' THEN (pickup_time + INTERVAL '13 hour')
    ELSE pickup_time
  END AS pickup_time,
  CAST(
    regexp_replace(distance, '[a-z]+', '') AS DECIMAL(5, 2)
  ) AS distance,
  CAST(regexp_replace(duration, '[a-z]+', '') AS INT) AS duration,
  cancellation
FROM
  first_layer;


------------------------------------------------------
-- 1) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner
--    made so far if there are no delivery fees?


--Let's create a temp table to make this more organized and get used to the syntax. I do not append those information to existing tables as it would require discussion
-- with the person managing the database (in a real situation). I'll use another method.


DROP TABLE IF EXISTS pizza_prices;
CREATE TEMP TABLE pizza_prices (
  "pizza_id" INTEGER,
  "price" INTEGER
);
INSERT INTO
  pizza_prices ("pizza_id", "price")
VALUES
  (1, 12),
  (2, 10);

---

WITH profit_table AS (
  SELECT
    C.pizza_id,
    COUNT(C.pizza_id) * price as pizza_revenues
  FROM
    customer_orders_cleaned AS C
    LEFT JOIN runner_orders_cleaned AS R ON C.order_id = R.order_id
    LEFT JOIN pizza_prices AS P ON C.pizza_id = P.pizza_id
  WHERE
    R.cancellation IS NULL
  GROUP BY
    C.pizza_id,
    price
)
SELECT
  SUM(pizza_revenues) AS total_revenue
FROM
  profit_table;

| total_revenue |
| ------------- |
| 138           |



------------------------------------------------------
-- 2) What if there was an additional $1 charge for any pizza extras?
-- - Add cheese is $1 extra

-- let's recycle last part queries:

DROP TABLE IF EXISTS orders_extras;
CREATE TEMP TABLE orders_extras AS
SELECT
  row_number_order,
  order_id,
  customer_id,
  customer_orders_cleaned.pizza_id,
  pizza_name,
  CAST(
    UNNEST(string_to_array(COALESCE(extras, '0'), ',')) AS INT
  ) AS extras
FROM
  customer_orders_cleaned
  JOIN pizza_names ON customer_orders_cleaned.pizza_id = pizza_names.pizza_id
ORDER BY
  order_id;


WITH segmented_revenues AS (
  SELECT
    table1.pizza_id,
    table1.pizza_revenues,
    table2.extras_revenues,
    (table1.pizza_revenues + table2.extras_revenues) AS total_revenues
  FROM
    (
      SELECT
        C.pizza_id,
        COUNT(C.pizza_id) * price as pizza_revenues
      FROM
        customer_orders_cleaned AS C
        LEFT JOIN runner_orders_cleaned AS R ON C.order_id = R.order_id
        LEFT JOIN pizza_prices AS P ON C.pizza_id = P.pizza_id
      WHERE
        R.cancellation IS NULL
      GROUP BY
        C.pizza_id,
        price
    ) AS table1
    LEFT JOIN (
      SELECT
        t1.pizza_id,
        SUM(
          CASE
            WHEN t1.extras > 0 THEN 1
            ELSE 0
          END
        ) AS extras_revenues
      FROM
        orders_extras t1
        LEFT JOIN pizza_prices t2 ON t1.pizza_id = t2.pizza_id
        LEFT JOIN runner_orders_cleaned t3 ON t1.order_id = t3.order_id
      WHERE
        t3.cancellation IS NULL
      GROUP BY
        t1.pizza_id
    ) AS table2 ON table1.pizza_id = table2.pizza_id
)
SELECT
  SUM(total_revenues) AS total_revenues
FROM
  segmented_revenues;

| total_revenues |
| -------------- |
| 142            |




------------------------------------------------------
-- 3) What if substitutes were allowed at no additional cost but any additional extras were charged at $1?
-- - Exclude Cheese and add Bacon is free
-- - Exclude Cheese but add bacon and beef costs $1 extra


-- Step 1: create an unstacked table with the extras and exceptions 
DROP TABLE IF EXISTS exclusions_extras_unstacked;
CREATE TEMP TABLE exclusions_extras_unstacked AS
SELECT
  row_number_order,
  order_id,
  customer_id,
  customer_orders_cleaned.pizza_id,
  pizza_name,
  CAST(
    UNNEST(string_to_array(COALESCE(exclusions, '0'), ',')) AS INT
  ) AS exclusions,
  CAST(
    UNNEST(string_to_array(COALESCE(extras, '0'), ',')) AS INT
  ) AS extras
FROM
  customer_orders_cleaned
  JOIN pizza_names ON customer_orders_cleaned.pizza_id = pizza_names.pizza_id
ORDER BY
  order_id;

--Step 2: create a balance to see if we had more extras than exclusions
WITH order_layer AS (
  SELECT
    row_number_order,
    order_id,
    pizza_id,
    SUM(
      CASE
        WHEN extras > 0 THEN 1
        ELSE 0
      END
    ) - SUM(
      CASE
        WHEN exclusions > 0 THEN 1
        ELSE 0
      END
    ) AS substitutes_cost
  FROM
    exclusions_extras_unstacked
  GROUP BY
    row_number_order,
    order_id,
    pizza_id
),
pizza_layer AS(
  SELECT
    row_number_order,
    order_id,
    pizza_id,
    CASE
      WHEN substitutes_cost < 0 THEN 0
      ELSE substitutes_cost
    END AS substitutes_cost
  FROM
    order_layer
)
SELECT
  pizza_id,
  SUM(substitutes_cost) AS substitutes_cost
FROM
  pizza_layer
GROUP BY
  pizza_id;

| pizza_id | substitutes_cost |
| -------- | ---------------- |
| 2        | 1                |
| 1        | 2                |

--Step 3: Change the LEFT JOIN in our last question query with the one created in step 2.
WITH segmented_revenues AS (
  SELECT
    table1.pizza_id,
    table1.pizza_revenues,
    table2.substitutes_cost,
    (table1.pizza_revenues + table2.substitutes_cost) AS total_revenues
  FROM
    (
      SELECT
        C.pizza_id,
        COUNT(C.pizza_id) * price as pizza_revenues
      FROM
        customer_orders_cleaned AS C
        LEFT JOIN runner_orders_cleaned AS R ON C.order_id = R.order_id
        LEFT JOIN pizza_prices AS P ON C.pizza_id = P.pizza_id
      WHERE
        R.cancellation IS NULL
      GROUP BY
        C.pizza_id,
        price
    ) AS table1
    LEFT JOIN (
      WITH order_layer AS (
        SELECT
          row_number_order,
          order_id,
          pizza_id,
          SUM(
            CASE
              WHEN extras > 0 THEN 1
              ELSE 0
            END
          ) - SUM(
            CASE
              WHEN exclusions > 0 THEN 1
              ELSE 0
            END
          ) AS substitutes_cost
        FROM
          exclusions_extras_unstacked
        GROUP BY
          row_number_order,
          order_id,
          pizza_id
      ),
      pizza_layer AS(
        SELECT
          row_number_order,
          order_id,
          pizza_id,
          CASE
            WHEN substitutes_cost < 0 THEN 0
            ELSE substitutes_cost
          END AS substitutes_cost
        FROM
          order_layer
      )
      SELECT
        pizza_id,
        SUM(substitutes_cost) AS substitutes_cost
      FROM
        pizza_layer
      GROUP BY
        pizza_id
    ) AS table2 ON table1.pizza_id = table2.pizza_id
)
SELECT
  SUM(total_revenues) AS total_revenues
FROM
  segmented_revenues;

| total_revenues |
| -------------- |
| 141            |



------------------------------------------------------
-- 4) What if meat substitutes and vegetable substitutes were allowed but any change outside were charged at $2 and $1 respectively?
-- - Exclude Cheese and add Bacon is $2 extra
-- - Exclude Beef and add mushroom is $1 extra
-- - Exclude Beef and add Bacon is free
-- - Exclude Beef and Mushroom, and add Bacon and Cheese is free

-- Table 2: Just as before, we will not modify existing tables.

DROP TABLE IF EXISTS modification_prices;
CREATE TEMP TABLE modification_prices (
  "topping_id" INTEGER,
  "topping_name" TEXT,
  "type" INTEGER,
  "type_name" TEXT,
  "modification_price" INTEGER
);
INSERT INTO
  modification_prices (
    "topping_id",
    "topping_name",
    "type",
    "type_name",
    "modification_price"
  )
VALUES
  ('1', 'Bacon', '1', 'Vegetable', '2'),
  ('2', 'BBQ Sauce', '0', 'Sauce', '0'),
  ('3', 'Beef', '1', 'Meat', '2'),
  ('4', 'Cheese', '2', 'Vegetable', '1'),
  ('5', 'Chicken', '1', 'Meat', '2'),
  ('6', 'Mushrooms', '2', 'Vegetable', '1'),
  ('7', 'Onions', '2', 'Vegetable', '1'),
  ('8', 'Pepperoni', '1', 'Meat', '2'),
  ('9', 'Peppers', '2', 'Vegetable', '1'),
  ('10', 'Salami', '1', 'Meat', '2'),
  ('11', 'Tomatoes', '2', 'Vegetable', '1'),
  ('12', 'Tomato Sauce', '0', 'Sauce', '0');


--Step 2: compute the fees using the table previously created
WITH unstacking AS(
  SELECT
    t1.row_number_order,
    t1.order_id,
    t1.pizza_id,
    t1.exclusions,
    t1.extras,
    t2.type AS exclusion_type,
    t3.type AS extras_type,
    t3.modification_price AS extras_price
  FROM
    exclusions_extras_unstacked t1
    LEFT JOIN modification_prices t2 ON t1.exclusions = t2.topping_id
    LEFT JOIN modification_prices t3 ON t1.extras = t3.topping_id
  ORDER BY
    order_id
),
condition_type AS(
  SELECT
    row_number_order,
    order_id,
    pizza_id,
    extras_price,
    CASE
      WHEN exclusion_type = 1 THEN 1
      ELSE 0
    END AS exclusion_type1,
    CASE
      WHEN exclusion_type = 2 THEN 1
      ELSE 0
    END AS exclusion_type2,
    CASE
      WHEN extras_type = 1 THEN 1
      ELSE 0
    END AS extras_type1,
    CASE
      WHEN extras_type = 2 THEN 1
      ELSE 0
    END AS extras_type2
  FROM
    unstacking
),
count_type AS(
  SELECT
    row_number_order,
    order_id,
    pizza_id,
    extras_price,
    SUM(exclusion_type1) AS exclusion_type1,
    SUM(exclusion_type2) AS exclusion_type2,
    SUM(extras_type1) AS extras_type1,
    SUM(extras_type2) AS extras_type2
  FROM
    condition_type
  GROUP BY
    row_number_order,
    order_id,
    pizza_id,
    extras_price
  ORDER BY
    row_number_order
),
fees_type AS(
  SELECT
    row_number_order,
    order_id,
    pizza_id,
    CASE
      WHEN (extras_type1 - exclusion_type1) * extras_price < 0 THEN 0
      ELSE (extras_type1 - exclusion_type1) * extras_price
    END AS fees_type1,
    CASE
      WHEN (extras_type2 - exclusion_type2) * extras_price < 0 THEN 0
      ELSE (extras_type2 - exclusion_type2) * extras_price
    END AS fees_type2
  FROM
    count_type
)
SELECT
  pizza_id,
  SUM(fees_type1) + SUM(fees_type2) AS substitutes_cost
FROM
  fees_type
GROUP BY
  pizza_id;

| pizza_id | substitutes_cost |
| -------- | ---------------- |
| 2        | 2                |
| 1        | 8                |


--Step 3: Compute the total revenues with the previously used queries:
WITH segmented_revenues AS (
  SELECT
    table1.pizza_id,
    table1.pizza_revenues,
    table2.substitutes_cost,
    (table1.pizza_revenues + table2.substitutes_cost) AS total_revenues
  FROM
    (
      SELECT
        C.pizza_id,
        COUNT(C.pizza_id) * price as pizza_revenues
      FROM
        customer_orders_cleaned AS C
        LEFT JOIN runner_orders_cleaned AS R ON C.order_id = R.order_id
        LEFT JOIN pizza_prices AS P ON C.pizza_id = P.pizza_id
      WHERE
        R.cancellation IS NULL
      GROUP BY
        C.pizza_id,
        price
    ) AS table1
    LEFT JOIN (
      WITH unstacking AS(
        SELECT
          t1.row_number_order,
          t1.order_id,
          t1.pizza_id,
          t1.exclusions,
          t1.extras,
          t2.type AS exclusion_type,
          t3.type AS extras_type,
          t3.modification_price AS extras_price
        FROM
          exclusions_extras_unstacked t1
          LEFT JOIN modification_prices t2 ON t1.exclusions = t2.topping_id
          LEFT JOIN modification_prices t3 ON t1.extras = t3.topping_id
        ORDER BY
          order_id
      ),
      condition_type AS(
        SELECT
          row_number_order,
          order_id,
          pizza_id,
          extras_price,
          CASE
            WHEN exclusion_type = 1 THEN 1
            ELSE 0
          END AS exclusion_type1,
          CASE
            WHEN exclusion_type = 2 THEN 1
            ELSE 0
          END AS exclusion_type2,
          CASE
            WHEN extras_type = 1 THEN 1
            ELSE 0
          END AS extras_type1,
          CASE
            WHEN extras_type = 2 THEN 1
            ELSE 0
          END AS extras_type2
        FROM
          unstacking
      ),
      count_type AS(
        SELECT
          row_number_order,
          order_id,
          pizza_id,
          extras_price,
          SUM(exclusion_type1) AS exclusion_type1,
          SUM(exclusion_type2) AS exclusion_type2,
          SUM(extras_type1) AS extras_type1,
          SUM(extras_type2) AS extras_type2
        FROM
          condition_type
        GROUP BY
          row_number_order,
          order_id,
          pizza_id,
          extras_price
        ORDER BY
          row_number_order
      ),
      fees_type AS(
        SELECT
          row_number_order,
          order_id,
          pizza_id,
          CASE
            WHEN (extras_type1 - exclusion_type1) * extras_price < 0 THEN 0
            ELSE (extras_type1 - exclusion_type1) * extras_price
          END AS fees_type1,
          CASE
            WHEN (extras_type2 - exclusion_type2) * extras_price < 0 THEN 0
            ELSE (extras_type2 - exclusion_type2) * extras_price
          END AS fees_type2
        FROM
          count_type
      )
      SELECT
        pizza_id,
        SUM(fees_type1) + SUM(fees_type2) AS substitutes_cost
      FROM
        fees_type
      GROUP BY
        pizza_id
    ) AS table2 ON table1.pizza_id = table2.pizza_id
)
SELECT
  SUM(total_revenues) AS total_revenues
FROM
  segmented_revenues;

| total_revenues |
| -------------- |
| 148            |



------------------------------------------------------
-- 5)The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--   how would you design an additional table for this new dataset - generate a schema for this new table and insert 
--   your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  "order_id" INTEGER,
  "rating" INTEGER CONSTRAINT check1to5_rating CHECK (
    "rating" between 1
    and 5
  ),
  "comment" VARCHAR(150)
);
INSERT INTO
  runner_ratings ("order_id", "rating", "comment")
VALUES
  ('1', '2', 'Tasty'),
  ('2', '4', ''),
  ('3', '4', ''),
  ('4', '5', 'The pizza arrived cold, really bad service'),
  ('5', '2', ''),
  ('6', NULL, ''),
  ('7', '5', ''),
  ('8', '4', 'Great service'),
  ('9', NULL, ''),
  ('10', '1', 'The pizza arrived upside down, really disappointed');
  
SELECT
  *
FROM
  runner_ratings;

| order_id | rating | comment                                            |
| -------- | ------ | -------------------------------------------------- |
| 1        | 2      | Tasty                                              |
| 2        | 4      |                                                    |
| 3        | 4      |                                                    |
| 4        | 5      | The pizza arrived cold, really bad service         |
| 5        | 2      |                                                    |
| 6        |        |                                                    |
| 7        | 5      |                                                    |
| 8        | 4      | Great service                                      |
| 9        |        |                                                    |
| 10       | 1      | The pizza arrived upside down, really disappointed |


------------------------------------------------------
-- 6)Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- - customer_id
-- - order_id
-- - runner_id
-- - rating
-- - order_time
-- - pickup_time
-- - Time between order and pickup
-- - Delivery duration
-- - Average speed
-- - Total number of pizzas

DROP TABLE IF EXISTS Global_table;
CREATE TEMP TABLE Global_table AS WITH runner_layer1 AS (
  SELECT
    order_id,
    runner_id,
    CAST(
      CASE
        WHEN pickup_time = 'null' THEN NULL
        ELSE pickup_time
      END AS timestamp
    ) AS pickup_time,
    CASE
      WHEN distance = '' THEN NULL
      WHEN distance = 'null' THEN NULL
      ELSE distance
    END as distance,
    CASE
      WHEN duration = '' THEN NULL
      WHEN duration = 'null' THEN NULL
      ELSE duration
    END as duration,
    CASE
      WHEN cancellation = '' THEN NULL
      WHEN cancellation = 'null' THEN NULL
      ELSE cancellation
    END as cancellation
  FROM
    runner_orders
),
runner_layer2 AS(
  SELECT
    order_id,
    runner_id,
    CASE
      WHEN order_id = '3' THEN (pickup_time + INTERVAL '13 hour')
      ELSE pickup_time
    END AS pickup_time,
    CAST(
      regexp_replace(distance, '[a-z]+', '') AS DECIMAL(5, 2)
    ) AS distance,
    CAST(regexp_replace(duration, '[a-z]+', '') AS INT) AS duration,
    cancellation
  FROM
    runner_layer1
)
SELECT
  t1.order_id,
  t2.customer_id,
  t1.runner_id,
  t3.rating,
  t2.order_time,
  t1.pickup_time,
  (
    DATE_PART('hour', t1.pickup_time - t2.order_time) * 60 + DATE_PART('minute', t1.pickup_time - t2.order_time)
  ) * 60 + DATE_PART('second', t1.pickup_time - t2.order_time) AS time_between_order_and_pickup,
  t1.distance,
  t1.duration,
  ROUND(
    (
      t1.distance :: NUMERIC /(t1.duration :: NUMERIC / 60)
    ),
    2
  ) AS average_speed,
  COUNT(t2.pizza_id) AS count_pizza
FROM
  runner_layer2 t1
  LEFT JOIN customer_orders t2 ON t1.order_id = t2.order_id
  LEFT JOIN runner_ratings t3 ON t1.order_id = t3.order_id
WHERE
  cancellation IS NULL
GROUP BY
  t1.order_id,
  t1.runner_id,
  t1.pickup_time,
  t1.distance,
  t1.duration,
  ROUND(
    (
      t1.distance :: NUMERIC /(t1.duration :: NUMERIC / 60)
    ),
    2
  ),
  t2.customer_id,
  t2.order_time,
  t3.rating;


------------------------------------------------------
-- 7) If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre
--    traveled - how much money does Pizza Runner have left over after these deliveries?

WITH pizza_revenues AS(
  SELECT
    t1.order_id,
    pizza_id,
    CASE
      WHEN pizza_id = 1 THEN COUNT(pizza_id) * 12
      ELSE COUNT(pizza_id) * 10
    END AS pizza_revenues
  FROM
    customer_orders_cleaned t1
    LEFT JOIN runner_orders_cleaned t2 ON t1.order_id = t2.order_id
  WHERE
    cancellation IS NULL
  GROUP BY
    t1.order_id,
    pizza_id
),
revenues_delivery AS(
  SELECT
    t1.order_id,
    t2.distance * 0.3 AS delivery_cost,
    SUM(t1.pizza_revenues) AS order_revenues
  FROM
    pizza_revenues t1
    LEFT JOIN Global_table t2 ON t1.order_id = t2.order_id
  GROUP BY
    t1.order_id,
    distance
)
SELECT
  ROUND(SUM(order_revenues) - SUM(delivery_COST), 2) AS revenues_afterdelivery
FROM
  revenues_delivery;

| revenues_afterdelivery |
| ---------------------- |
| 94.44                  |



------------------------------------------------------
-- 8) If 1 unit of each ingredient costs $0.50 - how much net revenue will Pizza Runner make if the costs from question 30 are used?

--Step 1: Let's go back to previous queries where we obtained how many times each ingredients were used (question 5 & 6 of part Ingredient Optimization)
-- Note that those lines are added to make the SQL works as I divided this assignment in multiple parts for readability !
DROP TABLE IF EXISTS classical_recipe;
CREATE TEMP TABLE classical_recipe AS WITH pizza_recipes_unstacked AS (
  SELECT
    pizza_id,
    CAST(
      UNNEST(
        string_to_array(toppings, ', ')
      ) AS INT
    ) AS topping_id
  FROM
    pizza_recipes
)
SELECT
  t4.row_number_order,
  t4.order_id,
  t4.customer_id,
  t1.pizza_id,
  t1.pizza_name,
  t2.topping_id,
  t3.topping_name
FROM
  pizza_names t1
  JOIN pizza_recipes_unstacked t2 ON t1.pizza_id = t2.pizza_id
  JOIN pizza_toppings t3 ON t2.topping_id = t3.topping_id
  RIGHT JOIN customer_orders_cleaned t4 ON t1.pizza_id = t4.pizza_id;


DROP TABLE IF EXISTS orders_exclusions;
CREATE TEMP TABLE orders_exclusions AS
SELECT
  row_number_order,
  order_id,
  customer_id,
  customer_orders_cleaned.pizza_id,
  pizza_name,
  CAST(
    UNNEST(string_to_array(COALESCE(exclusions, '0'), ',')) AS INT
  ) AS exclusions
FROM
  customer_orders_cleaned
  JOIN pizza_names ON customer_orders_cleaned.pizza_id = pizza_names.pizza_id
ORDER BY
  order_id;


DROP TABLE IF EXISTS orders_extras;
CREATE TEMP TABLE orders_extras AS
SELECT
  row_number_order,
  order_id,
  customer_id,
  customer_orders_cleaned.pizza_id,
  pizza_name,
  CAST(
    UNNEST(string_to_array(COALESCE(extras, '0'), ',')) AS INT
  ) AS extras
FROM
  customer_orders_cleaned
  JOIN pizza_names ON customer_orders_cleaned.pizza_id = pizza_names.pizza_id
ORDER BY
  order_id;

DROP TABLE IF EXISTS pizzas_details;
CREATE TEMP TABLE pizzas_details AS WITH first_layer AS (
  SELECT
    row_number_order,
    order_id,
    customer_id,
    pizza_id,
    pizza_name,
    topping_id
  FROM
    classical_recipe
  EXCEPT
  SELECT
    *
  FROM
    orders_exclusions
  UNION ALL
  SELECT
    *
  FROM
    orders_extras
  WHERE
    extras != 0
)
SELECT
  row_number_order,
  order_id,
  customer_id,
  pizza_id,
  pizza_name,
  first_layer.topping_id,
  topping_name
FROM
  first_layer
  LEFT JOIN pizza_toppings ON first_layer.topping_id = pizza_toppings.topping_id
ORDER BY
  row_number_order,
  order_id,
  pizza_id,
  topping_id;


--Step 2: Detail of the query to get the ingredients' cost per order_id

SELECT
  order_id,
  COUNT(topping_id) * 0.5 as ingredient_costs
FROM
  pizzas_details
GROUP BY
  order_id
ORDER BY
  order_id;

| order_id | ingredient_costs |
| -------- | ---------------- |
| 1        | 4.0              |
| 2        | 4.0              |
| 3        | 7.0              |
| 4        | 9.5              |
| 5        | 4.5              |
| 6        | 3.0              |
| 7        | 3.5              |
| 8        | 4.0              |
| 9        | 4.5              |
| 10       | 8.0              |


--Step 3: Now let's fill this in the query of the previous question:
WITH pizza_revenues AS(
  SELECT
    t1.order_id,
    pizza_id,
    CASE
      WHEN pizza_id = 1 THEN COUNT(pizza_id) * 12
      ELSE COUNT(pizza_id) * 10
    END AS pizza_revenues
  FROM
    customer_orders_cleaned t1
    LEFT JOIN runner_orders_cleaned t2 ON t1.order_id = t2.order_id
  WHERE
    cancellation IS NULL
  GROUP BY
    t1.order_id,
    pizza_id
),
revenues_delivery AS(
  SELECT
    t1.order_id,
    t2.distance * 0.3 AS delivery_cost,
    SUM(t1.pizza_revenues) AS order_revenues,
    t3.ingredient_costs
  FROM
    pizza_revenues t1
    LEFT JOIN Global_table t2 ON t1.order_id = t2.order_id
    LEFT JOIN (
      SELECT
        order_id,
        COUNT(topping_id) * 0.5 as ingredient_costs
      FROM
        pizzas_details
      GROUP BY
        order_id
    ) AS t3 ON t1.order_id = t3.order_id
  GROUP BY
    t1.order_id,
    distance,
    t3.ingredient_costs
)
SELECT
  ROUND(
    SUM(order_revenues) - SUM(delivery_COST) - SUM(ingredient_costs),
    2
  ) AS revenues_left
FROM
  revenues_delivery;

| revenues_left |
| ------------- |
| 49.94         |

---

[View on DB Fiddle](https://www.db-fiddle.com/f/7VcQKQwsS3CTkGRFG7vu98/4)
