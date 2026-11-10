# Hotel Booking Analytics — Architecture & Workflow

## 1. Project Overview

The Hotel Booking Analytics project is an end-to-end data engineering and analytics solution developed using Databricks.

The project processes raw hotel booking CSV data through a Medallion Architecture consisting of Bronze, Silver, and Gold layers.

Using Databricks Lakeflow Spark Declarative Pipelines and SQL, the solution ingests booking records, removes duplicates, applies data-quality validation rules, separates clean and rejected records, and prepares business-level summary tables.

The processed data is visualized using a three-page Databricks AI/BI Dashboard covering booking trends, hotel and room performance, booking channels, and data quality.

## 2. Business Objective

The primary objective is to transform raw hotel booking data into reliable, analysis-ready information that supports hotel management in making data-driven decisions.

The project focuses on:

- Analyzing monthly booking and cancellation trends.
- Measuring hotel revenue and Average Daily Rate (ADR).
- Comparing room-type performance and guest satisfaction.
- Evaluating booking channels and cancellation rates.
- Identifying duplicate, incomplete, and invalid booking records.
- Maintaining data reliability through validation and reconciliation.

## 3. Project Scope

The solution processes hotel booking records for 2025.

The pipeline initially ingests 1,316 raw records, identifies 26 duplicate records, and retains 1,290 unique bookings.

After applying data-quality rules, 1,269 valid bookings are retained for business analysis, while 21 invalid bookings are separated for investigation.

The Gold layer produces five materialized views, which serve as the data sources for the final analytics dashboard.

The pipeline also performs record-count reconciliation to verify that all raw records are accounted for.

## 4. Technology Stack

| Technology | Usage |
|---|---|
| Databricks | Data engineering and analytics platform |
| Unity Catalog | Data organization and governance |
| Unity Catalog Volumes | Raw CSV file storage |
| Databricks SQL | Data transformation, validation and aggregation |
| Lakeflow Spark Declarative Pipelines | Pipeline orchestration and dependency management |
| Streaming Tables | Incremental Bronze ingestion |
| Materialized Views | Silver processing and Gold aggregations |
| Databricks AI/BI Dashboards | Interactive reporting and data visualization |

## 5. Medallion Architecture

The project follows a three-layer Medallion Architecture to transform raw hotel booking records into validated, business-ready datasets.

### 5.1 Bronze Layer — Raw Data Ingestion

The Bronze layer ingests hotel booking CSV files from a Unity Catalog Volume using `STREAM read_files()`.

The ingestion process also captures source-file metadata and ingestion timestamps for traceability.

**Output:** `bronze_hotel_bookings` — 1,316 records.

### 5.2 Silver Layer — Data Preparation and Validation

The Silver layer performs deduplication, data preparation and quality validation.

It consists of three datasets:

- `silver_bookings_prepared`: Removes duplicate booking IDs and retains 1,290 unique records.
- `silver_bookings_clean`: Retains 1,269 bookings that satisfy the validation rules.
- `silver_bookings_rejected`: Separates 21 invalid records for investigation.

The main rejection conditions include invalid stay dates and negative room rates.

Missing or unknown city and booking-channel values are tracked as data-quality indicators without automatically rejecting otherwise valid bookings.

### 5.3 Gold Layer — Business Aggregations

The Gold layer transforms validated booking data into business-level summaries using SQL aggregations.

Five materialized views are created:

1. `gold_monthly_bookings` — Monthly bookings, cancellations, room nights and revenue.
2. `gold_hotel_summary` — Hotel-level booking and revenue performance.
3. `gold_channel_summary` — Booking-channel performance and cancellation rates.
4. `gold_room_type_summary` — Room-type revenue, bookings and average guest ratings.
5. `gold_data_quality` — Data-quality metrics and reconciliation results.

### 5.4 Analytics Layer — AI/BI Dashboard

The Gold datasets are used to build a three-page Databricks AI/BI Dashboard:

- **Overview:** Booking KPIs, monthly trends, revenue and ADR.
- **Hotels, Rooms & Channels:** Performance comparisons across hotels, regions, cities, booking channels and room types.
- **Data Quality & Reconciliation:** Data volumes, duplicates, rejected records, quality issues and reconciliation status.

The dashboard provides interactive filtering and supports business performance monitoring.

## 6. Pipeline Reconciliation

The pipeline verifies that all source records are accounted for.

**Raw Records = Clean Records + Rejected Records + Duplicate Records**

1,316 = 1,269 + 21 + 26

**Reconciliation Difference:** 0

**Reconciliation Status:** PASSED

This confirms record-count consistency across the pipeline for the validated dataset.

## 7. Data Cleaning and Quality Validation

The Silver layer prepares raw booking records for reliable business analysis.

### 7.1 Duplicate Removal

Duplicate booking records are identified using `ROW_NUMBER()` partitioned by `booking_id`.

The pipeline retains one record per booking ID and removes additional occurrences.

- Raw records: 1,316
- Unique bookings: 1,290
- Duplicate records removed: 26

