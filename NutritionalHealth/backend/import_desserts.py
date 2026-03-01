import os
import pandas as pd
from datetime import datetime
from api import create_app, db
from models import DessertMenu
from sqlalchemy import text

app = create_app()

CSV_PATH = os.path.join(
    os.path.dirname(__file__),
    "data",
    "menuallcsv",
    "Food_Nutrition_Dataset.csv"
)

# =========================
# keyword ของหวาน (EN + TH)
# =========================
DESSERT_KEYWORDS = [
    # English
    "cake", "pie", "pudding", "ice cream", "dessert",
    "sweet", "chocolate", "cookie", "brownie",
    "custard", "cupcake", "tart",

    # Thai
    "ขนม", "เค้ก", "บัวลอย", "ทองหยิบ", "ทองหยอด",
    "ฝอยทอง", "โรตี", "เครป", "วาฟเฟิล",
    "ไอศกรีม", "พุดดิ้ง", "ข้าวเหนียวมะม่วง"
]


def safe_float(val):
    try:
        if pd.isna(val) or val == "":
            return None
        return float(val)
    except Exception:
        return None


def is_dessert(name: str) -> bool:
    name = name.lower()
    return any(k in name for k in DESSERT_KEYWORDS)


def main():
    with app.app_context():

        print(f"📥 Loading dessert names from {CSV_PATH}")

        if not os.path.exists(CSV_PATH):
            print("❌ CSV file not found")
            return

        df = pd.read_csv(CSV_PATH)
        df.columns = df.columns.str.strip()

        # detect whether DB column is `name` (new) or `dessert_name` (legacy)
        schema = db.engine.url.database
        q = text(f"SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema='{schema}' AND table_name='dessert_menus'")
        cols = {r[0] for r in db.session.execute(q).fetchall()}

        use_name_col = 'name' in cols

        desserts_to_insert = []
        raw_inserts = []
        inserted = 0
        skipped = 0

        if use_name_col:
            existing_names = {
                name.lower()
                for (name,) in db.session.query(DessertMenu.name).all()
                if name
            }
        else:
            res = db.session.execute(text("SELECT dessert_name FROM dessert_menus"))
            existing_names = {row[0].lower() for row in res.fetchall() if row[0]}

        for _, row in df.iterrows():
            food_name = str(row.get("food_name", "")).strip()

            if not food_name:
                skipped += 1
                continue

            if not is_dessert(food_name):
                skipped += 1
                continue

            if food_name.lower() in existing_names:
                skipped += 1
                continue

            if use_name_col:
                desserts_to_insert.append(
                    DessertMenu(
                        name=food_name,
                        category="dessert",
                        calories=safe_float(row.get("calories")),
                        protein_g=safe_float(row.get("protein")),
                        carbs_g=safe_float(row.get("carbs")),
                        fat_g=safe_float(row.get("fat")),
                        fiber_g=None,
                        sugar_g=None,
                        iron=None,
                        vitamin_c=None,
                        created_at=datetime.utcnow()
                    )
                )
            else:
                raw_inserts.append({
                    'dessert_name': food_name,
                    'category': 'dessert',
                    'calories': safe_float(row.get('calories')),
                    'protein_g': safe_float(row.get('protein')),
                    'carbs_g': safe_float(row.get('carbs')),
                    'fat_g': safe_float(row.get('fat')),
                    'fiber_g': None,
                    'sugar_g': None,
                    'iron': None,
                    'vitamin_c': None,
                    'created_at': datetime.utcnow()
                })

            existing_names.add(food_name.lower())
            inserted += 1

        try:
            if use_name_col:
                if desserts_to_insert:
                    db.session.bulk_save_objects(desserts_to_insert)
                    db.session.commit()
            else:
                if raw_inserts:
                    insert_sql = text(
                        "INSERT INTO dessert_menus (dessert_name, category, calories, protein_g, carbs_g, fat_g, fiber_g, sugar_g, iron, vitamin_c, created_at) "
                        "VALUES (:dessert_name, :category, :calories, :protein_g, :carbs_g, :fat_g, :fiber_g, :sugar_g, :iron, :vitamin_c, :created_at)"
                    )
                    for params in raw_inserts:
                        db.session.execute(insert_sql, params)
                    db.session.commit()

            print("================================")
            print(f"✅ Inserted desserts : {inserted}")
            print(f"⏭️ Skipped : {skipped}")
            print("================================")

        except Exception as e:
            db.session.rollback()
            print("❌ DB commit failed:", e)


if __name__ == "__main__":
    main()