from api import app, db
from sqlalchemy import text

if __name__ == '__main__':
    with app.app_context():
        try:
            with db.engine.connect() as conn:
                r = conn.execute(text("SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'"))
                rows = r.fetchall()
                if not rows:
                    print('No users table or no columns returned')
                for row in rows:
                    print(row)
        except Exception as e:
            print('Error:', e)
