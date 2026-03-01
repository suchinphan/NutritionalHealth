from api import create_app
from models import db, FoodCategory, FoodMenu

# Top15 IDs selected earlier
TOP15_IDS = [60,50,95,51,96,103,101,46,105,85,120,88,87,10,98]

app = create_app()

with app.app_context():
    target = FoodCategory.query.filter_by(food_type_id=2).filter(FoodCategory.name.like('%บำรุง%')).first()
    if not target:
        print('Target category "บำรุง" not found; aborting')
    else:
        print('Target:', target.id, target.name)
        moved = 0
        for mid in TOP15_IDS:
            m = FoodMenu.query.get(mid)
            if not m:
                print(' - not found id=', mid)
                continue
            if m.category_id == target.id:
                print(f' - id={mid} already in target')
                continue
            print(f' - moving id={mid} "{m.name}" from cat={m.category_id} to {target.id}')
            m.category_id = target.id
            moved += 1
        try:
            db.session.commit()
            print(f'Committed. Moved {moved} items.')
        except Exception as e:
            db.session.rollback()
            print('DB commit failed:', e)
