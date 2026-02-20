import csv
from pathlib import Path

BASE = Path(r"c:/Users/USerZ/Downloads/NutritionalHealth/NutritionalHealth/frontend/mobile/assets/csv/menuallcsv")

files = {
    'food': 'Food_Nutrition_Dataset.csv',
    'dessert': 'starbucks-menu-nutrition-food.csv',
    'smoothie': '000Smoothie-Recipes - Sheet1.csv',
    'starbucks_expanded': 'starbucks_drinkMenu_expanded.csv',
    'starbucks_nutrition_drinks': 'starbucks-menu-nutrition-drinks.csv',
}


def read_first_column(path):
    p = BASE / path
    if not p.exists():
        return []
    out = []
    with p.open(encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        rows = list(reader)
        if not rows:
            return []
        # skip header
        for r in rows[1:]:
            if not r: continue
            name = r[0].strip()
            if name:
                out.append(name)
    # dedupe preserving order
    seen = set()
    res = []
    for n in out:
        k = n.lower()
        if k not in seen:
            seen.add(k)
            res.append(n)
    return res


def test():
    print('Files exist:')
    for k,fn in files.items():
        p = BASE / fn
        print(f' - {fn}:', p.exists(), 'size=', p.stat().st_size if p.exists() else 'N/A')
    
    food_names = read_first_column(files['food'])
    print('\nFood_Nutrition_Dataset.csv: {} items (sample 10)'.format(len(food_names)))
    print(food_names[:10])

    dessert = read_first_column(files['dessert'])
    print('\nstarbucks-menu-nutrition-food.csv: {} items (sample 10)'.format(len(dessert)))
    print(dessert[:10])

    smoothie = read_first_column(files['smoothie'])
    print('\n000Smoothie-Recipes - Sheet1.csv: {} items (sample 10)'.format(len(smoothie)))
    print(smoothie[:10])

    starb = read_first_column(files['starbucks_expanded'])
    print('\nstarbucks_drinkMenu_expanded.csv: {} items (sample 10)'.format(len(starb)))
    print(starb[:10])

    # emulate loadProteinMenus from Food_Nutrition_Dataset.csv
    def load_protein():
        p = BASE / files['food']
        out = []
        with p.open(encoding='utf-8', errors='replace') as f:
            reader = csv.reader(f)
            rows = list(reader)
            if not rows: return []
            header = [h.strip().lower() for h in rows[0]]
            name_idx = next((i for i,h in enumerate(header) if 'food_name' in h or 'name' in h), 0)
            prot_idx = next((i for i,h in enumerate(header) if 'protein' in h), -1)
            carb_idx = next((i for i,h in enumerate(header) if 'carb' in h), -1)
            fat_idx = next((i for i,h in enumerate(header) if 'fat' in h), -1)
            for r in rows[1:]:
                if len(r) <= name_idx: continue
                name = r[name_idx].strip()
                try:
                    prot = float(r[prot_idx]) if prot_idx >=0 and prot_idx < len(r) and r[prot_idx].strip()!='' else 0
                except:
                    prot = 0
                try:
                    carb = float(r[carb_idx]) if carb_idx >=0 and carb_idx < len(r) and r[carb_idx].strip()!='' else 0
                except:
                    carb = 0
                try:
                    fat = float(r[fat_idx]) if fat_idx >=0 and fat_idx < len(r) and r[fat_idx].strip()!='' else 0
                except:
                    fat = 0
                if prot >= carb and prot >= fat:
                    out.append(name)
        # dedupe
        seen=set(); res=[]
        for n in out:
            k=n.lower().strip()
            if k and k not in seen:
                seen.add(k); res.append(n)
        return res

    prot_list = load_protein()
    print('\nloadProteinMenus -> {} items (sample 10)'.format(len(prot_list)))
    print(prot_list[:10])

if __name__ == '__main__':
    test()
