# 🎬 Movie Ticket Booking Analysis — SQL

## 📌 Project Overview
This Project Analyzed **Movie Ticket Booking Database** Using SQL to uncover insights related to Bookings, Revenue, Customers, Movies, Theatres, Payments and Customer Behaviors.

The Project Contains **20 business-driven SQL queries** Progressing from basic Aggregations and Joins to Advanced SQL Techniques Such as **CTEs, subqueries, window functions, customer segmentation and RFM-style analysis**.

## 🎯 Business Objectives

* Analyzed Overall Booking Performance and Confirmed Revenue.
* Understand Booking Status Distribution.
* Identify High-performing Payment Methods and Theatre cities.
* Analyzed Movie Genres and Languages.
* Identify Top-spending Customers.
* Compare One-time vs Repeat Customers.
* Measure Theatre Occupancy.
* Analyzed Monthly and weekday/weekend Booking Trends.
* Identify Movies with High Cancellation Rates.
* Find Top-performing Theatres within each City.
* Calculate cumulative and Month-over-month Revenue.
* Rank Customers within their Cities.
* Segment Movies based on Revenue
* Analyzed Customer Acquisition-to-first-booking Behavior.
* Perform RFM-style Customer Segmentation.

## 🛠️ SQL Skills Demonstrated

* `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`
* Aggregate Functions — `SUM()`, `COUNT()`, `AVG()`
* `JOIN`
* Subqueries
* Common Table Expressions (CTEs)
* `CASE WHEN`
* `HAVING`
* Date Functions
* Window Functions:

  * `RANK()`
  * `ROW_NUMBER()`
  * `NTILE()`
  * `LAG()`

## 📊 Key Analysis Areas

| Area                  | Analysis                                      |
| --------------------- | --------------------------------------------- |
| 💰 Revenue            | Total, monthly, cumulative & MoM revenue      |
| 🎟️ Bookings          | Confirmed, pending & cancelled bookings       |
| 🎬 Movies             | Genre, language & revenue performance         |
| 🏢 Theatres           | City-wise performance & occupancy             |
| 👥 Customers          | Top spenders, repeat customers & segmentation |
| 💳 Payments           | Payment method ,revenue ranking                |
| 📅 Time Analysis      | Monthly & weekday/weekend behaviors           |
| 📈 Advanced Analytics | Ranking, quartiles, cancellation rate & RFM   |

## 🔍 Advanced SQL Analysis

**Running Revenue Total**

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

**Movie Revenue Tiers**

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


**Month-over-Month Revenue Growth**

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

**RFM-style Customer Segmentation**

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


## 🛠️ Tools & Technologies

* **MySQL** — Database management and SQL analysis.
* **Power Query** - Clean and Filter the Raw Data.


