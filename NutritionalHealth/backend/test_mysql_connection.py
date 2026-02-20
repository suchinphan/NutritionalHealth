#!/usr/bin/env python3
"""Quick tester for MySQL connection and SQLite users preview.

Usage:
  # set env vars then run
  $env:MYSQL_USER="appuser"
  $env:MYSQL_PASS="StrongP@ssw0rd!"
  $env:MYSQL_DB="nutrition_app"
  $env:MYSQL_HOST="127.0.0.1"
  python test_mysql_connection.py

The script URL-encodes the password, prints a masked URI, attempts a connection
and prints helpful hints on common failures. It also prints a small sample from
the local SQLite `data.db` if present.
"""

from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
import os
import traceback


def mask_password_in_uri(uri, pw):
    if not pw:
        return uri
    return uri.replace(pw, '***')


def test_mysql():
    user = os.environ.get('MYSQL_USER')
    pw = os.environ.get('MYSQL_PASS')
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    port = os.environ.get('MYSQL_PORT', '3306')
    db = os.environ.get('MYSQL_DB')

    if not all([user, pw, db]):
        print('Environment variables MYSQL_USER, MYSQL_PASS and MYSQL_DB must be set.')
        return

    pw_q = quote_plus(pw)
    uri = f"mysql+pymysql://{user}:{pw_q}@{host}:{port}/{db}?charset=utf8mb4"
    masked = mask_password_in_uri(uri, pw_q)
    print('Testing MySQL connection to (masked):', masked)

    try:
        engine = create_engine(uri, pool_pre_ping=True)
        with engine.connect() as conn:
            r = conn.execute(text("SELECT 1")).fetchone()
            print('MySQL connection OK, test query returned:', r)
            return True
    except Exception as ex:
        print('MySQL connection failed:')
        traceback.print_exc()
        msg = str(ex)
        if 'Access denied' in msg or '1045' in msg:
            print('\nHint: Access denied (1045). Check user/password, host and privileges.')
            print("Use '127.0.0.1' as host when testing locally and ensure the user@'localhost' has privileges.")
        if 'cryptography' in msg or 'sha2' in msg.lower():
            print('\nHint: Authentication requires the `cryptography` package or mysql_native_password.')
            print('Try: pip install cryptography OR ALTER USER ... IDENTIFIED WITH mysql_native_password')
        return False


def preview_sqlite():
    try:
        from sqlalchemy import MetaData, Table, select, create_engine as ce
        s_engine = ce('sqlite:///data.db')
        meta = MetaData()
        users = Table('users', meta, autoload_with=s_engine)
        with s_engine.connect() as sc:
            rows = sc.execute(select(users).limit(5)).fetchall()
            sample = []
            for r in rows:
                try:
                    # SQLAlchemy Row supports _mapping in recent versions
                    sample.append(dict(r._mapping))
                except Exception:
                    # fallback: build dict from columns
                    rowd = {}
                    for i, col in enumerate(users.columns):
                        try:
                            rowd[col.name] = r[i]
                        except Exception:
                            rowd[col.name] = None
                    sample.append(rowd)
            print('\nSQLite `data.db` users sample (up to 5 rows):')
            print(sample)
    except Exception as e:
        print('\nNo SQLite preview available or failed to read data.db:', e)


def main():
    ok = test_mysql()
    preview_sqlite()
    if not ok:
        print('\nAfter fixing credentials you can re-run this script to re-check. If you want, run the migration script:')
        print('  python migrate_sqlite_to_mysql.py')


if __name__ == '__main__':
    main()
