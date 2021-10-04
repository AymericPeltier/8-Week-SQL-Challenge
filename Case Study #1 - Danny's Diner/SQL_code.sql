-------------------------------------------------
-- Data with Danny - 8 Week Challenge (Week 1) --
-- https://8weeksqlchallenge.com/case-study-1/ --
-------------------------------------------------
-- Done with PostgreSQL
-- by Aymeric Peltier

-- **Schema (PostgreSQL v13)**
CREATE TABLE sales (
    "customer_id" VARCHAR(1),
    "order_date" DATE,
    "product_id" INTEGER
);
INSERT INTO sales ("customer_id", "order_date", "product_id")
VALUES ('A', '2021-01-01', '1'),
    ('A', '2021-01-01', '2'),
    ('A', '2021-01-07', '2'),
    ('A', '2021-01-10', '3'),
    ('A', '2021-01-11', '3'),
    ('A', '2021-01-11', '3'),
    ('B', '2021-01-01', '2'),
    ('B', '2021-01-02', '2'),
    ('B', '2021-01-04', '1'),
    ('B', '2021-01-11', '1'),
    ('B', '2021-01-16', '3'),
    ('B', '2021-02-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-07', '3');
CREATE TABLE menu (
    "product_id" INTEGER,
    "product_name" VARCHAR(5),
    "price" INTEGER
);
INSERT INTO menu ("product_id", "product_name", "price")
VALUES ('1', 'sushi', '10'),
    ('2', 'curry', '15'),
    ('3', 'ramen', '12');
CREATE TABLE members (
    "customer_id" VARCHAR(1),
    "join_date" DATE
);
INSERT INTO members ("customer_id", "join_date")
VALUES ('A', '2021-01-07'),
    ('B', '2021-01-09');
-- BONUS QUESTION 1; Join All The Things
SELECT S.customer_id,
    S.order_date,
    S.product_id,
    MU.product_name,
    MU.price,
    CASE
        WHEN (S.order_date >= MB.join_date) THEN 'Y'
        else 'N'
    END AS member
FROM sales AS S
    LEFT JOIN menu AS MU ON S.product_id = MU.product_id
    LEFT JOIN members as MB ON S.customer_id = MB.customer_id
ORDER BY customer_id,
    order_date;
-- BONUS QUESTION 2: Rank All The Things
WITH joined_table AS(
    SELECT S.customer_id,
        S.order_date,
        S.product_id,
        MU.product_name,
        MU.price,
        CASE
            WHEN (S.order_date >= MB.join_date) THEN 'Y'
            else 'N'
        END AS member
    FROM sales AS S
        LEFT JOIN menu AS MU ON S.product_id = MU.product_id
        LEFT JOIN members as MB ON S.customer_id = MB.customer_id
    ORDER BY customer_id,
        order_date
)
SELECT customer_id,
    order_date,
    product_id,
    product_name,
    price,
    member,
    CASE
        WHEN member = 'Y' THEN rank() OVER (
            PARTITION BY customer_id,
            member
            ORDER BY order_date
        )
        ELSE NULL
    END as ranking
FROM joined_table;
-- ----------------------------------------------------
-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id,
    SUM(price) as total_spent
FROM (
        SELECT S.customer_id,
            S.order_date,
            S.product_id,
            MU.product_name,
            MU.price,
            CASE
                WHEN (S.order_date >= MB.join_date) THEN 'Y'
                else 'N'
            END AS member
        FROM sales AS S
            LEFT JOIN menu AS MU ON S.product_id = MU.product_id
            LEFT JOIN members as MB ON S.customer_id = MB.customer_id
        ORDER BY customer_id,
            order_date
    ) as bonus_table
GROUP BY customer_id
ORDER BY customer_id;
-- ----------------------------------------------------
-- 2. How many days has each customer visited the restaurant?
SELECT customer_id,
    COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id;
-- ----------------------------------------------------
-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id,
    product_name
