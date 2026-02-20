import os
import sqlite3

base = os.path.abspath(os.getcwd())
print('Working dir:', base)

dbs = [os.path.join(base, f) for f in os.listdir(base) if f.endswith('.db')]
print('DB files found:')
for db in dbs:
    print(' -', db)

for db in dbs:
    try:
        conn = sqlite3.connect(db)
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [r[0] for r in cur.fetchall()]
        print('\nTables in', db, ':', tables)
        conn.close()
    except Exception as e:
        print('Error reading', db, e)
