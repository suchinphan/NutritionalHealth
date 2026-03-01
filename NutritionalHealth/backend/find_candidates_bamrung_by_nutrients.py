from api import create_app
from models import db, FoodCategory, FoodMenu

app = create_app()

with app.app_context():
    target = FoodCategory.query.filter_by(food_type_id=2).filter(FoodCategory.name.like('%บำรุง%')).first()
    if not target:
        print('Target category "บำรุง" not found')
    else:
        print('Target:', target.id, target.name)
        candidates = []
        for m in FoodMenu.query.filter_by(food_type_id=2).filter(FoodMenu.category_id!=target.id).all():
            prot = (m.protein or 0)
            cal = (m.calories or 0)
            # heuristic: moderate calories and moderate protein -> "บำรุง"
            if 50 <= cal <= 400 and 3 <= prot <= 15:
                candidates.append(m)
        if not candidates:
            print('No candidates found with nutrient heuristic')
        else:
            print(f'Found {len(candidates)} nutrient-based candidate menus:')
            for c in candidates[:200]:
                print(f' id={c.id} name="{c.name}" current_cat={c.category_id} calories={c.calories} protein={c.protein} carbs={c.carbs}')
