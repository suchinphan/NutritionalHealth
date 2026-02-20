import os
from sqlalchemy import create_engine, MetaData, Table, select, text
from urllib.parse import quote_plus

DB_PATH = os.path.join(os.path.dirname(__file__), 'data.db')

def get_mysql_uri():
    user = os.environ.get('MYSQL_USER')
    pw = os.environ.get('MYSQL_PASS')
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    port = os.environ.get('MYSQL_PORT', '3306')
    db = os.environ.get('MYSQL_DB')
    if not all([user, pw, db]):
        raise RuntimeError('Please set MYSQL_USER, MYSQL_PASS and MYSQL_DB environment variables')
    # URL-encode the password to safely include special characters like '@' or '!'
    pw_quoted = quote_plus(pw)
    return f'mysql+pymysql://{user}:{pw_quoted}@{host}:{port}/{db}?charset=utf8mb4'

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Migrate users from local SQLite to MySQL')
    parser.add_argument('--preview', action='store_true', help='Show users that would be migrated and exit')
    parser.add_argument('--preserve-ids', action='store_true', help='Preserve original SQLite ids when inserting into MySQL')
    args = parser.parse_args()

    sqlite_uri = f'sqlite:///{DB_PATH}'
    print('Connecting to SQLite:', sqlite_uri)
    sqlite_engine = create_engine(sqlite_uri)

    mysql_uri = get_mysql_uri()
    print('Connecting to MySQL:', mysql_uri)
    mysql_engine = create_engine(mysql_uri)

    meta_sqlite = MetaData()
    meta_mysql = MetaData()

    users_sqlite = Table('users', meta_sqlite, autoload_with=sqlite_engine)
    users_mysql = Table('users', meta_mysql, autoload_with=mysql_engine)

    with sqlite_engine.connect() as sconn, mysql_engine.connect() as mconn:
        rows = sconn.execute(select(users_sqlite)).fetchall()
        print(f'Found {len(rows)} users in SQLite')
        if not rows:
            return
        # Build a preview list
        preview_list = []
        for r in rows:
            try:
                d = dict(r._mapping)
            except Exception:
                d = dict(r)
            preview_list.append({'username': d.get('username'), 'email': d.get('email'), 'id': d.get('id')})

        if args.preview:
            print('Preview of users to migrate:')
            for p in preview_list[:50]:
                print(p)
            print(f'Total: {len(preview_list)}')
            return

        inserted = 0
        for r in rows:
            try:
                data = dict(r._mapping)
            except Exception:
                data = dict(r)
            username = data.get('username')
            if not username:
                continue
            exists = mconn.execute(select(users_mysql.c.username).where(users_mysql.c.username == username)).fetchone()
            if exists:
                continue
            # remove id unless preserve-ids requested
            if args.preserve_ids:
                # insert with explicit id (may require disabling strict mode or adjusting auto_increment)
                mconn.execute(users_mysql.insert().values(**data))
            else:
                data.pop('id', None)
                mconn.execute(users_mysql.insert().values(**data))
            inserted += 1
        print(f'Inserted {inserted} new users into MySQL')

    # Admin-only actions: creating users/grants should be done by a DBA/root account.
    # Attempting them with the app user will likely fail; run as admin if needed.
    try:
        with mysql_engine.connect() as conn:
            conn.execute(text("CREATE DATABASE IF NOT EXISTS nutrition_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"))
            # Create app user WITHOUT forcing an auth plugin (some servers don't load mysql_native_password)
            conn.execute(text("CREATE USER IF NOT EXISTS 'appuser'@'127.0.0.1' IDENTIFIED BY 'StrongP@ssw0rd!';"))
            conn.execute(text("GRANT ALL PRIVILEGES ON nutrition_app.* TO 'appuser'@'127.0.0.1';"))
            conn.execute(text("FLUSH PRIVILEGES;"))
            print('Admin statements executed (or skipped if user exists).')
    except Exception as e:
        print('Could not run admin statements (insufficient privileges).')
        print('If you need to create the DB/user, run the SQL in mysql_schema.sql as root or via Workbench.')

if __name__ == '__main__':
    main()
