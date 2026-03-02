"""
generate_sample_data.py
Generates realistic sample sales data for the pipeline.
Usage: python utils/generate_sample_data.py
Output: data/sample/ (sales.csv, customers.csv, products.csv)
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
import os

fake = Faker()
random.seed(42)
np.random.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "sample")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Configuration ────────────────────────────────────────────
N_CUSTOMERS = 500
N_PRODUCTS  = 200
N_ORDERS    = 10_000
START_DATE  = datetime(2022, 1, 1)
END_DATE    = datetime(2024, 12, 31)

SEGMENTS    = ["Consumer", "Corporate", "Home Office"]
REGIONS     = ["North", "South", "East", "West", "Central"]
SHIP_MODES  = ["Standard Class", "Second Class", "First Class", "Same Day"]
CATEGORIES  = {
    "Technology":  ["Phones", "Computers", "Accessories", "Machines"],
    "Furniture":   ["Chairs", "Tables", "Bookcases", "Furnishings"],
    "Office Supplies": ["Labels", "Paper", "Binders", "Art", "Storage"],
}
BRANDS      = ["TechPro", "OfficeMax", "FurniCo", "SmartGear", "WorkDesk", "SwiftTech"]


# ── Generate Customers ───────────────────────────────────────
def generate_customers():
    print("Generating customers...")
    records = []
    for i in range(N_CUSTOMERS):
        cid = f"CUST-{i+1:05d}"
        records.append({
            "customer_id":   cid,
            "customer_name": fake.name(),
            "segment":       random.choice(SEGMENTS),
            "country":       "United States",
            "state":         fake.state(),
            "city":          fake.city(),
            "postal_code":   fake.zipcode(),
            "email":         fake.email(),
        })
    df = pd.DataFrame(records)
    df.to_csv(os.path.join(OUTPUT_DIR, "customers.csv"), index=False)
    print(f"  ✅ {len(df):,} customers saved")
    return df


# ── Generate Products ────────────────────────────────────────
def generate_products():
    print("Generating products...")
    records = []
    pid = 1
    for category, sub_cats in CATEGORIES.items():
        for sub_cat in sub_cats:
            n = N_PRODUCTS // sum(len(v) for v in CATEGORIES.values()) + 1
            for _ in range(n):
                cost = round(random.uniform(5, 400), 2)
                records.append({
                    "product_id":    f"PROD-{pid:05d}",
                    "product_name":  f"{random.choice(BRANDS)} {fake.word().title()} {sub_cat[:-1]}",
                    "category":      category,
                    "sub_category":  sub_cat,
                    "brand":         random.choice(BRANDS),
                    "standard_cost": cost,
                    "list_price":    round(cost * random.uniform(1.3, 2.5), 2),
                })
                pid += 1

    df = pd.DataFrame(records).head(N_PRODUCTS)
    df.to_csv(os.path.join(OUTPUT_DIR, "products.csv"), index=False)
    print(f"  ✅ {len(df):,} products saved")
    return df


# ── Generate Sales ───────────────────────────────────────────
def generate_sales(customers_df, products_df):
    print("Generating sales orders...")
    records = []
    date_range = (END_DATE - START_DATE).days

    for i in range(N_ORDERS):
        order_date = START_DATE + timedelta(days=random.randint(0, date_range))
        ship_days  = random.randint(1, 7)
        ship_date  = order_date + timedelta(days=ship_days)

        customer  = customers_df.sample(1).iloc[0]
        n_lines   = random.randint(1, 5)
        products  = products_df.sample(n_lines)

        order_id = f"ORD-{i+1:06d}"
        for line_num, (_, product) in enumerate(products.iterrows(), 1):
            qty        = random.randint(1, 20)
            unit_price = round(product["list_price"] * random.uniform(0.8, 1.0), 2)
            discount   = round(random.choice([0, 0, 0, 0.05, 0.10, 0.15, 0.20, 0.30]), 2)
            cogs       = round(product["standard_cost"] * qty, 2)

            records.append({
                "order_id":    order_id,
                "order_line":  line_num,
                "order_date":  order_date.strftime("%Y-%m-%d"),
                "ship_date":   ship_date.strftime("%Y-%m-%d"),
                "ship_mode":   random.choice(SHIP_MODES),
                "customer_id": customer["customer_id"],
                "product_id":  product["product_id"],
                "region":      random.choice(REGIONS),
                "quantity":    qty,
                "unit_price":  unit_price,
                "discount":    discount,
                "cogs":        cogs,
            })

    df = pd.DataFrame(records)
    df.to_csv(os.path.join(OUTPUT_DIR, "sales.csv"), index=False)
    print(f"  ✅ {len(df):,} sales lines saved")
    return df


# ── Main ─────────────────────────────────────────────────────
if __name__ == "__main__":
    print(f"\n{'='*50}")
    print("  Sales Data Generator — Microsoft Fabric Pipeline")
    print(f"{'='*50}\n")

    customers_df = generate_customers()
    products_df  = generate_products()
    sales_df     = generate_sales(customers_df, products_df)

    # Quick summary
    gross = (sales_df["quantity"] * sales_df["unit_price"]).sum()
    print(f"\n📊 Summary:")
    print(f"   Customers  : {len(customers_df):,}")
    print(f"   Products   : {len(products_df):,}")
    print(f"   Order lines: {len(sales_df):,}")
    print(f"   Gross sales: ${gross:,.2f}")
    print(f"\n✅ All files written to {os.path.abspath(OUTPUT_DIR)}/")
    print("\nNext step: Upload to Lakehouse Files/raw/ and run notebook 01_bronze_ingestion.ipynb\n")
