# FDA Drug Shortages: Clinical Risk & Supply Chain Velocity Dashboard

An end-to-end data engineering and analytics project that processes, models, and visualizes U.S. Food and Drug Administration (FDA) drug shortage records. The pipeline extracts and normalizes semi-structured JSON data inside PostgreSQL and surfaces operational risk intelligence through an interactive two-page Power BI dashboard.

---

## Architecture Overview

```
┌─────────────────────────────────┐
│     openFDA Data Source         │
│ (drug-shortages-0001-of-0001)   │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│   PostgreSQL Ingestion Layer    │
│  - Raw JSONB Staging Table      │
│  - Relational Schema Mapping    │
│  - Array & JSONB Unpacking      │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│   Analytical Transformation     │
│  - vw_fact_drug_shortages       │
│  - vw_dim_therapeutic_category  │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│    Power BI Reporting Layer     │
│  - Clinical Risk & Specialty    │
│  - Shortage Aging & Velocity    │
└─────────────────────────────────┘
```

---

## Data Source

The dataset used in this project is sourced directly from the **U.S. Food and Drug Administration (FDA) openFDA Drug Shortages API / Public Data Export**:

* **Source**: [openFDA Drug Shortages Dataset](https://open.fda.gov/data/drugshortages/)
* **Format**: JSON (`drug-shortages-0001-of-0001.json`)
* **Scope**: Regulatory reports detailing human drug shortages in the United States, including national drug codes (`package_ndc`), generic and brand names, therapeutic categories, dosage presentations, shortage reasons, change velocity, and resolution statuses.

---

## Repository Structure

```
├── drug-shortages-0001-of-0001.json   # Source JSON export from openFDA
├── import_data.sql                   # SQL script for staging and raw JSON ingestion
├── create_tables_and_views.sql       # DDL scripts for tables, indexes, and analytical views
├── drug_shortage_analysis.pbix       # Power BI report file with visual layouts and models
└── README.md                         # Project documentation and execution guide
```

### File Descriptions

* **`drug-shortages-0001-of-0001.json`**: The complete raw openFDA drug shortages export containing nested product records, dates, and administrative attributes.
* **`import_data.sql`**: Contains the commands required to ingest the multiline JSON payload into a PostgreSQL `JSONB` staging table via `psql` or native copy techniques.
* **`create_tables_and_views.sql`**: 
  * Builds the core `drug_shortages` structured table with appropriate data types (`DATE`, `TEXT[]`, `JSONB`).
  * Establishes B-tree and GIN indexes for performant querying.
  * Creates `vw_fact_drug_shortages` (with calculated duration, staleness metrics, and risk tier logic).
  * Creates `vw_dim_therapeutic_category` (unnests multi-value therapeutic categories to prevent M:M join fan-out).
* **`drug_shortage_analysis.pbix`**: The compiled Power BI report configured with clean dimensional relationships and interactive visual elements across two reporting pages.

---

## Power BI Dashboard Overview

The analytical report is divided into two distinct executive pages designed for clinical procurement leads, hospital inventory directors, and healthcare supply chain analysts:

### Page 1: Clinical Risk & Specialty Exposure

* **Core Objective**: Measure the clinical vulnerability of hospital specialty service lines and evaluate exposure across different dosage forms and administration routes.
* **Key Visuals & Insights**:
  * **Executive KPI Cards**: Real-time totals for active shortages, critical tier-1 deficits, and high-risk product volume.
  * **Therapeutic Risk Matrix**: Evaluates specialty categories (e.g., Anesthesia, Oncology, Cardiovascular, Emergency Medicine) across defined severity tiers to locate departments under acute operational pressure.
  * **Route Vulnerability Breakdown**: Identifies supply strains on critical delivery mechanisms (e.g., Intravenous vs. Oral).
  * **Formulation Composition**: Categorizes product volume into sterile injectables, oral solids, and liquids to highlight reliance on high-risk manufacturing categories.
  * **Clinical Action Worklist**: Drill-down tabular inventory listing NDC codes, generic names, presentations, and manufacturer contacts for immediate alternative sourcing.

### Page 2: Shortage Aging & Velocity Metrics

* **Core Objective**: Benchmark supply chain recovery latency, identify chronic multi-year market failures, and flag communication staleness from manufacturers.
* **Key Visuals & Insights**:
  * **Latency & Staleness KPIs**: Tracks mean and median active shortage duration alongside the average interval since regulatory verification.
  * **Aging Distribution Profile**: Buckets active disruptions into standardized age intervals (0–90 days, 91–180 days, 181–365 days, 1–2 years, and >2 years) segmented by current availability.
  * **Specialty Resolution Backlog**: Compares median active days across therapeutic domains to identify sectors experiencing systemic, slow-to-resolve shortages.
  * **Transparency & Velocity Matrix**: Plots total duration against days since last update to isolate "neglected chronic shortages" requiring regulatory follow-up.
  * **Root Cause vs. Duration Analysis**: Maps reported shortage drivers (e.g., API constraints, shipping delays, manufacturing delays) to observe which mechanisms lead to the longest market disruptions.

---

## Setup & Reproduction Guide

### 1. Prerequisites
* **PostgreSQL** (v14 or newer recommended)
* **Power BI Desktop**
* Terminal access with the `psql` command-line client

### 2. Database Initialization & Data Loading

1. Create a database for the project:
   ```bash
   createdb drug_shortage
   ```

2. Load the staging schema and import the raw JSON:
   ```bash
   psql -d drug_shortage -f import_data.sql
   ```

3. Generate the structured tables, unpack JSON fields, and create the reporting views:
   ```bash
   psql -d drug_shortage -f create_tables_and_views.sql
   ```

### 3. Power BI Configuration

1. Launch **Power BI Desktop** and open `drug_shortage_analysis.pbix`.
2. Navigate to **Home > Transform Data > Data source settings**.
3. Point the PostgreSQL connection to your local or remote database server (`localhost:5432`, database: `drug_shortage`).
4. Click **Apply Changes** to refresh the dataset directly from `vw_fact_drug_shortages` and `vw_dim_therapeutic_category`.
