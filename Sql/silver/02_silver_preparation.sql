
CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_prepared
AS
WITH deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY booking_id
            ORDER BY booking_date
        ) AS row_num
    FROM hotel_bookings.bookings.bronze_hotel_bookings
),

typed AS (
    SELECT
        booking_id,
        NULLIF(TRIM(guest_id), '') AS guest_id,

        TRY_CAST(booking_date AS DATE) AS booking_date,
        TRY_CAST(check_in_date AS DATE) AS check_in_date,
        TRY_CAST(check_out_date AS DATE) AS check_out_date,

        TRY_CAST(nights AS INT) AS original_nights,

        INITCAP(TRIM(hotel_name)) AS hotel_name,

        COALESCE(
            INITCAP(NULLIF(TRIM(city), '')),
            'Unknown'
        ) AS city,

        INITCAP(TRIM(region)) AS region,
        INITCAP(TRIM(room_type)) AS room_type,

        COALESCE(
            INITCAP(NULLIF(TRIM(booking_channel), '')),
            'Unknown'
        ) AS booking_channel,

        TRY_CAST(guests AS INT) AS guests,

        TRY_CAST(room_rate AS DECIMAL(12,2))
            AS room_rate,

        TRY_CAST(total_amount AS DECIMAL(12,2))
            AS original_amount,

        TRY_CAST(discount_amount AS DECIMAL(12,2))
            AS discount_amount,

        INITCAP(TRIM(meal_plan)) AS meal_plan,
        INITCAP(TRIM(payment_method)) AS payment_method,
        INITCAP(TRIM(payment_status)) AS payment_status,
        INITCAP(TRIM(booking_status)) AS booking_status,

        TRY_CAST(guest_rating AS INT) AS guest_rating

    FROM deduplicated
    WHERE row_num = 1
),

calculated AS (
    SELECT
        *,
        COALESCE(
            original_nights,
            DATEDIFF(check_out_date, check_in_date)
        ) AS nights
    FROM typed
)

SELECT
    * EXCEPT (original_nights, original_amount),

    COALESCE(
        original_amount,
        nights * room_rate
    ) AS total_amount

FROM calculated;
