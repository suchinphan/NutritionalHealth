from api import app, db
from sqlalchemy import text

if __name__ == '__main__':
    with app.app_context():
        try:
            with db.engine.connect() as conn:
                r = conn.execute(text('SHOW PROCESSLIST'))
                rows = r.fetchall()
                for row in rows:
                    print(row)
        except Exception as e:
            print('Error:', e)
