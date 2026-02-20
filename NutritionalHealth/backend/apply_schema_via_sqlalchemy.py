#!/usr/bin/env python3
"""Apply CREATE TABLE statements from mysql_schema.sql using SQLAlchemy.

Usage:
  Set env vars then run:
    $env:MYSQL_USER="appuser"
    $env:MYSQL_PASS="StrongP@ssw0rd!"
    $env:MYSQL_DB="nutrition_app"
    $env:MYSQL_HOST="127.0.0.1"
    python apply_schema_via_sqlalchemy.py

This script splits the schema file on semicolons and executes each statement
individually, skipping comments and empty pieces. Errors are printed but do not
stop execution so a non-privileged app user can still create tables if allowed.
"""

import os
from urllib.parse import quote_plus
from sqlalchemy import create_engine, text
import traceback


def main():
    user = os.environ.get('MYSQL_USER')
    pw = os.environ.get('MYSQL_PASS')
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    port = os.environ.get('MYSQL_PORT', '3306')
    db = os.environ.get('MYSQL_DB')

    if not all([user, pw, db]):
        print('Please set MYSQL_USER, MYSQL_PASS and MYSQL_DB in your environment.')
        return

    pw_q = quote_plus(pw)
    uri = f"mysql+pymysql://{user}:{pw_q}@{host}:{port}/{db}?charset=utf8mb4"
    print('Connecting to MySQL as', user, 'to DB', db)

    engine = create_engine(uri, pool_pre_ping=True)

    schema_path = os.path.join(os.path.dirname(__file__), 'mysql_schema.sql')
    with open(schema_path, 'r', encoding='utf-8') as fh:
        sql = fh.read()

    # Split on semicolon and execute statements individually
    statements = [s.strip() for s in sql.split(';') if s.strip()]

    # Only run CREATE TABLE / ALTER TABLE statements as the app user usually
    # won't have global privileges to create users/grants/databases.
    allowed_prefixes = ('CREATE TABLE', 'ALTER TABLE', 'DROP TABLE', 'CREATE INDEX', 'CREATE UNIQUE INDEX')
    print('Parsed', len(statements), 'SQL statements from mysql_schema.sql')
    for i, s in enumerate(statements, start=1):
        summary = s.strip().splitlines()[0][:120] if s.strip() else '<empty>'
        print(f'statement {i}:', summary)

    with engine.begin() as conn:
        for stmt in statements:
            s = stmt.lstrip()
            if s.startswith('--') or not s:
                continue
            up = s.upper()
            if not any(up.startswith(p) for p in allowed_prefixes):
                print('Skipping statement (not allowed for app user):', s.splitlines()[0][:120])
                continue
            try:
                conn.execute(text(stmt))
                print('Applied:', s.splitlines()[0][:120])
            except Exception:
                print('ERROR executing statement (continuing):')
                print(s.splitlines()[0][:200])
                traceback.print_exc()


if __name__ == '__main__':
    main()