FROM (
        WITH table_name AS(
            SELECT S.customer_id,
                S.order_date,
                M.product_name
            FROM sales as S
                LEFT JOIN menu as M ON S.product_id = M.product_id
            ORDER BY order_date
        )
        SELECT customer_id,
            product_name,
            RANK() OVER (
                ORDER BY order_date
            ) as rank_order
        FROM table_name
    ) as rank_product
WHERE rank_order = 1
GROUP BY customer_id,
    product_name
ORDER BY customer_id;
-- ----------------------------------------------------
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT S.product_id,
    M.product_name,
    COUNT(S.product_id) as total_order
FROM sales S
    LEFT JOIN menu M ON S.product_id = M.product_id
GROUP BY S.product_id,
    M.product_name
ORDER BY total_order DESC
LIMIT 1;
-- ------------------------------------------------------
-- 5. Which item was the most popular for each customer?
SELECT customer_id,
    string_agg(CAST(product_id AS CHAR), ', ') AS favorite_product
FROM (
        SELECT customer_id,
            product_id,
            product_name,
            total_order,
            rank
        FROM (
                WITH table_name AS (
                    SELECT S.customer_id,
                        S.product_id,
                        M.product_name,
                        COUNT(S.product_id) as total_order
                    FROM sales S
                        LEFT JOIN menu M ON S.product_id = M.product_id
                    GROUP BY S.customer_id,
                        S.product_id,
                        M.product_name
                )
                SELECT customer_id,
                    product_id,
                    product_name,
                    total_order,
                    RANK() OVER (
                        PARTITION BY customer_id
                        ORDER BY total_order DESC
                    ) as Rank
                FROM table_name
            ) as rank_order
        WHERE rank = 1
    ) as ranking_table
GROUP BY customer_id;
-- ----------------------------------------------------
-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id,
    product_id,
    product_name,
    order_date
FROM (
        WITH joined_table AS(
            SELECT S.customer_id,
                S.order_date,
                S.product_id,
                MU.product_name,
                MU.price,
                CASE
                    WHEN (S.order_date >= MB.join_date) THEN 'Y'
                    else 'N'
                END AS member
            FROM sales AS S
                LEFT JOIN menu AS MU ON S.product_id = MU.product_id
                LEFT JOIN members as MB ON S.customer_id = MB.customer_id
            ORDER BY customer_id,
                order_date
        )
        SELECT customer_id,
            order_date,
            product_id,
            product_name,
            price,
            member,
            CASE
                WHEN member = 'Y' THEN rank() OVER (
                    PARTITION BY customer_id,
                    member
                    ORDER BY order_date
                )
                ELSE NULL
            END as ranking
        FROM joined_table
    ) as ranking_table
WHERE ranking = 1;
-- ----------------------------------------------------
-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id,
    string_agg(product_name, ', ') AS favorite_product
FROM(
        SELECT customer_id,
            join_date,
            order_date,
            product_id,
            product_name,
            price
        FROM (
                WITH joined_table AS(
                    SELECT S.customer_id,
                        S.order_date,
                        S.product_id,
                        MU.product_name,
                        MU.price,
                        MB.join_date,
                        CASE
                            WHEN (S.order_date >= MB.join_date) THEN 'Y'
                            else 'N'
                        END AS member
                    FROM sales AS S
                        LEFT JOIN menu AS MU ON S.product_id = MU.product_id
                        LEFT JOIN members as MB ON S.customer_id = MB.customer_id
                    ORDER BY customer_id,
                        order_date
                )
                SELECT customer_id,
                    join_date,
                    order_date,
                    product_id,
                    product_name,
                    price,
                    member,
                    CASE
                        WHEN member = 'Y' THEN rank() OVER (
                            PARTITION BY customer_id,
                            member
                            ORDER BY order_date
                        )
                        ELSE NULL
                    END as ranking,
                    CASE
                        WHEN member = 'N' THEN rank() OVER (
                            PARTITION BY customer_id,
                            member
                            ORDER BY order_date DESC
                        )
                        ELSE NULL
                    END as inverse_ranking
                FROM joined_table
            ) as ranking_table
        WHERE join_date IS NOT NULL
            AND inverse_ranking = 1
    ) as ranking_table
