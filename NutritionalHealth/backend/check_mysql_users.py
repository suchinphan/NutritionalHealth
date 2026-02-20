#!/usr/bin/env python3
"""Check and print rows from the `users` table using env MYSQL_* vars.

Usage (PowerShell):
$env:MYSQL_USER="appuser"; $env:MYSQL_PASS="StrongP@ssw0rd!"; $env:MYSQL_DB="nutrition_app"; $env:MYSQL_HOST="127.0.0.1"; python check_mysql_users.py
"""

import os
from urllib.parse import quote_plus
from sqlalchemy import create_engine, text


def main():
    user = os.environ.get('MYSQL_USER')
    pw = os.environ.get('MYSQL_PASS')
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    port = os.environ.get('MYSQL_PORT', '3306')
    db = os.environ.get('MYSQL_DB')
    if not all([user, pw, db]):
        print('Please set MYSQL_USER, MYSQL_PASS and MYSQL_DB environment variables')
        return

    uri = f"mysql+pymysql://{user}:{quote_plus(pw)}@{host}:{port}/{db}?charset=utf8mb4"
    print('Connecting to MySQL at', uri.replace(quote_plus(pw), '***'))
    engine = create_engine(uri, pool_pre_ping=True)

    with engine.connect() as conn:
        try:
            res = conn.execute(text('SELECT id, username, email, created_at FROM users ORDER BY id;')).fetchall()
            print('Rows in users:', len(res))
            for r in res:
                # SQLAlchemy Row may support _mapping
                try:
                    print(dict(r._mapping))
                except Exception:
                    print(tuple(r))
        except Exception as e:
            print('Query failed:', e)


if __name__ == '__main__':
    main()
