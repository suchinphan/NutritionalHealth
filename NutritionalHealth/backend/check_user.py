import sqlite3
p='data.db'
conn=sqlite3.connect(p)
c=conn.cursor()
try:
    c.execute("SELECT id,username,email FROM users WHERE username LIKE ? COLLATE NOCASE", ('night1',))
    rows=c.fetchall()
    if not rows:
        print('NOT FOUND')
    else:
        for r in rows:
            print('FOUND', r)
except Exception as e:
    print('ERROR', e)
finally:
    conn.close()