GROUP BY customer_id;
-- ----------------------------------------------------
-- 8) What is the total items and amount spent for each member before they became a member?
SELECT customer_id,
    COUNT(order_date) as items,
    SUM(price) as price_paid
FROM (
        WITH joined_table AS(
            SELECT S.customer_id,
                S.order_date,
                S.product_id,
                MU.product_name,
                MU.price,
                MB.join_date,
                CASE
                    WHEN (S.order_date >= MB.join_date) THEN 'Y'
                    else 'N'
                END AS member
            FROM sales AS S
                LEFT JOIN menu AS MU ON S.product_id = MU.product_id
                LEFT JOIN members as MB ON S.customer_id = MB.customer_id
            ORDER BY customer_id,
                order_date
        )
        SELECT customer_id,
            join_date,
            order_date,
            product_id,
            product_name,
            price,
            member,
            CASE
                WHEN member = 'Y' THEN rank() OVER (
                    PARTITION BY customer_id,
                    member
                    ORDER BY order_date
                )
                ELSE NULL
            END as ranking,
            CASE
                WHEN member = 'N' THEN rank() OVER (
                    PARTITION BY customer_id,
                    member
                    ORDER BY order_date DESC
                )
                ELSE NULL
            END as inverse_ranking
        FROM joined_table
    ) as ranking_table
WHERE join_date IS NOT NULL
    AND member = 'N'
GROUP BY customer_id;
-- ----------------------------------------------------
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,
    SUM(
        CASE
            WHEN product_name = 'sushi' THEN price * 20
            ELSE price * 10
        END
    ) as customer_points
FROM (
        WITH joined_table AS(
            SELECT S.customer_id,
                S.order_date,
                S.product_id,
                MU.product_name,
                MU.price,
                CASE
                    WHEN (S.order_date >= MB.join_date) THEN 'Y'
                    else 'N'
                END AS member
            FROM sales AS S
                LEFT JOIN menu AS MU ON S.product_id = MU.product_id
                LEFT JOIN members as MB ON S.customer_id = MB.customer_id
            ORDER BY customer_id,
                order_date
        )
        SELECT customer_id,
            order_date,
            product_id,
            product_name,
            price,
            member,
            CASE
                WHEN member = 'Y' THEN rank() OVER (
                    PARTITION BY customer_id,
                    member
                    ORDER BY order_date
                )
                ELSE NULL
            END as ranking
        FROM joined_table
    ) as ranking_table
WHERE member = 'Y'
GROUP BY customer_id
ORDER BY customer_id;
-- ----------------------------------------------------
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id,
    SUM(
        CASE
            WHEN first_week = 'Y' THEN price * 20
            ELSE CASE
                WHEN product_name = 'sushi' THEN price * 20
                ELSE price * 10
            END
        END
    ) AS customer_points
FROM (
        WITH joined_table AS(
            SELECT S.customer_id,
                MB.join_date,
                S.order_date,
                S.product_id,
                MU.product_name,
                MU.price,
                CASE
                    WHEN (S.order_date >= MB.join_date) THEN 'Y'
                    else 'N'
                END AS member,
                CASE
                    WHEN (S.order_date - MB.join_date) BETWEEN 0 and 6 THEN 'Y'
                    else 'N'
                END AS first_week
            FROM sales AS S
                LEFT JOIN menu AS MU ON S.product_id = MU.product_id
                LEFT JOIN members as MB ON S.customer_id = MB.customer_id
            ORDER BY customer_id,
                order_date
        )
        SELECT customer_id,
            join_date,
            order_date,
            product_id,
            product_name,
            price,
            member,
            first_week,
            CASE
                WHEN member = 'Y' THEN rank() OVER (
                    PARTITION BY customer_id,
                    member
                    ORDER BY order_date
                )
                ELSE NULL
            END as ranking
        FROM joined_table
    ) as ranking_table
WHERE member = 'Y'
GROUP BY customer_id
ORDER BY customer_id;
