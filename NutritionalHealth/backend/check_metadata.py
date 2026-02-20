import sqlite3
import pandas as pd

conn = sqlite3.connect("pipeline_metadata.db")

df = pd.read_sql_query("SELECT * FROM pipeline_metadata", conn)

print(df)

conn.close()
