"""Helper to run the schema SQL and optionally create the app user.

Usage:
  # run as an admin user (root) or a MySQL user with CREATE/GRANT rights
  python setup_mysql.py

This script reads env vars (or prompts):
  MYSQL_ADMIN_USER (default: root)
  MYSQL_ADMIN_PASS (prompted if not set)
  MYSQL_HOST (default 127.0.0.1)
  MYSQL_PORT (default 3306)
  APP_DB (default nutrition_app)
  APP_USER (default appuser)
  APP_PASS (default StrongP@ssw0rd!)

It will execute the `mysql_schema.sql` file and (optionally) create the
application user and grant privileges. Use this when you have admin access to
MySQL and want to prepare the database for the app.
"""

import os
import getpass
from sqlalchemy import create_engine, text

BASE = os.path.dirname(__file__)
SCHEMA_FILE = os.path.join(BASE, 'mysql_schema.sql')

def main():
    admin_user = os.environ.get('MYSQL_ADMIN_USER', 'root')
    admin_pass = os.environ.get('MYSQL_ADMIN_PASS')
    host = os.environ.get('MYSQL_HOST', '127.0.0.1')
    port = os.environ.get('MYSQL_PORT', '3306')

    app_db = os.environ.get('APP_DB', 'nutrition_app')
    app_user = os.environ.get('APP_USER', 'appuser')
    app_pass = os.environ.get('APP_PASS', 'StrongP@ssw0rd!')

    if admin_pass is None:
        admin_pass = getpass.getpass(f'Password for MySQL admin user {admin_user}: ')

    admin_uri = f"mysql+pymysql://{admin_user}:{admin_pass}@{host}:{port}/mysql?charset=utf8mb4"
    print('Connecting as admin to', host, port)
    engine = create_engine(admin_uri)
    try:
        with engine.begin() as conn:
            print('Reading schema from', SCHEMA_FILE)
            with open(SCHEMA_FILE, 'r', encoding='utf-8') as f:
                sql = f.read()
            # Execute schema (note: schema file contains CREATE DATABASE; ensure it's run as admin)
            conn.execute(text(sql))
            print('Schema executed')

            # Create app user and grant privileges (idempotent if IF NOT EXISTS supported)
            print(f"Creating/ensuring app user '{app_user}'@'127.0.0.1' and '{app_user}'@'localhost'")
            # Use mysql_native_password to keep client compatibility
            conn.execute(text("""
                CREATE USER IF NOT EXISTS :u@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY :p
            """), {'u': app_user, 'p': app_pass})
            conn.execute(text("""
                CREATE USER IF NOT EXISTS :u@'localhost' IDENTIFIED WITH mysql_native_password BY :p
            """), {'u': app_user, 'p': app_pass})
            conn.execute(text("GRANT ALL PRIVILEGES ON %s.* TO :u@'127.0.0.1'" % app_db), {'u': app_user})
            conn.execute(text("GRANT ALL PRIVILEGES ON %s.* TO :u@'localhost'" % app_db), {'u': app_user})
            conn.execute(text('FLUSH PRIVILEGES'))
            print('App user created and privileges granted')
    except Exception as e:
        print('Failed to run setup:', e)
        raise

if __name__ == '__main__':
    main()