### 7.2 Data Standardization

The following SQL functions are used during preparation:

- `TRIM()` removes unnecessary leading and trailing spaces.
- `INITCAP()` standardizes text capitalization.
- `TRY_CAST()` converts values into the required data types while returning NULL for values that cannot be converted.
- `NULLIF()` converts empty text values into NULL.
- `COALESCE()` supplies defined fallback values for missing data.

Missing city and booking-channel values are standardized to `Unknown`.

### 7.3 Missing-Value Handling

Missing nights are calculated using the difference between checkout and check-in dates when the original nights value is NULL.

Missing total amounts are calculated using room rate multiplied by the number of nights when the original amount is NULL.

These fallback calculations are applied only when the required input values are available.

### 7.4 Data Quality Validation

Bookings are validated using the following rules:

- Check-in and checkout dates must be present and valid.
- Checkout date must be later than check-in date.
- Room rate must be present and non-negative.

Records failing these rules are separated into `silver_bookings_rejected`, with a rejection reason.

The rejected dataset contains:

| Rejection reason | Records |
|---|---:|
| Invalid stay dates | 12 |
| Negative room rates | 9 |
| **Total rejected** | **21** |

These counts represent the rejection reasons assigned by the pipeline.

### 7.5 Quality Monitoring

The Gold data-quality view tracks:

| Quality metric | Result |
|---|---:|
| Duplicate records | 26 |
| Rejected bookings | 21 |
| Unknown cities | 11 |
| Unknown booking channels | 13 |
| Reconciliation difference | 0 |
| Reconciliation status | PASSED |

## 8. Business Metrics and Gold Transformations

The Gold layer creates business-ready aggregated datasets from validated booking records.

### 8.1 Monthly Booking Trends

Dataset: `gold_monthly_bookings`

Bookings are grouped by the month of check-in using `DATE_TRUNC('MONTH', check_in_date)`.

Metrics include total bookings, cancellations, completed room nights, and net revenue.

### 8.2 Hotel Performance

Dataset: `gold_hotel_summary`

Bookings are aggregated by region, city, and hotel name.

The summary includes booking counts, completed bookings, room nights, net revenue, and Average Daily Rate (ADR).

**ADR = Net Revenue / Completed Room Nights**

`NULLIF()` protects the calculation from division by zero.

### 8.3 Room Type Performance

Dataset: `gold_room_type_summary`

Bookings are grouped by room type to analyze booking volume, revenue, completed room nights, and guest satisfaction.

Average guest rating is calculated from available ratings associated with completed bookings.

`AVG()` ignores NULL ratings.

### 8.4 Booking Channel Performance

Dataset: `gold_channel_summary`

Bookings are grouped by booking channel to compare volume, revenue, cancellations, and cancellation rates.

**Cancellation Rate (%) = Cancelled Bookings / Total Bookings × 100**

### 8.5 Business Calculation Rules

The following rules are applied consistently:

- Total bookings include all valid bookings, including cancellations.
- Only bookings with `Completed` status contribute to revenue.
- Only completed bookings contribute to room nights.
- Net revenue is calculated as total amount minus discount amount.
- ADR is calculated using net revenue and completed room nights.
- Cancellation rate uses all valid bookings as the denominator.
- Guest ratings are averaged using available ratings from completed bookings.

### 8.6 Validated Business Results

| KPI | Result |
|---|---:|
| Total bookings | 1,269 |
| Completed bookings | 1,083 |
| Cancelled bookings | 186 |
| Cancellation rate | 14.66% |
| Completed room nights | 3,107 |
| Net revenue | ₹15,054,596.50 |
| ADR | ₹4,845.38 |

The monthly, hotel, room-type, and booking-channel Gold summaries were reconciled to confirm consistent booking, room-night, and revenue totals.

## 9. Pipeline Execution and Orchestration

The project uses Databricks Lakeflow Spark Declarative Pipelines to manage the execution of Bronze, Silver and Gold datasets.

**Pipeline Name:** `hotel_booking_medallion_pipeline`

**Catalog:** `hotel_bookings`

**Schema:** `bookings`

**Raw Data Location:** `/Volumes/hotel_bookings/bookings/raw_files/`

### 9.1 Pipeline Execution Flow

1. Raw hotel booking CSV files are stored in a Unity Catalog Volume.
2. The Bronze streaming table ingests the source records using `STREAM read_files()`.
3. The Silver preparation materialized view performs data cleaning and deduplication.
4. Silver validation separates clean and rejected bookings.
5. Gold materialized views calculate business metrics and data-quality summaries.
6. Databricks AI/BI Dashboards query the Gold datasets for reporting.

Lakeflow manages dataset dependencies and executes transformations in the required order.

### 9.2 Pipeline Components

The pipeline contains nine datasets:

