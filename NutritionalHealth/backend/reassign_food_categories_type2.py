from import_foods import load_category_map, detect_category_id
from api import create_app
from models import db, FoodMenu

app = create_app()

with app.app_context():
    category_map = load_category_map()
    cat_map_for_type = category_map.get(2, {})
    if not cat_map_for_type:
        print('No categories for food_type 2 found; abort')
    else:
        updated = 0
        total = 0
        for f in FoodMenu.query.filter_by(food_type_id=2).all():
            total += 1
            new_cat = detect_category_id(2, f.protein, f.calories, category_map)
            if new_cat and f.category_id != new_cat:
                f.category_id = new_cat
                updated += 1
        try:
            db.session.commit()
            print(f'Updated {updated} of {total} food_menus for food_type=2')
        except Exception as e:
            db.session.rollback()
            print('DB commit failed:', e)
