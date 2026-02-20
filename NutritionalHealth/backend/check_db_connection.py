from api import app, db
from sqlalchemy import text

if __name__ == '__main__':
    with app.app_context():
        uri = app.config.get('SQLALCHEMY_DATABASE_URI')
        print('SQLALCHEMY_DATABASE_URI=', uri)
        using_mysql = 'mysql' in (uri or '')
        print('Using MySQL?', using_mysql)
        try:
            with db.engine.connect() as conn:
                try:
                    r = conn.execute(text('SELECT @@port AS port, DATABASE() AS db'))
                    row = r.first()
                    print('SELECT @@port, DATABASE():', row)
                except Exception as e:
                    print('Error running SELECT @@port, DATABASE():', e)
        except Exception as e:
            print('Error connecting engine:', e)
