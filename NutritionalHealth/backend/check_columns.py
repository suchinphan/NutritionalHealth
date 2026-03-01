import os
import pandas as pd

BASE_DIR = os.path.dirname(__file__)

files = [
    "data/menuallcsv/starbucks_drinkMenu_expanded.csv",
    "data/menuallcsv/starbucks-menu-nutrition-drinks.csv",
    "data/menuallcsv/starbucks-menu-nutrition-food.csv",
    "data/menuallcsv/000Smoothie-Recipes - Sheet1.csv"
]

for file in files:
    try:
        path = os.path.join(BASE_DIR, file)
        print("Trying path:", path)
        df = pd.read_csv(path)
        print("=================================")
        print("File:", file)
        print("Columns:", df.columns.tolist())
    except Exception as e:
        print("Error reading", file, ":", e)