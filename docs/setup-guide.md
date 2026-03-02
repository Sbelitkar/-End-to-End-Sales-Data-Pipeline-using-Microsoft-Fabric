# 📋 Setup Guide — End-to-End Sales Data Pipeline on Microsoft Fabric

## Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Create Microsoft Fabric Workspace](#2-create-microsoft-fabric-workspace)
3. [Create the Lakehouse](#3-create-the-lakehouse)
4. [Upload Sample Data](#4-upload-sample-data)
5. [Run PySpark Notebooks](#5-run-pyspark-notebooks)
6. [Configure Dataflow Gen2](#6-configure-dataflow-gen2)
7. [Set Up Fabric Warehouse](#7-set-up-fabric-warehouse)
8. [Build Power BI Report](#8-build-power-bi-report)
9. [Schedule the Pipeline](#9-schedule-the-pipeline)
10. [Set Up GitHub Repository](#10-set-up-github-repository)

---

## 1. Prerequisites

| Requirement | Details |
|-------------|---------|
| Microsoft Fabric | Trial or F2+ capacity |
| Azure subscription | For Fabric provisioning |
| Python 3.9+ | For data generation |
| Power BI Desktop | August 2023 or later |
| Git | For source control |

---

## 2. Create Microsoft Fabric Workspace

1. Go to [app.fabric.microsoft.com](https://app.fabric.microsoft.com)
2. Click **Workspaces** → **New workspace**
3. Name it: `sales-pipeline-workspace`
4. Assign your **Fabric capacity** (trial or purchased)
5. Click **Apply**

---

## 3. Create the Lakehouse

1. In your workspace, click **New** → **Lakehouse**
2. Name it: `sales_lakehouse`
3. Once created, you'll see:
   - **Files** — unmanaged files (Bronze zone)
   - **Tables** — Delta tables (Silver zone)
4. Create these folders inside **Files**:
   ```
   Files/
   ├── raw/
   │   ├── sales/
   │   ├── customers/
   │   └── products/
   ├── bronze/
   └── logs/
   ```

---

## 4. Upload Sample Data

### 4a. Generate sample data locally
```bash
git clone https://github.com/<your-org>/fabric-sales-pipeline.git
cd fabric-sales-pipeline
pip install pandas faker numpy
python utils/generate_sample_data.py
```
This creates `data/sample/sales.csv`, `customers.csv`, `products.csv`.

### 4b. Upload to Lakehouse
1. In the Lakehouse UI, navigate to `Files/raw/sales/`
2. Click **Upload** → **Upload files**
3. Select `data/sample/sales.csv`
4. Repeat for `customers/` and `products/` folders

---

## 5. Run PySpark Notebooks

### 5a. Import notebooks
1. In your workspace, click **New** → **Import notebook**
2. Import all three notebooks from `lakehouse/notebooks/`:
   - `01_bronze_ingestion.ipynb`
   - `02_silver_transform.ipynb`
   - `03_gold_load.ipynb`

### 5b. Attach Lakehouse to each notebook
1. Open each notebook
2. In the **Explorer** pane, click **+ Add** → **Existing Lakehouse**
3. Select `sales_lakehouse`

### 5c. Update configuration
In `03_gold_load.ipynb`, update:
```python
WAREHOUSE_CONN = "<your-fabric-warehouse-jdbc-connection-string>"
```
Find your connection string in: Warehouse → Settings → Connection strings → **JDBC endpoint**

### 5d. Run notebooks in order
1. Open `01_bronze_ingestion.ipynb` → **Run All**
2. Verify Bronze Delta tables written successfully
3. Open `02_silver_transform.ipynb` → **Run All**
4. Open `03_gold_load.ipynb` → **Run All**

---

## 6. Configure Dataflow Gen2

Dataflow Gen2 provides a low-code/no-code alternative for transformations.

### 6a. Create Dataflow
1. In your workspace, click **New** → **Dataflow Gen2**
2. Name it: `sales_dataflow`

### 6b. Import Dataflow definition
1. Go to **Home** → **Import** → **Import from JSON**
2. Upload `dataflow/sales_dataflow.json`

### 6c. Configure data destination
1. For each query (Sales, Customers, Products):
   - Click **+** → **Add data destination** → **Fabric Warehouse**
   - Select your warehouse and target table
2. Set **Update method** to `Replace` for dimensions, `Append` for facts

### 6d. Publish the Dataflow
Click **Publish** — Dataflow Gen2 will immediately validate and save.

---

## 7. Set Up Fabric Warehouse

### 7a. Create the Warehouse
1. In your workspace, click **New** → **Warehouse**
2. Name it: `sales_warehouse`

### 7b. Run DDL scripts
Open the Warehouse SQL editor:

1. **Create dimensions:**
   - Paste contents of `warehouse/ddl/create_dimensions.sql`
   - Click **Run**

2. **Create fact table:**
   - Paste contents of `warehouse/ddl/create_facts.sql`
   - Click **Run**

3. **Create stored procedures:**
   - Paste each file from `warehouse/stored_procedures/`
   - Click **Run**

4. **Create views:**
   - Paste `warehouse/views/vw_sales_summary.sql`
   - Click **Run**

### 7c. Verify with sample query
```sql
SELECT COUNT(*) AS total_orders FROM dbo.fact_sales;
SELECT * FROM dbo.vw_monthly_sales WHERE year = 2024 ORDER BY yyyymm;
```

---

## 8. Build Power BI Report

### 8a. Connect Power BI Desktop to Fabric Warehouse
1. Open Power BI Desktop
2. Click **Get Data** → **Microsoft Fabric** → **Warehouse**
3. Enter your workspace and select `sales_warehouse`
4. Select tables: `fact_sales`, `dim_customer`, `dim_product`, `dim_date`, `dim_region`

### 8b. Build the Data Model
1. In **Model view**, verify relationships:
   - `fact_sales[date_key]` → `dim_date[date_key]`
   - `fact_sales[customer_key]` → `dim_customer[customer_key]`
   - `fact_sales[product_key]` → `dim_product[product_key]`
   - `fact_sales[region_key]` → `dim_region[region_key]`

### 8c. Import DAX Measures
1. Open **DAX Studio** (free download)
2. Connect to your Power BI model
3. Open `powerbi/measures.dax`
4. Execute to create all measures

### 8d. Build Dashboard Pages
| Page | Visuals |
|------|---------|
| **Executive Summary** | KPI cards, Revenue trend line, Profit margin gauge |
| **Sales by Region** | Map visual, Bar chart by region |
| **Product Performance** | Matrix: category × revenue, Top 10 bar chart |
| **Customer Analysis** | RFM scatter, Customer segment donut |
| **Time Analysis** | YoY comparison, QTD waterfall |

### 8e. Publish to Fabric
1. Click **Publish** → Select `sales-pipeline-workspace`
2. The report auto-connects to the Warehouse semantic model

---

## 9. Schedule the Pipeline

### 9a. Create a Fabric Data Pipeline
1. In workspace: **New** → **Data pipeline**
2. Name: `sales_daily_pipeline`
3. Add activities in sequence:

```
[Notebook: 01_bronze_ingestion]
         ↓
[Notebook: 02_silver_transform]
         ↓
[Notebook: 03_gold_load]
         ↓
[Stored Procedure: sp_load_fact_sales]
```

### 9b. Schedule
1. Click **Schedule** → Enable schedule
2. Set: **Daily at 02:00 UTC**
3. Click **Apply**

---

## 10. Set Up GitHub Repository

### 10a. Create GitHub repository
```bash
# Create repo on GitHub: github.com/new
# Name: fabric-sales-pipeline

cd fabric-sales-pipeline
git init
git add .
git commit -m "feat: initial project setup — End-to-End Sales Pipeline on Microsoft Fabric"
git branch -M main
git remote add origin https://github.com/<your-org>/fabric-sales-pipeline.git
git push -u origin main
```

### 10b. Set up GitHub Secrets
Go to **Settings → Secrets → Actions → New repository secret**:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | Azure service principal JSON |
| `FABRIC_WORKSPACE_ID` | Your Fabric workspace GUID |
| `FABRIC_WAREHOUSE_ID` | Your Fabric warehouse GUID |
| `FABRIC_PIPELINE_ID` | Your Fabric pipeline GUID |
| `FABRIC_CLIENT_ID` | Azure AD app registration client ID |
| `FABRIC_TENANT_ID` | Your Azure tenant ID |

### 10c. Create Azure Service Principal
```bash
az ad sp create-for-rbac \
  --name "fabric-pipeline-sp" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```
Copy the JSON output → paste as `AZURE_CREDENTIALS` secret.

### 10d. Enable Fabric Workspace Git Integration
1. Workspace → **Workspace settings** → **Git integration**
2. Connect to GitHub → select your repository
3. Branch: `main`
4. This syncs notebooks, pipelines, and dataflows automatically!

---

## ✅ Verification Checklist

- [ ] Lakehouse created with Bronze/Silver/Gold structure
- [ ] Sample data uploaded to `Files/raw/`
- [ ] All 3 notebooks run successfully
- [ ] Warehouse tables created and populated
- [ ] Power BI report connects and shows data
- [ ] Daily pipeline scheduled
- [ ] GitHub Actions CI/CD passing
- [ ] Git integration enabled on Fabric workspace
