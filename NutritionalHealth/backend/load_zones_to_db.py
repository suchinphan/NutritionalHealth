import pandas as pd
import sqlite3
import os
import glob
import traceback

print("=== LOADING ALL ZONES INTO DATABASE ===")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
print("BASE_DIR:", BASE_DIR)

db_path = os.path.join(BASE_DIR, "pipeline_data.db")
conn = sqlite3.connect(db_path)


# ==========================================================
# SAFE CSV READER
# ==========================================================
def read_csv_safe(file_path):
    encodings = [
        "utf-8-sig",
        "utf-16",
        "utf-16-le",
        "cp1252",
        "windows-874"
    ]

    for enc in encodings:
        try:
            print(f"   Trying encoding: {enc}")
            df = pd.read_csv(
                file_path,
                encoding=enc,
                engine="python",
                on_bad_lines="skip"
            )
            print(f"   Success with {enc}")
            return df
        except Exception:
            continue

    raise ValueError(f"Cannot read file (unknown encoding): {file_path}")


# ==========================================================
# CLEAN & FIX COLUMN NAMES
# ==========================================================
def clean_columns(df):
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
    )

    cols = pd.Series(df.columns)
    for dup in cols[cols.duplicated()].unique():
        duplicate_indexes = cols[cols == dup].index.tolist()
        for i, idx in enumerate(duplicate_indexes):
            if i == 0:
                continue
            cols[idx] = f"{dup}_{i}"

    df.columns = cols
    return df


# ==========================================================
# STANDARDIZE NUTRITION COLUMNS (IMPORTANT FIX)
# ==========================================================
def standardize_nutrition_columns(df):

    column_mapping = {
        "protein": "protein_g",
        "protein_(g)": "protein_g",
        "carbohydrates": "carbs_g",
        "carbohydrate": "carbs_g",
        "carbs": "carbs_g",
        "fat": "fat_g",
        "total_fat": "fat_g",
        "fiber": "fiber_g",
        "dietary_fiber": "fiber_g"
    }

    df = df.rename(columns=column_mapping)

    return df


# ==========================================================
# GENERIC CSV LOADER
# ==========================================================
def load_csv_to_table(file_path, table_name):
    try:
        if os.path.exists(file_path):
            print(f"\nLoading {table_name} ...")
            df = read_csv_safe(file_path)

            df = clean_columns(df)

            df.to_sql(
                table_name,
                conn,
                if_exists="replace",
                index=False
            )

            print(
                f"Loaded {table_name} | Rows: {df.shape[0]} | Columns: {df.shape[1]}"
            )
        else:
            print(f"File not found: {file_path}")

    except Exception as e:
        print(f"ERROR loading {table_name}")
        print(str(e))
        traceback.print_exc()


# ==========================================================
# RAW ZONE
# ==========================================================
print("\n========== RAW ZONE ==========")

raw_folder = os.path.join(BASE_DIR, "data", "menuallcsv")

if os.path.exists(raw_folder):

    raw_files = glob.glob(os.path.join(raw_folder, "*.csv"))

    if raw_files:
        print(f"Found {len(raw_files)} raw CSV files")

        all_dfs = []

        for f in raw_files:
            try:
                print("\nReading:", os.path.basename(f))
                df = read_csv_safe(f)
                df = clean_columns(df)
                df = standardize_nutrition_columns(df)   # ⭐ FIX ADDED HERE
                all_dfs.append(df)
            except Exception as e:
                print(f"Failed to read {f}")
                print(str(e))

        if all_dfs:
            combined_df = pd.concat(
                all_dfs,
                ignore_index=True,
                sort=False
            )

            combined_df = clean_columns(combined_df)
            combined_df = standardize_nutrition_columns(combined_df)  # ⭐ FIX

            combined_df.to_sql(
                "raw_zone",
                conn,
                if_exists="replace",
                index=False
            )

            print(
                f"\nLoaded raw_zone | Rows: {combined_df.shape[0]} | Columns: {combined_df.shape[1]}"
            )
        else:
            print("No valid CSV files could be loaded.")

    else:
        print("No CSV files found in menuallcsv")

else:
    print("menuallcsv folder not found:", raw_folder)


# ==========================================================
# STAGING ZONE
# ==========================================================
print("\n========== STAGING ZONE ==========")
load_csv_to_table(
    os.path.join(BASE_DIR, "data", "staging", "thailand_foods_staging.csv"),
    "staging_zone"
)


# ==========================================================
# CLEANSING ZONE
# ==========================================================
print("\n========== CLEANSING ZONE ==========")
load_csv_to_table(
    os.path.join(BASE_DIR, "data", "cleansing", "thailand_foods_cleaned.csv"),
    "cleansing_zone"
)


# ==========================================================
# PRESENTATION ZONE
# ==========================================================
print("\n========== PRESENTATION ZONE ==========")
load_csv_to_table(
    os.path.join(BASE_DIR, "data", "presentation", "final_dashboard_food.csv"),
    "presentation_zone"
)


# ==========================================================
# PREDICTION ZONE
# ==========================================================
print("\n========== PREDICTION ZONE ==========")
load_csv_to_table(
    os.path.join(BASE_DIR, "data", "prediction", "model_ready_food.csv"),
    "prediction_zone"
)


# ==========================================================
# FINALIZE
# ==========================================================
conn.commit()
conn.close()

print("\nAll Zones Loaded into pipeline_data.db Successfully!")
