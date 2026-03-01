from api import create_app
from models import db, FoodCategory, FoodMenu

KEYWORDS = ['ผัก','ผลไม้','สลัด','สลัดผลไม้','ผักสด','ผลไม้สด','ผักต้ม','ผักย่าง',
            'yogurt','kefir','soup','สตูว์','fish','salad','egg','chicken','meat','stew',
            'smoothie','juice','fruit','vegan','nuts','milk','potato','rice']

app = create_app()

with app.app_context():
    target = FoodCategory.query.filter_by(food_type_id=2).filter(FoodCategory.name.like('%บำรุง%')).first()
    if not target:
        print('Target category "บำรุง" not found')
    else:
        print('Target:', target.id, target.name)
        candidates = []
        all_menus = FoodMenu.query.filter_by(food_type_id=2).all()
        for m in all_menus:
            if m.category_id == target.id:
                continue
            name = (m.name or '').lower()
            prot = (m.protein or 0)
            cal = (m.calories or 0)
            carbs = (m.carbs or 0)
            # Exclude explicit desserts if flagged
            if getattr(m, 'is_dessert', None) in (1, True):
                continue
            # Broad nutrient heuristic (more inclusive)
            nutrient_match = (30 <= cal <= 800 and 1 <= prot <= 30)
            keyword_match = any(kw.lower() in name for kw in KEYWORDS)
            if nutrient_match or keyword_match:
                candidates.append(m)
        if not candidates:
            print('No extended candidates found')
        else:
            print(f'Found {len(candidates)} extended candidates:')
            for c in candidates[:200]:
                print(f' id={c.id} name="{c.name}" current_cat={c.category_id} calories={c.calories} protein={c.protein} carbs={c.carbs}')
