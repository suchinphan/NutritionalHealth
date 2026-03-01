import os
import pandas as pd
from api import create_app, db
from models import DrinkMenu, DrinkType

app = create_app()

BASE_DIR = os.path.dirname(__file__)
CSV_PATH = os.path.join(
    BASE_DIR,
    "data",
    "menuallcsv",
    "starbucks_drinkMenu_expanded.csv"
)

# -------------------------
# helpers
# -------------------------

def clean_number(val):
    try:
        if pd.isna(val) or val == "":
            return None
        return float(str(val).strip())
    except Exception:
        return None


def clean_percent(val):
    try:
        if pd.isna(val) or val == "":
            return None
        return float(str(val).replace('%', '').strip())
    except Exception:
        return None


# -------------------------
# DRINK TYPE MAPPING
# -------------------------

def map_drink_type(name: str, category: str):
    name = name.lower()
    category = category.lower()

    if any(k in name for k in [
        "low", "light", "zero", "diet", "skinny", "sugar-free", "no sugar"
    ]):
        return "เครื่องดื่มลดน้ำหนัก"

    if any(k in category for k in [
        "tea", "herbal", "juice", "smoothie"
    ]):
        return "เครื่องดื่มเพื่อสุขภาพ"

    if any(k in category for k in [
        "coffee", "espresso", "frappuccino", "cold brew", "shaken"
    ]):
        return "เครื่องดื่มเพิ่มพลังงาน"

    # fallback
    return "เครื่องดื่มทั่วไป"


# -------------------------
# main
# -------------------------

def run():
    with app.app_context():

        if not os.path.exists(CSV_PATH):
            print("❌ CSV not found:", CSV_PATH)
            return

        df = pd.read_csv(CSV_PATH)
        df.columns = df.columns.str.strip()

        # preload drink types
        drink_types = {
            dt.name: dt for dt in DrinkType.query.all()
        }

        existing_names = {
            name.lower()
            for (name,) in db.session.query(DrinkMenu.name).all()
            if name
        }

        inserted = 0
        skipped = 0

        try:
            for _, row in df.iterrows():

                name = str(row.get("Beverage", "")).strip()
                category = str(row.get("Beverage_category", "")).strip()

                if not name or name.lower() in existing_names:
                    skipped += 1
                    continue

                drink_type_name = map_drink_type(name, category)

                if drink_type_name not in drink_types:
                    drink_type = DrinkType(name=drink_type_name)
                    db.session.add(drink_type)
                    db.session.flush()  # get id without commit
                    drink_types[drink_type_name] = drink_type
                else:
                    drink_type = drink_types[drink_type_name]

                drink = DrinkMenu(
                    name=name,
                    drink_type_id=drink_type.id,
                    calories=clean_number(row.get("Calories")),
                    sugar_g=clean_number(row.get("Sugars (g)")),
                    protein_g=clean_number(row.get("Protein (g)")),
                    iron=clean_percent(row.get("Iron (% DV)")),
                    vitamin_c=clean_percent(row.get("Vitamin C (% DV)")),
                )

                db.session.add(drink)
                existing_names.add(name.lower())
                inserted += 1

            db.session.commit()

            print("================================")
            print(f"✅ Inserted drinks : {inserted}")
            print(f"⏭️ Skipped         : {skipped}")
            print("================================")

        except Exception as e:
            db.session.rollback()
            print("❌ ERROR importing drinks:", e)


if __name__ == "__main__":
    run()
