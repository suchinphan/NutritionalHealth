"""Add temp password columns to the users table if they don't exist.

Usage: from the backend directory run:
    python add_temp_columns.py

This script detects MySQL vs SQLite and issues the appropriate ALTER TABLE.
It is safe to run multiple times.
"""
from api import app
from models import db
from sqlalchemy import text

def column_exists_mysql(conn, table, column):
    r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE :col"), {'col': column})
    return r.first() is not None

def column_exists_sqlite(conn, table, column):
    r = conn.execute(text(f"PRAGMA table_info({table})"))
    for row in r:
        # PRAGMA table_info returns rows where second column is name in many SQLite versions
        # row[1] is column name
        if str(row[1]) == column:
            return True
    return False

def add_columns():
    with app.app_context():
        engine = db.engine
        dialect = engine.dialect.name
        table = 'users'
        with engine.connect() as conn:
            if dialect == 'mysql':
                # check and add columns
                if not column_exists_mysql(conn, table, 'temp_password_hash'):
                    print('Adding temp_password_hash (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_hash VARCHAR(128)"))
                else:
                    print('temp_password_hash already exists')
                if not column_exists_mysql(conn, table, 'temp_password_expires_at'):
                    print('Adding temp_password_expires_at (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_expires_at DATETIME"))
                else:
                    print('temp_password_expires_at already exists')
            else:
                # assume sqlite or other dialects that support PRAGMA table_info
                if not column_exists_sqlite(conn, table, 'temp_password_hash'):
                    print('Adding temp_password_hash (SQLite)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_hash TEXT"))
                else:
                    print('temp_password_hash already exists')
                if not column_exists_sqlite(conn, table, 'temp_password_expires_at'):
                    print('Adding temp_password_expires_at (SQLite)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_expires_at DATETIME"))
                else:
                    print('temp_password_expires_at already exists')

if __name__ == '__main__':
    print('Running add_temp_columns.py')
    add_columns()
    print('Done')
