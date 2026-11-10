
CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_bookings
AS
SELECT
    DATE_TRUNC('MONTH', check_in_date) AS stay_month,

    COUNT(*) AS bookings,

    SUM(
        CASE
            WHEN booking_status = 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_bookings,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN nights ELSE 0
        END
    ) AS room_nights,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN total_amount - discount_amount
            ELSE 0
        END
    ) AS net_revenue

FROM silver_bookings_clean

GROUP BY DATE_TRUNC('MONTH', check_in_date);



CREATE OR REFRESH MATERIALIZED VIEW gold_hotel_summary
AS
WITH hotel_metrics AS (
    SELECT
        region,
        city,
        hotel_name,

        COUNT(*) AS bookings,

        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN 1 ELSE 0
            END
        ) AS completed_bookings,

        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN nights ELSE 0
            END
        ) AS room_nights,

        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN total_amount - discount_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM silver_bookings_clean
    GROUP BY region, city, hotel_name
)

SELECT
    *,
    ROUND(
        net_revenue / NULLIF(room_nights, 0),
        2
    ) AS adr
FROM hotel_metrics;



-- BR-03: Room Type Performance

CREATE OR REFRESH MATERIALIZED VIEW gold_room_type_summary
AS
SELECT
    room_type,

    COUNT(*) AS bookings,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN 1 ELSE 0
        END
    ) AS completed_bookings,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN nights ELSE 0
        END
    ) AS room_nights,

    SUM(
        CASE
            WHEN booking_status = 'Completed'
            THEN total_amount - discount_amount
            ELSE 0
        END
    ) AS net_revenue,

    ROUND(
        AVG(
            CASE
                WHEN booking_status = 'Completed'
                THEN guest_rating
            END
        ),
        2
    ) AS avg_guest_rating

FROM silver_bookings_clean

GROUP BY room_type;


-- BR-04: Booking Channel Performance

CREATE OR REFRESH MATERIALIZED VIEW gold_channel_summary
AS
WITH channel_metrics AS (
    SELECT
        booking_channel,

        COUNT(*) AS bookings,

        SUM(
            CASE
                WHEN booking_status = 'Cancelled'
                THEN 1 ELSE 0
            END
        ) AS cancelled_bookings,

        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN 1 ELSE 0
            END
        ) AS completed_bookings,

        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN nights ELSE 0
            END
        ) AS room_nights,

        SUM(
            CASE
                WHEN booking_status = 'Completed'
                THEN total_amount - discount_amount
                ELSE 0
            END
        ) AS net_revenue

    FROM silver_bookings_clean
    GROUP BY booking_channel
)

SELECT
    *,
    ROUND(
        cancelled_bookings * 100.0
        / NULLIF(bookings, 0),
        2
    ) AS cancellation_rate_pct

FROM channel_metrics;

