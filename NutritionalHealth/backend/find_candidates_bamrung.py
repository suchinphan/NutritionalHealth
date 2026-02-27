from api import create_app
from models import db, FoodCategory, FoodMenu

KEYWORDS = ['ผัก','ผลไม้','สลัด','สลัดผลไม้','ผักสด','ผลไม้สด','ผักต้ม','ผักย่าง']

app = create_app()

with app.app_context():
    target = FoodCategory.query.filter_by(food_type_id=2).filter(FoodCategory.name.like('%บำรุง%')).first()
    if not target:
        print('Target category "บำรุง" not found')
    else:
        print('Target:', target.id, target.name)
        candidates = []
        for m in FoodMenu.query.filter_by(food_type_id=2).filter(FoodMenu.category_id!=target.id).all():
            name = (m.name or '').lower()
            if any(k in name for k in [kw.lower() for kw in KEYWORDS]):
                candidates.append(m)
        if not candidates:
            print('No candidates found with keyword heuristic')
        else:
            print(f'Found {len(candidates)} candidate menus to consider:')
            for c in candidates[:200]:
                print(f' id={c.id} name="{c.name}" current_cat={c.category_id} calories={c.calories} protein={c.protein} carbs={c.carbs}')
