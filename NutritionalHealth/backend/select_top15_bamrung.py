from api import create_app
from models import db, FoodCategory, FoodMenu

KEYWORDS = ['ผัก','ผลไม้','สลัด','สลัดผลไม้','ผักสด','ผลไม้สด','ผักต้ม','ผักย่าง',
            'yogurt','kefir','soup','สตูว์','fish','salad','egg','chicken','meat','stew',
            'smoothie','juice','fruit','vegan','nuts','milk','potato','rice']

app = create_app()

def score_menu(m):
    name = (m.name or '').lower()
    prot = (m.protein or 0)
    cal = (m.calories or 0)
    keyword = any(kw.lower() in name for kw in KEYWORDS)
    nutrient = (30 <= cal <= 800 and 1 <= prot <= 30)
    score = 0
    if keyword:
        score += 3
    if nutrient:
        score += 1
    score += min(prot, 10) * 0.1
    # prefer moderate calories (~100-200)
    score -= abs(150 - cal) / 300.0
    return score

with app.app_context():
    target = FoodCategory.query.filter_by(food_type_id=2).filter(FoodCategory.name.like('%บำรุง%')).first()
    if not target:
        print('Target category "บำรุง" not found')
    else:
        all_menus = FoodMenu.query.filter_by(food_type_id=2).filter(FoodMenu.category_id!=target.id).all()
        candidates = []
        for m in all_menus:
            if getattr(m, 'is_dessert', None) in (1, True):
                continue
            s = score_menu(m)
            if s > -10:
                candidates.append((s, m))
        candidates.sort(key=lambda x: x[0], reverse=True)
        top = candidates[:15]
        print('Top 15 candidates for อาหารบำรุงสุขภาพ:')
        for s, m in top:
            print(f'id={m.id} score={s:.2f} name="{m.name}" current_cat={m.category_id} calories={m.calories} protein={m.protein} carbs={m.carbs}')
