
-- BR-05 & BR-06: Data Quality and Reconciliation

CREATE OR REFRESH MATERIALIZED VIEW gold_data_quality
AS
WITH bronze_counts AS (
    SELECT
        COUNT(*) AS raw_records,
        COUNT(DISTINCT booking_id) AS unique_bookings,
        COUNT(*) - COUNT(DISTINCT booking_id)
            AS duplicate_rows
    FROM bronze_hotel_bookings
),

silver_counts AS (
    SELECT
        COUNT(*) AS clean_bookings,

        SUM(
            CASE WHEN city = 'Unknown'
            THEN 1 ELSE 0 END
        ) AS unknown_cities,

        SUM(
            CASE WHEN booking_channel = 'Unknown'
            THEN 1 ELSE 0 END
        ) AS unknown_channels

    FROM silver_bookings_clean
),

rejected_counts AS (
    SELECT
        COUNT(*) AS rejected_bookings,

        SUM(
            CASE WHEN reject_reason = 'Invalid stay dates'
            THEN 1 ELSE 0 END
        ) AS invalid_stay_dates,

        SUM(
            CASE WHEN reject_reason = 'Negative room rate'
            THEN 1 ELSE 0 END
        ) AS negative_room_rates

    FROM silver_bookings_rejected
)

SELECT
    b.raw_records,
    b.unique_bookings,
    b.duplicate_rows,

    s.clean_bookings,
    r.rejected_bookings,

    r.invalid_stay_dates,
    r.negative_room_rates,

    s.unknown_cities,
    s.unknown_channels,

    b.raw_records
      - (s.clean_bookings
         + r.rejected_bookings
         + b.duplicate_rows)
        AS reconciliation_difference,

    CASE
        WHEN b.raw_records =
             s.clean_bookings
             + r.rejected_bookings
             + b.duplicate_rows
        THEN 'PASSED'
        ELSE 'FAILED'
    END AS reconciliation_status

FROM bronze_counts b
CROSS JOIN silver_counts s
CROSS JOIN rejected_counts r;
