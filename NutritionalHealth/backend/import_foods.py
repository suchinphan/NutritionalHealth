import os
import pandas as pd
from api import create_app, db
from models import FoodMenu, FoodCategory

app = create_app()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(
    BASE_DIR,
    "data",
    "menuallcsv",
    "Food_Nutrition_Dataset.csv"
)

# -------------------------
# helper functions
# -------------------------

def safe_float(val):
    try:
        if pd.isna(val) or val == "":
            return None
        return float(val)
    except Exception:
        return None


def is_real_food(name: str) -> bool:
    name = name.lower()
    dessert_keywords = [
        "cake", "candy", "sweet", "dessert", "ice cream",
        "cookie", "pie", "pudding", "syrup", "chocolate",
        "candied", "sugar", "icing", "frosting", "jam",
        "jelly", "caramel", "custard", "donut", "brownie"
    ]
    return not any(k in name for k in dessert_keywords)


# -------------------------
# food_type logic
# -------------------------
# 1 = เมนูโปรตีน
# 2 = เมนูผักและผลไม้
# 3 = เมนูคาร์โบไฮเดรต
def detect_food_type(protein, carbs):
    protein = protein or 0
    carbs = carbs or 0

    if protein >= 10 and protein > carbs:
        return 1
    elif carbs >= 20 and carbs > protein:
        return 3
    else:
        return 2


# -------------------------
# category logic (ผูกกับ food_type_id)
# -------------------------
def load_category_map():
    """
    return:
    {
      food_type_id: {
        category_name: category_id
      }
    }
    """
    cats = FoodCategory.query.all()
    cat_map = {}

    for c in cats:
        ft = c.food_type_id
        if ft not in cat_map:
            cat_map[ft] = {}
        cat_map[ft][c.name.strip()] = c.id

    return cat_map


def detect_category_id(food_type_id, protein, calories, cat_map):
    protein = protein or 0
    calories = calories or 0

    categories = cat_map.get(food_type_id, {})

    # อาหารลดน้ำหนัก
    # Heuristics:
    # - protein-high -> 'อาหารสร้างกล้ามเนื้อ' (for food_type 1)
    # - calories-high -> 'อาหารให้พลังงานสูง' (for food_type 3)
    # - low-calories -> 'อาหารลดน้ำหนัก' (reduced threshold)
    # - default -> 'อาหารครบ5หมู่'

    # 1) protein-based (muscle foods)
    if food_type_id == 1 and protein >= 15 and "อาหารสร้างกล้ามเนื้อ" in categories:
        return categories["อาหารสร้างกล้ามเนื้อ"]

    # 2) high calorie -> high energy (carb type)
    if food_type_id == 3 and calories >= 400 and "อาหารให้พลังงานสูง" in categories:
        return categories["อาหารให้พลังงานสูง"]

    # 3) weight loss (use a tighter threshold to avoid catching light fruits/veg)
    if calories is not None and calories <= 100 and "อาหารลดน้ำหนัก" in categories:
        return categories["อาหารลดน้ำหนัก"]

    # 4) default: prefer 'อาหารครบ5หมู่' when present
    if "อาหารครบ5หมู่" in categories:
        return categories["อาหารครบ5หมู่"]

    # 5) as last resort, if any category exists, return one
    return next(iter(categories.values()), None)


# -------------------------
# main
# -------------------------
with app.app_context():

    print("📥 Loading Food_Nutrition_Dataset.csv")
    print("📂 Path:", CSV_PATH)

    if not os.path.exists(CSV_PATH):
        print("❌ CSV not found")
        exit()

    df = pd.read_csv(CSV_PATH)
    df.columns = df.columns.str.strip()
    print("📊 Columns:", df.columns.tolist())

    category_map = load_category_map()

    existing_names = {
        name.lower().strip()
        for (name,) in db.session.query(FoodMenu.name).all()
        if name
    }

    inserted = skipped = skipped_dessert = 0

    for _, row in df.iterrows():

        food_name = str(row.get("food_name", "")).strip()
        if not food_name:
            skipped += 1
            continue

        if not is_real_food(food_name):
            skipped_dessert += 1
            continue

        if food_name.lower() in existing_names:
            skipped += 1
            continue

        calories = safe_float(row.get("calories"))
        protein = safe_float(row.get("protein"))
        carbs = safe_float(row.get("carbs"))
        fat = safe_float(row.get("fat"))

        food_type_id = detect_food_type(protein, carbs)
        category_id = detect_category_id(
            food_type_id,
            protein,
            calories,
            category_map
        )

        food = FoodMenu(
            name=food_name,
            food_type_id=food_type_id,
            category_id=category_id,
            calories=calories,
            protein=protein,
            carbs=carbs,
            fat=fat,
            is_dessert=False
        )

        db.session.add(food)
        existing_names.add(food_name.lower())
        inserted += 1

    try:
        db.session.commit()
        print("===================================")
        print(f"✅ Inserted food menus : {inserted}")
        print(f"⏭️ Skipped duplicate/invalid : {skipped}")
        print(f"🍰 Skipped dessert-like items : {skipped_dessert}")
        print("===================================")
    except Exception as e:
        db.session.rollback()
        print("❌ ERROR:", e)