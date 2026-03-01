from api import create_app
from models import db, FoodCategory, FoodMenu

app = create_app()

with app.app_context():
    cats = FoodCategory.query.filter_by(food_type_id=2).all()
    if not cats:
        print('No categories for food_type=2')
    else:
        print('Categories for food_type=2:')
        for c in cats:
            count = FoodMenu.query.filter_by(category_id=c.id).count()
            print(f' - id={c.id} name="{c.name}" menus={count}')

        target = None
        for c in cats:
            if c.name and 'บำรุง' in c.name:
                target = c
                break
        if not target:
            print('Could not find category containing "บำรุง"')
        else:
            print('\nListing menus for category:', target.name)
            menus = FoodMenu.query.filter_by(category_id=target.id).all()
            if not menus:
                print(' No menus found')
            else:
                for m in menus[:50]:
                    print(f' * id={m.id} name="{m.name}" is_dessert={getattr(m, "is_dessert", None)} calories={m.calories} protein={m.protein} carbs={m.carbs}')
                print(f' (printed {min(50, len(menus))} of {len(menus)})')
