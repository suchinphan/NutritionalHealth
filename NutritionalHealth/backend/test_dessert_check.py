from api import app, db
from sqlalchemy import text

def run_checks():
    with app.app_context():
        print('App ready')
        # print columns
        try:
            schema = db.engine.url.database
            col_q = text("SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema=:schema AND table_name='dessert_menus'")
            cols = [r[0] for r in db.session.execute(col_q, {"schema": schema}).fetchall()]
            print('Columns in dessert_menus:', cols)
        except Exception as e:
            print('Failed to read columns:', e)

        # count rows
        try:
            cnt = db.session.execute(text('SELECT COUNT(*) FROM dessert_menus')).scalar()
            print('dessert_menus row count:', cnt)
        except Exception as e:
            print('Failed to count rows:', e)

        # sample rows
        try:
            rows = db.session.execute(text('SELECT id, dessert_name, name, category FROM dessert_menus LIMIT 5')).fetchall()
            print('Sample rows:')
            for r in rows:
                print(r)
        except Exception as e:
            print('Failed to fetch sample rows:', e)

    # test endpoints via test_client
    with app.test_client() as c:
        print('\nRequest without food_type_id')
        r = c.get('/api/dessert-menus')
        print('status', r.status_code)
        try:
            print('json', r.get_json())
        except Exception:
            print('raw', r.data[:200])

        print('\nRequest with food_type_id=1')
        r = c.get('/api/dessert-menus?food_type_id=1')
        print('status', r.status_code)
        try:
            print('json', r.get_json())
        except Exception:
            print('raw', r.data[:200])

        print('\nRequest with food_type_id=3')
        r = c.get('/api/dessert-menus?food_type_id=3')
        print('status', r.status_code)
        try:
            print('json', r.get_json())
        except Exception:
            print('raw', r.data[:200])

if __name__ == '__main__':
    run_checks()
