# StreamCart dbt Project

## Project Overview
This is a comprehensive dbt Core data pipeline for the StreamCart e-commerce scenario. It transforms raw JSON event data into a Kimball-style dimensional model (marts) using SCD Type 2 snapshots, incremental processing, and robust data quality testing.

## Warehouse Requirements
* Databricks Workspace (Delta Lake)
* Compute Cluster running Spark SQL

## Configuration
To run this locally, configure your `~/.dbt/profiles.yml` file with your Databricks host, HTTP path, and Personal Access Token. Do not commit this file to version control.

## Execution Steps
1. Load seeds: `dbt seed`
2. Run staging models: `dbt run --select staging`
3. Run mart models: `dbt run --select marts`
4. Test pipeline: `dbt test`

## Mart Models
* `dim_customers`: Customer lifetime value and geographic data.
* `fct_orders`: Incremental fact table for order line items.
* `monthly_revenue_summary`: Aggregate KPI table for monthly revenue.
* `product_performance`: Aggregate KPI table for unit sales and inventory.
* `channel_performance_summary`: Aggregate KPI table tracking platform success rates.