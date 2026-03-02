# 🏭 End-to-End Sales Data Pipeline — Microsoft Fabric

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Microsoft Fabric](https://img.shields.io/badge/Microsoft-Fabric-blue)](https://fabric.microsoft.com)
[![Power BI](https://img.shields.io/badge/Power-BI-F2C811)](https://powerbi.microsoft.com)

A production-ready, end-to-end Sales Data Pipeline built on **Microsoft Fabric**, covering ingestion → transformation → warehousing → reporting.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Microsoft Fabric Workspace                       │
│                                                                         │
│  ┌──────────────┐    ┌────────────────┐    ┌──────────────────────┐    │
│  │  Data Source │    │   Lakehouse    │    │   Fabric Warehouse   │    │
│  │              │───▶│  (Bronze/      │───▶│   (Gold Layer /      │    │
│  │  - CSV/API   │    │  Silver Layer) │    │   Star Schema)       │    │
│  │  - ERP/CRM   │    │                │    │                      │    │
│  │  - Blob Stor │    │  Notebooks +   │    │  Fact & Dim Tables   │    │
│  └──────────────┘    │  Delta Tables  │    │  Stored Procedures   │    │
│                      └───────┬────────┘    └──────────┬───────────┘    │
│                              │                        │                 │
│                    ┌─────────▼────────┐               │                 │
│                    │  Dataflow Gen2   │               │                 │
│                    │  (Transformations│───────────────┘                 │
│                    │   & Data Loads)  │                                 │
│                    └──────────────────┘                                 │
│                                                        │                │
│                                             ┌──────────▼───────────┐   │
│                                             │  Power BI Semantic   │   │
│                                             │  Model + Reports     │   │
│                                             │  (Sales Dashboard)   │   │
│                                             └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Medallion Architecture
| Layer | Location | Description |
|-------|----------|-------------|
| 🥉 **Bronze** | Lakehouse Files | Raw ingested data — no transformations |
| 🥈 **Silver** | Lakehouse Delta Tables | Cleaned, deduplicated, typed data |
| 🥇 **Gold** | Fabric Warehouse | Star schema, aggregations, business logic |

---

## 📁 Repository Structure

```
fabric-sales-pipeline/
├── .github/
│   └── workflows/
│       └── ci-cd.yml                  # GitHub Actions CI/CD pipeline
├── docs/
│   ├── architecture.md                # Detailed architecture guide
│   ├── setup-guide.md                 # Step-by-step setup instructions
│   └── data-dictionary.md             # Data dictionary & field descriptions
├── lakehouse/
│   ├── notebooks/
│   │   ├── 01_bronze_ingestion.ipynb  # Ingest raw data to Bronze
│   │   ├── 02_silver_transform.ipynb  # Clean & transform to Silver
│   │   └── 03_gold_load.ipynb         # Load Star Schema to Gold
│   └── scripts/
│       └── lakehouse_setup.py         # Lakehouse provisioning script
├── dataflow/
│   └── sales_dataflow.json            # Dataflow Gen2 definition (Power Query M)
├── warehouse/
│   ├── ddl/
│   │   ├── create_dimensions.sql      # Dimension table DDL
│   │   └── create_facts.sql           # Fact table DDL
│   ├── stored_procedures/
│   │   ├── sp_load_dim_customer.sql
│   │   ├── sp_load_dim_product.sql
│   │   ├── sp_load_dim_date.sql
│   │   └── sp_load_fact_sales.sql
│   └── views/
│       └── vw_sales_summary.sql       # Reporting views
├── powerbi/
│   ├── sales_dashboard.md             # Dashboard design guide & DAX measures
│   └── measures.dax                   # All DAX measures
├── data/
│   └── sample/
│       ├── sales.csv                  # Sample sales data
│       ├── customers.csv              # Sample customer data
│       └── products.csv              # Sample product data
├── infrastructure/
│   └── arm_templates/
│       └── fabric_workspace.json      # ARM template for Fabric workspace
├── utils/
│   └── generate_sample_data.py        # Sample data generator
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites
- Microsoft Fabric capacity (F2 or higher, or trial)
- Python 3.9+
- Power BI Desktop
- Azure CLI (optional, for ARM deployments)

### 1. Clone the Repository
```bash
git clone https://github.com/<your-org>/fabric-sales-pipeline.git
cd fabric-sales-pipeline
```

### 2. Generate Sample Data
```bash
pip install pandas faker
python utils/generate_sample_data.py
```

### 3. Set Up Microsoft Fabric
Follow the detailed guide in [`docs/setup-guide.md`](docs/setup-guide.md).

### 4. Upload & Run Notebooks
1. Upload notebooks from `lakehouse/notebooks/` to your Fabric workspace
2. Run in order: `01 → 02 → 03`

### 5. Configure Dataflow Gen2
Import `dataflow/sales_dataflow.json` into your Fabric workspace.

### 6. Build Power BI Report
Connect Power BI Desktop to your Fabric Warehouse and import measures from `powerbi/measures.dax`.

---

## 📊 Data Model

### Star Schema (Gold Layer)

```
          ┌─────────────────┐
          │  dim_date       │
          │  date_key (PK)  │
          └────────┬────────┘
                   │
┌────────────┐     │      ┌──────────────────┐
│dim_customer│     │      │  dim_product     │
│customer_key├─────┼──────┤  product_key(PK) │
│  (PK)      │     │      └──────────────────┘
└────────────┴─────┼───────────────────────────┐
                   │                           │
          ┌────────▼────────────────────────────▼─┐
          │            fact_sales                  │
          │  sales_key (PK)                        │
          │  date_key (FK) → dim_date              │
          │  customer_key (FK) → dim_customer      │
          │  product_key (FK) → dim_product        │
          │  region_key (FK) → dim_region          │
          │  quantity, unit_price, discount        │
          │  gross_sales, net_sales, cogs, profit  │
          └────────────────────────────────────────┘
```

---

## 🔄 Pipeline Flow

1. **Ingest** → Raw CSV/API data lands in Lakehouse Bronze layer
2. **Transform** → PySpark notebooks clean & enrich data into Silver Delta tables
3. **Load** → Dataflow Gen2 / notebooks push data to Fabric Warehouse (Gold)
4. **Aggregate** → Stored procedures populate dimension & fact tables
5. **Report** → Power BI semantic model connects to Warehouse for real-time dashboards

---

## 📈 Key KPIs Tracked

| KPI | Description |
|-----|-------------|
| Total Revenue | Gross sales across all regions |
| Net Revenue | After discounts |
| Gross Profit | Revenue minus COGS |
| Profit Margin % | Gross profit / Net revenue |
| Units Sold | Total quantity sold |
| Avg Order Value | Revenue / Order count |
| Revenue by Region | Geographic breakdown |
| Top Products | By revenue & units |
| Sales Trend | MoM & YoY growth |
| Customer Segments | RFM analysis |

---

## 🛡️ Security & Governance

- **Workspace roles**: Admin, Member, Contributor, Viewer
- **Row-level security (RLS)**: Enforced in Power BI for regional managers
- **Sensitivity labels**: Applied via Microsoft Purview
- **Data lineage**: Tracked automatically by Fabric

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m "feat: add your feature"`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📜 License

MIT License — see [LICENSE](LICENSE)
