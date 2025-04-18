**Project Design: Medicare Provider Analysis Dashboard (GCP & Power BI)**

**1) Problem Description**

*   **Problem:** Healthcare administrators, policymakers, and researchers need to understand the distribution and service patterns of Medicare providers across the United States. Key questions include where different types of providers are concentrated and which medical services (identified by HCPCS codes) are most frequently rendered. Analyzing the vast Medicare public data requires significant processing and is not readily available for quick visualization.
*   **Project Goal:** To build an automated pipeline on GCP that processes the public Medicare Physician and Other Supplier dataset, transforms it for analysis, and presents key insights via an interactive Power BI dashboard. Specifically, the dashboard will visualize the geographical distribution of provider types and identify the most common services provided.
*   **Solution:** This project implements a cloud-based data pipeline using GCP services. It leverages BigQuery for accessing public data and warehousing, Cloud Composer (Airflow) for orchestration, dbt for transformations, and Power BI for visualization. Infrastructure will be managed using Terraform.

**2) Cloud Development and IaC (Infrastructure as Code)**

*   **Cloud Provider:** Google Cloud Platform (GCP)
*   **IaC Tool:** Terraform (using the `google` provider).
*   **Terraform Managed Resources:**
    *   **Project Setup:** GCP Project configuration (if managing projects via Terraform).
    *   **Storage:** Google Cloud Storage (GCS) Buckets (e.g., for dbt logs, temporary files, optional staging if needed - though less critical here as source is BigQuery).
    *   **Orchestration:** Cloud Composer 2 Environment.
    *   **Data Warehouse:** BigQuery Datasets (e.g., `medicare_staging`, `medicare_analytics`).
    *   **Identity & Access:** IAM Service Accounts (for Composer, dbt execution), Roles, and Bindings granting necessary permissions (e.g., Composer accessing BigQuery, BigQuery Data Editor/Viewer roles).


**3) Batch / Workflow Orchestration & End-to-End Pipeline**

*   **Orchestration Tool:** Cloud Composer (Managed Apache Airflow on GCP).
*   **Dataset:** `bigquery-public-data.medicare.physicians_and_other_suppliers` (Choosing a specific year's table, e.g., `physicians_and_other_suppliers_2019`)
*   **End-to-End Pipeline (Conceptual Airflow DAG):**

    *   **DAG ID:** `medicare_analytics_pipeline` (Scheduled: e.g., Annually, or triggered manually)
        1.  `start_pipeline`: DummyOperator marking the start.
        2.  `create_staging_table`: `BigQueryOperator` executing a `CREATE OR REPLACE TABLE` statement.
            *   **Action:** Selects relevant columns from the public dataset (`bigquery-public-data.medicare.physicians_and_other_suppliers_2019`) and copies them into a staging table within our project (e.g., `your-gcp-project.medicare_staging.stg_physicians_suppliers_2019`). This isolates our processing from the public dataset and potentially allows pre-filtering or casting.
            *
        3.  `run_dbt_transformations`: `BashOperator` (or KubernetesPodOperator if dbt runs in a container).
            *   **Action:** Navigates to the dbt project directory (checked out from a repo like Cloud Source Repositories) and executes `dbt run --profiles-dir . --target prod`. Assumes dbt is installed in the Composer environment or worker, and the `profiles.yml` is configured for BigQuery using a service account.
        4.  `end_pipeline`: DummyOperator marking successful completion.

**4) BigQuery Table Design (Partitioning & Clustering)**

*   **Staging Dataset:** `medicare_staging`
    *   Table: `stg_physicians_suppliers_YYYY` (No partitioning/clustering needed, temporary).
