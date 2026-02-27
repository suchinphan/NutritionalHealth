from api import create_app
from models import db, FoodCategory, FoodMenu

app = create_app()
with app.app_context():
    cats = FoodCategory.query.filter_by(food_type_id=2).all()
    print('categories for food_type=2:')
    for c in cats:
        cnt = db.session.query(FoodMenu).filter_by(category_id=c.id).count()
        print(c.id, c.name, '->', cnt, 'menus')

    target = FoodCategory.query.filter_by(food_type_id=2, name='อาหารครบ5หมู่').first()
    if target:
        print('\nSample menus for category id', target.id)
        menus = FoodMenu.query.filter_by(category_id=target.id).limit(50).all()
        for m in menus:
            print(m.id, m.name, 'type=', m.food_type_id)
    else:
        print('\nNo category named อาหารครบ5หมู่ for food_type=2')
