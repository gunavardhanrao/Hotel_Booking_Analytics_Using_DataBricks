
-- ============================================
-- SILVER CLEAN BOOKINGS
-- ============================================

CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_clean (
    CONSTRAINT valid_stay_dates
        EXPECT (
            check_in_date IS NOT NULL
            AND check_out_date IS NOT NULL
            AND check_out_date > check_in_date
        ) ON VIOLATION DROP ROW,

    CONSTRAINT valid_room_rate
        EXPECT (
            room_rate IS NOT NULL
            AND room_rate >= 0
        ) ON VIOLATION DROP ROW
)
AS
SELECT *
FROM silver_bookings_prepared
WHERE check_in_date IS NOT NULL
  AND check_out_date IS NOT NULL
  AND check_out_date > check_in_date
  AND room_rate IS NOT NULL
  AND room_rate >= 0;


-- ============================================
-- SILVER REJECTED BOOKINGS
-- ============================================

CREATE OR REFRESH MATERIALIZED VIEW silver_bookings_rejected
AS
SELECT
    *,
    CASE
        WHEN check_in_date IS NULL
          OR check_out_date IS NULL
            THEN 'Missing or invalid stay date'

        WHEN check_out_date <= check_in_date
            THEN 'Invalid stay dates'

        WHEN room_rate IS NULL
            THEN 'Missing or invalid room rate'

        WHEN room_rate < 0
            THEN 'Negative room rate'
    END AS reject_reason

FROM silver_bookings_prepared
WHERE check_in_date IS NULL
   OR check_out_date IS NULL
   OR check_out_date <= check_in_date
   OR room_rate IS NULL
   OR room_rate < 0;
