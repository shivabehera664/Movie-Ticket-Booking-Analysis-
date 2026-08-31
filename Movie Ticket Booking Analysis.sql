USE movie_booking_db;

-- Q1. Find total revenue, total bookings, and total seats booked from CONFIRMED bookings only.

SELECT
    SUM(ticket_amount) AS total_revenue,
    COUNT(booking_id) AS total_bookings,
    SUM(seats_booked) AS total_seats_booked
FROM bookings
WHERE booking_status = 'CONFIRMED';

-- Q2. Show the count and % share of bookings for each booking_status (Confirmed / Pending / Cancelled) sorted by count descending.

SELECT
    booking_status,
    COUNT(*) AS booking_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_share
FROM bookings
GROUP BY booking_status
ORDER BY booking_count DESC;

-- Q3. Rank payment methods by total confirmed revenue generated.

SELECT
    payment_method,
    SUM(ticket_amount) AS total_confirmed_revenue,
    RANK() OVER (
        ORDER BY SUM(ticket_amount) DESC
    ) AS revenue_rank
FROM bookings
WHERE booking_status = 'Confirmed'
GROUP BY payment_method
ORDER BY revenue_rank desc;

-- Q4. For each theatre city, find total confirmed bookings and total revenue Sort by revenue descending.

SELECT
    t.city ,
    COUNT(b.booking_id) AS total_confirmed_bookings,
    SUM(b.ticket_amount) AS total_confirmed_revenue
FROM bookings b
JOIN theatres t
ON b.theatre_id = t.theatre_id
WHERE booking_status = 'Confirmed'
GROUP BY t.city
ORDER BY total_confirmed_revenue DESC;

-- Q5. Find the top 5 movie genres by number of confirmed bookings and total seats sold.

SELECT 
	m.genre,
    count(b.booking_status)AS confirmed_bookings,
    sum(b.seats_booked) AS total_seats_sold
FROM bookings b
JOIN movies m
ON b.movie_id = m.movie_id 
WHERE  b.booking_status = 'confirmed'
GROUP BY m.genre 
ORDER BY  total_seats_sold DESC 
 LIMIT 5;
 
 -- Q6. For each movie language, find the number of distinct movies distinct theatres that screened them and total revenue.

SELECT 
      language,
      count( DISTINCT m.movie_name) AS total_movies ,
      count( DISTINCT t.theatre_name) AS total_theatre ,
      sum(b.ticket_amount) AS total_revenue 
FROM bookings b
JOIN movies m
ON b.movie_id = m.movie_id
JOIN theatres t
ON b.theatre_id = t.theatre_id 
GROUP BY m.language 
ORDER BY total_revenue DESC;

-- Q7. List the top 10 customers by total confirmed spend along with their city and number of bookings.

SELECT 
    c.customer_name,
    c.city,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.ticket_amount) AS total_confirmed_spend
FROM bookings b
JOIN customers c
    ON b.customer_id = c.customer_id
WHERE b.booking_status = 'Confirmed'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_confirmed_spend DESC
LIMIT 10;

-- Q8. Classify each customer as 'One-time' or 'Repeat' based on whether they have more than 1 confirmed booking, then find total revenue contributed by each group.

SELECT
    CASE
        WHEN confirmed_bookings = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,
    SUM(total_revenue) AS total_revenue
FROM (
    SELECT
        customer_id,
        COUNT(booking_id) AS confirmed_bookings,
        SUM(ticket_amount) AS total_revenue
    FROM bookings
    WHERE booking_status = 'Confirmed'
    GROUP BY customer_id
) AS customer_summary
GROUP BY
    CASE
        WHEN confirmed_bookings = 1 THEN 'One-time'
        ELSE 'Repeat'
    END;
 
-- Q9. For each theatre, calculate the average seats booked per show and express it as a percentage of total_seats ("avg occupancy %").

SELECT
    t.theatre_name,
    t.total_seats,
    AVG(b.seats_booked) AS avg_seats_booked,
    (AVG(b.seats_booked) / t.total_seats) * 100 AS avg_occupancy_pct
FROM bookings b
JOIN theatres t
    ON b.theatre_id = t.theatre_id
WHERE b.booking_status = 'Confirmed'
GROUP BY
    t.theatre_id,
    t.theatre_name,
    t.total_seats
ORDER BY total_seats DESC;
 
