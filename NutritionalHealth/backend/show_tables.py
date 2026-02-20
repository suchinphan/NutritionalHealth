#!/usr/bin/env python3
"""Show MySQL tables and users count using env vars (quick verifier).

Run from backend folder:
  python show_tables.py
"""
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
import os
import traceback


def main():
    user = os.environ.get('MYSQL_USER')
    pw = os.environ.get('MYSQL_PASS')
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    port = os.environ.get('MYSQL_PORT', '3306')
    db = os.environ.get('MYSQL_DB')

    if not all([user, pw, db]):
        print('Set MYSQL_USER, MYSQL_PASS and MYSQL_DB in environment first.')
        return

    uri = f"mysql+pymysql://{user}:{quote_plus(pw)}@{host}:{port}/{db}?charset=utf8mb4"
    print('Connecting to', uri.replace(pw, '***'))
    try:
        engine = create_engine(uri, pool_pre_ping=True)
        with engine.connect() as conn:
            tables = conn.execute(text('SHOW TABLES')).fetchall()
            print('\nTables:')
            for t in tables:
                print(' -', t[0])
            # try users count
            try:
                cnt = conn.execute(text('SELECT COUNT(*) FROM users')).fetchone()
                print('\nusers count:', cnt[0])
            except Exception:
                print('\nCould not query users table (it may not exist).')
    except Exception:
        print('Connection failed:')
        traceback.print_exc()


if __name__ == '__main__':
    main()
