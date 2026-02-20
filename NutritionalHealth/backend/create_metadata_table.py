import sqlite3

# สร้างหรือเชื่อมต่อฐานข้อมูล
conn = sqlite3.connect("pipeline_metadata.db")
cursor = conn.cursor()

# สร้างตาราง metadata ถ้ายังไม่มี
cursor.execute("""
CREATE TABLE IF NOT EXISTS pipeline_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    step_name TEXT,
    file_count INTEGER,
    row_count INTEGER,
    column_count INTEGER,
    run_time TEXT,
    status TEXT
)
""")

conn.commit()
conn.close()

print("Metadata table created successfully!")