-- Q10. Find total confirmed revenue and booking count grouped by year-month of show_date, sorted chronologically.
 
SELECT
    YEAR(show_date) AS year,
    MONTH(show_date) AS month,
    COUNT(booking_id) AS booking_count,
    SUM(ticket_amount) AS total_revenue
FROM bookings
WHERE booking_status = 'Confirmed'
GROUP BY YEAR(show_date), MONTH(show_date)
ORDER BY year DESC;
 
-- Q11. Weekday vs weekend behaviour Compare average ticket_amount and total bookings on weekdays vs weekends (show_date).

SELECT
    CASE
        WHEN DAYOFWEEK(show_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    AVG(ticket_amount) AS avg_ticket_amount,
    COUNT(booking_id) AS total_bookings
FROM bookings 
WHERE booking_status = 'Confirmed'
GROUP BY
    CASE
        WHEN DAYOFWEEK(show_date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END;
 
-- Q12. Find the top 5 movies with the highest cancellation RATE (cancelled bookings / total bookings for that movie),considering only movies with at least 20 total bookings.

SELECT
    movie_id,
    COUNT(booking_id) AS total_bookings,
    SUM(
        CASE
            WHEN booking_status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_bookings,
    ROUND(
        SUM(
            CASE
                WHEN booking_status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(booking_id),
        2
    ) AS cancellation_rate
FROM bookings
GROUP BY movie_id
HAVING COUNT(booking_id) >= 20
ORDER BY cancellation_rate DESC
LIMIT 5;

 
-- Q13. List customers whose total confirmed spend is greater than the overall AVERAGE total spend across all customers.

SELECT
    c.customer_id,
    c.customer_name,
    SUM(b.ticket_amount) AS total_confirmed_spend
FROM bookings b
JOIN customers c
    ON b.customer_id = c.customer_id
WHERE b.booking_status = 'Confirmed'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(b.ticket_amount) > (
    SELECT AVG(total_spend)
    FROM (
        SELECT
            customer_id,
            SUM(ticket_amount) AS total_spend
        FROM bookings
        WHERE booking_status = 'Confirmed'
        GROUP BY customer_id
    ) AS customer_spend
)
ORDER BY total_confirmed_spend DESC;

-- Q14. For every city, find the single highest-revenue theatre using a correlated subquery or window function (no city should have 2 rows).

WITH theatre_revenue AS (
    SELECT
        t.city,
        t.theatre_id,
        t.theatre_name,
        SUM(b.ticket_amount) AS total_revenue
    FROM bookings b
    JOIN theatres t
        ON b.theatre_id = t.theatre_id
    WHERE b.booking_status = 'Confirmed'
    GROUP BY
        t.city,
        t.theatre_id,
        t.theatre_name
),
ranked_theatres AS (
    SELECT
        city,
        theatre_id,
        theatre_name,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY total_revenue DESC
        ) AS rn
    FROM theatre_revenue
)
SELECT
    city,
    theatre_id,
    theatre_name,
    total_revenue
FROM ranked_theatres
WHERE rn = 1
ORDER BY city;

-- Q15. For each month, show monthly confirmed revenue and a running cumulative revenue total using a window function.

WITH monthly_revenue AS (
    SELECT
        YEAR(b.show_date) AS year,
        MONTH(b.show_date) AS month,
        SUM(b.ticket_amount) AS monthly_revenue
    FROM bookings b
    WHERE b.booking_status = 'Confirmed'
    GROUP BY
        YEAR(b.show_date),
        MONTH(b.show_date)
)
SELECT
    year,
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY year, month
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY year, month;

-- Q16. Rank customers within their own city by total confirmed spend using RANK() or DENSE_RANK(), and return only rank 1-3 per city.

WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.city,
        SUM(b.ticket_amount) AS total_confirmed_spend
    FROM bookings b
    JOIN customers c
        ON b.customer_id = c.customer_id
    WHERE b.booking_status = 'Confirmed'
    GROUP BY
        c.customer_id,
        c.customer_name,
        c.city
),
ranked_customers AS (
    SELECT
        customer_id,
        customer_name,
        city,
        total_confirmed_spend,
        RANK() OVER (
            PARTITION BY city
            ORDER BY total_confirmed_spend DESC
        ) AS customer_rank
    FROM customer_spend
)
SELECT
    customer_id,
    customer_name,
    city,
    total_confirmed_spend,
    customer_rank
FROM ranked_customers
WHERE customer_rank <= 3
ORDER BY city, customer_rank;

-- Q17. Using NTILE(4), split movies into 4 revenue-based quartiles (tiers) based on total confirmed revenue, and count how many movies fall in each tier.
 

WITH movie_revenue AS (
    SELECT
        m.movie_id,
        m.movie_name,
        SUM(b.ticket_amount) AS total_confirmed_revenue
    FROM bookings b
    JOIN movies m
        ON b.movie_id = m.movie_id
    WHERE b.booking_status = 'Confirmed'
    GROUP BY
        m.movie_id,
        m.movie_name
),
movie_tiers AS (
    SELECT
        movie_id,
        movie_name,
        total_confirmed_revenue,
        NTILE(4) OVER (
            ORDER BY total_confirmed_revenue DESC
        ) AS revenue_tier
    FROM movie_revenue
)
SELECT
    revenue_tier,
    COUNT(*) AS movie_count
FROM movie_tiers
GROUP BY revenue_tier
ORDER BY revenue_tier;

-- Q18. Using LAG(), calculate month-over-month % change in confirmed revenue.
 
WITH monthly_revenue AS (
    SELECT
        YEAR(show_date) AS year,
        MONTH(show_date) AS month,
        SUM(ticket_amount) AS confirmed_revenue
    FROM bookings b
    WHERE booking_status = 'Confirmed'
    GROUP BY
        YEAR(show_date),
        MONTH(show_date)
),
revenue_with_lag AS (
    SELECT
        year,
        month,
        confirmed_revenue,
        LAG(confirmed_revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    year,
    month,
    confirmed_revenue,
    COALESCE(
        CAST(previous_month_revenue AS CHAR),
        'Not Found'
    ) AS previous_month_revenue,
    COALESCE(
        CAST(
            ROUND(
                (confirmed_revenue - previous_month_revenue)
                * 100.0 / previous_month_revenue,
                2
            ) AS CHAR
        ),
        'Not Found'
    ) AS mom_change_pct
FROM revenue_with_lag
ORDER BY year, month;

-- Q19. First booking vs signup gap.

WITH customer_bookings AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.signup_date,
        b.show_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id
            ORDER BY b.show_date
        ) AS booking_rank
    FROM customers c
    JOIN bookings b
        ON c.customer_id = b.customer_id
    JOIN movies m
        ON b.movie_id = m.movie_id
),
first_booking AS (
    SELECT
        customer_id,
        customer_name,
        signup_date,
        show_date AS first_booking_date,
        DATEDIFF(show_date, signup_date) AS days_to_first_booking
    FROM customer_bookings
    WHERE booking_rank = 1
)
SELECT
    customer_id,
    customer_name,
    signup_date,
    first_booking_date,
    days_to_first_booking,
    CASE
        WHEN days_to_first_booking BETWEEN 0 AND 7
            THEN '0-7 days'
        WHEN days_to_first_booking BETWEEN 8 AND 30
            THEN '8-30 days'
        ELSE '30+ days'
    END AS booking_bucket
FROM first_booking
ORDER BY customer_id;
 
-- Q20. RFM-style segmentation.

WITH customer_rfm AS (
    SELECT
        c.customer_id,
        c.customer_name,

        DATEDIFF(
            (SELECT MAX(b.show_date)
             FROM bookings b
             JOIN movies m
                 ON b.movie_id = m.movie_id
             WHERE b.booking_status = 'Confirmed'),
            MAX(b.show_date)
        ) AS recency,

        COUNT(b.booking_id) AS frequency,

        SUM(b.ticket_amount) AS monetary

    FROM customers c
    JOIN bookings b
        ON c.customer_id = b.customer_id
    JOIN movies m
        ON b.movie_id = m.movie_id

    WHERE b.booking_status = 'Confirmed'

    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    recency,
    frequency,
    monetary,

    CASE
        WHEN recency <= 30
             AND frequency >= 5
             AND monetary >= 5000
            THEN 'High Value'

        WHEN recency <= 90
             AND frequency >= 3
             AND monetary >= 2500
            THEN 'Medium Value'

        ELSE 'Low Value'
    END AS customer_value
FROM customer_rfm
ORDER BY monetary DESC;