*   **Analytics Dataset:** `medicare_analytics`
    *   **Table 1: `agg_provider_type_by_state`**
        *   Purpose: Aggregated counts of providers by type and state.
        *   Columns: `provider_state` (STRING), `provider_type` (STRING), `year` (INTEGER), `distinct_provider_count` (INTEGER), `total_services_rendered` (NUMERIC).
        *   **Partitioning:** `year` (Integer Range Partitioning, if analyzing multiple years. If only one year, partitioning isn't necessary on this table).
            *   **Explanation:** Analysis often involves comparing years or focusing on a specific year. Partitioning prunes data scanned based on year filters.
        *   **Clustering:** `provider_state`, `provider_type`.
            *   **Explanation:** Queries will frequently filter or group by state and provider type (`WHERE provider_state = 'CA'` or `GROUP BY provider_state, provider_type`). Clustering co-locates data with the same state and type, significantly reducing data scanned and improving query performance for these common access patterns.
    *   **Table 2: `agg_service_summary`**
        *   Purpose: Aggregated summary of services (HCPCS codes).
        *   Columns: `hcpcs_code` (STRING), `hcpcs_description` (STRING), `year` (INTEGER), `total_times_rendered` (NUMERIC), `avg_allowed_amount` (NUMERIC).
        *   **Partitioning:** `year` (Integer Range Partitioning, similar reasoning as above).
        *   **Clustering:** `hcpcs_code`.
            *   **Explanation:** Queries looking up specific services or grouping by service codes (`WHERE hcpcs_code = '99213'` or `GROUP BY hcpcs_code`) benefit from clustering, as rows with the same code are stored together.

**5) Transformations**

*   **Transformation Tool:** dbt (data build tool)
*   **dbt Project Configuration (`profiles.yml`):** Configure to use the `bigquery` adapter, specifying the GCP project, dataset (`medicare_analytics`), and authentication method (e.g., service account key file).
*   **dbt Models:**
    *   `models/staging/schema.yml`: Define source pointing to `medicare_staging.stg_physicians_suppliers_YYYY`.
    *   `models/staging/stg_medicare_physicians_suppliers.sql`: Basic selection, renaming, casting.
       
*   **Execution:** The Airflow task `run_dbt_transformations` executes `dbt run`, which reads from the staging table and creates/updates the two aggregate tables (`agg_provider_type_by_state`, `agg_service_summary`) in the `medicare_analytics` BigQuery dataset, applying the partitioning and clustering defined in the model configs.

**6) Dashboard (Power BI)**

*   **Tool:** Power BI Desktop / Service
*   **Data Source Connection:**
    1.  In Power BI Desktop, select "Get Data".
    2.  Search for and select "Google BigQuery".
    3.  Connect using either Organizational account or Service Account Login . Provide the Service Account email and the JSON key file content.
    4.  Navigate to your GCP Project -> `medicare_analytics` dataset.
    5.  Select the tables: `agg_provider_type_by_state` and `agg_service_summary`.
    6.  Choose "Import" mode (suitable for aggregated data) or "DirectQuery". Select "Import".
*   **Dashboard Tiles:**
    *   **Tile 1: Provider Count by State and Type**
        *   **Visualization Type:** Treemap (good for hierarchical proportions) or Filled Map.
        *   **Details (Treemap):** `provider_state`, `provider_type`
        *   **Values (Treemap):** `distinct_provider_count`
        *   **Description:** Shows the relative number of distinct Medicare providers across different states, broken down by their specialty/type. Add slicers for `provider_state` and `provider_type` for filtering.
    *   **Tile 2: Top 10 Most Frequent Services (National)**
        *   **Visualization Type:** Bar Chart (Horizontal or Vertical)
        *   **Axis:** `hcpcs_description` (or `hcpcs_code` if description is less clear)
        *   **Value:** `total_times_rendered`
        *   **Filter:** Apply a "Top N" filter on the visual (in the Filters pane), selecting Top 10 based on `total_times_rendered`.
        *   **Description:** Highlights the 10 Medicare services (HCPCS codes) that were performed most often nationally in the selected year(s). Add a slicer for `year`. Optionally add a slicer for `provider_state` to see top services within a specific state using the `agg_provider_type_by_state` table potentially (requires slight model adjustment or relationship).
