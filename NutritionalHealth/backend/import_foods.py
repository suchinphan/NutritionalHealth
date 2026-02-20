import pandas as pd
from api import app, db
from models import FoodMenu

with app.app_context():

    print("📥 กำลังอ่านไฟล์ CSV...")
    df = pd.read_csv("presentation/cleaned_food.csv")

    df.columns = df.columns.str.strip()
    print("🔎 คอลัมน์ที่พบ:", df.columns)

    count = 0

    for _, row in df.iterrows():

        food_name = row["th_name"]  # ใช้ชื่อไทย

        food = FoodMenu(
            category_id=1,   # ✅ สำคัญมาก
            name=food_name,
            calories=0,
            protein=0,
            carbs=0,
            fat=0
        )

        db.session.add(food)
        count += 1

    db.session.commit()

    print(f"🎉 Import สำเร็จ {count} รายการ")
