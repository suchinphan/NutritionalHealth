from api import app
from models import FoodMenu, FoodCategory, FoodType, DessertMenu, DrinkMenu, DrinkType

with app.app_context():
    from sqlalchemy import func
    from models import db

    total = db.session.query(func.count(FoodMenu.id)).scalar()
    print('food_menus total =', total)

    counts_by_type = db.session.query(FoodMenu.food_type_id, func.count(FoodMenu.id)).group_by(FoodMenu.food_type_id).all()
    print('counts by food_type_id:')
    for ftid, cnt in counts_by_type:
        print(' ', ftid, cnt)

    print('\nSample food_menus (limit 20):')
    for f in FoodMenu.query.limit(20).all():
        print(f.id, f.name, 'type=', f.food_type_id, 'cat=', f.category_id, 'is_dessert=', f.is_dessert)

    print('\nFood categories:')
    for c in FoodCategory.query.all():
        print(c.id, c.name, 'food_type_id=', c.food_type_id)

    print('\nDesserts count:', db.session.query(func.count(DessertMenu.id)).scalar())
    print('Drink menus count:', db.session.query(func.count(DrinkMenu.id)).scalar())
    print('Drink types:')
    for dt in DrinkType.query.all():
        print(dt.id, dt.name)