| Layer | Dataset | Type |
|---|---|---|
| Bronze | `bronze_hotel_bookings` | Streaming Table |
| Silver | `silver_bookings_prepared` | Materialized View |
| Silver | `silver_bookings_clean` | Materialized View |
| Silver | `silver_bookings_rejected` | Materialized View |
| Gold | `gold_monthly_bookings` | Materialized View |
| Gold | `gold_hotel_summary` | Materialized View |
| Gold | `gold_room_type_summary` | Materialized View |
| Gold | `gold_channel_summary` | Materialized View |
| Gold | `gold_data_quality` | Materialized View |

All nine datasets were successfully executed and verified through the Lakeflow pipeline graph.

## 10. Data Validation and Testing

Testing was performed at multiple stages to verify data quality and business metric consistency.

### 10.1 Record-Level Validation

The pipeline was checked to confirm:

- Duplicate booking IDs were removed.
- Invalid stay dates were identified.
- Negative room rates were rejected.
- Valid and rejected bookings were stored separately.
- Missing city and booking-channel values were handled consistently.

### 10.2 Reconciliation Testing

Record reconciliation was performed using the following calculation:

**Raw Records − Duplicates − Rejected Records − Clean Records = 0**

1,316 − 26 − 21 − 1,269 = 0

**Result: PASSED**

### 10.3 Business Metric Validation

Gold datasets were checked for consistent booking counts, cancellation counts, room nights and revenue.

The final validated metrics include:

- 1,269 total bookings
- 1,083 completed bookings
- 186 cancelled bookings
- 3,107 completed room nights
- ₹15,054,596.50 net revenue
- ₹4,845.38 Average Daily Rate

## 11. Dashboard Design and Functional Testing

The project includes a three-page Databricks AI/BI Dashboard named **Hotel Booking Analytics**.

### 11.1 Page 1 — Overview

This page provides:

- Total bookings
- Completed bookings
- Cancelled bookings
- Cancellation rate
- Completed room nights
- Net revenue
- Average Daily Rate
- Monthly booking and revenue trends
- Monthly cancellation trends
- Booking detail table
- Date filtering

### 11.2 Page 2 — Hotels, Rooms & Channels

This page analyzes performance across:

- Regions and cities
- Hotels
- Room types
- Booking channels
- Revenue and booking volume
- Cancellation rates
- Guest ratings

Interactive filters include Region, City and Booking Channel.

### 11.3 Page 3 — Data Quality & Reconciliation

This page monitors:

- Raw and unique record counts
- Duplicate records
- Clean and rejected bookings
- Invalid stay dates
- Negative room rates
- Unknown city and booking-channel values
- Reconciliation difference and status

### 11.4 Dashboard Testing

The dashboard was tested using different filter selections.

**Test 1: January 2025**

| Metric | Result |
|---|---:|
| Total bookings | 110 |
| Completed bookings | 93 |
| Cancelled bookings | 17 |
| Completed room nights | 270 |
| Cancellation rate | 15.45% |

**Test 2: Region Filter**

Selecting the West region correctly filtered the relevant region and city visualizations.

**Test 3: Booking Channel Filter**

Selecting Mobile App correctly filtered the three booking-channel visualizations configured for that filter.

Some unrelated aggregated datasets remained unaffected because they do not contain the booking-channel dimension.

**Test 4: Data Quality**

The data-quality dashboard values matched the Gold data-quality dataset.

## 12. Implementation Challenges and Considerations

### 12.1 Managing Data Quality

**Challenge:** The source data contained duplicate bookings, invalid stay dates, negative room rates and missing categorical values.

**Approach:** Separate data preparation from validation, preserve rejected records and implement record-count reconciliation.

### 12.2 Maintaining Consistent Business Calculations

**Challenge:** Booking counts, revenue and room-night metrics require different business rules.

**Approach:** Include cancelled bookings in total booking counts while calculating revenue and room nights from completed bookings only.

### 12.3 Dashboard Filtering Across Aggregated Datasets

**Consideration:** Gold summary datasets have different aggregation levels and dimensions.

**Approach:** Configure dashboard filters only for compatible datasets and avoid joining unrelated Gold summaries in ways that could duplicate aggregated values.

### 12.4 Data Traceability

**Consideration:** Raw records should remain traceable throughout processing.

**Approach:** Preserve source-file information and ingestion timestamps in Bronze, and maintain a separate rejected-record dataset in Silver.

## 13. Project Outcome

The project successfully implemented an end-to-end hotel booking analytics pipeline using Databricks and Medallion Architecture.

The solution transformed 1,316 raw booking records into 1,269 validated bookings, created five Gold-level analytical datasets, and delivered a three-page interactive business dashboard.

The pipeline achieved a zero record-count reconciliation difference and provides a reusable foundation for analyzing booking activity, hotel performance, revenue, cancellations and data quality.

## 14. Supporting Project Files

The GitHub repository will include:

- `sql/bronze/` — Raw data ingestion SQL
- `sql/silver/` — Data preparation and validation SQL
- `sql/gold/` — Business metrics and data-quality SQL
- `screenshots/` — Pipeline and dashboard screenshots
- `docs/architecture_and_workflow.md` — Complete architecture and implementation documentation
- `README.md` — Project overview and repository navigation