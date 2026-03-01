from api import create_app
from models import db, DrinkType, DrinkMenu

app = create_app()

with app.app_context():
    types = DrinkType.query.all()
    print('Drink types:')
    for t in types:
        cnt = DrinkMenu.query.filter_by(drink_type_id=t.id).count()
        print(f' - id={t.id} name="{t.name}" menus={cnt}')

    print('\nSample menus per type:')
    for t in types:
        print(f'\nType {t.id} {t.name}:')
        menus = DrinkMenu.query.filter_by(drink_type_id=t.id).limit(20).all()
        if not menus:
            print('  (no menus)')
        else:
            for m in menus:
                print(f'  id={m.id} name="{m.name}" calories={m.calories}')
