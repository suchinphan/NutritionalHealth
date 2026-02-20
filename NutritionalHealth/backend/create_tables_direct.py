#!/usr/bin/env python3
"""Create required tables directly in MySQL using app user credentials.

This runs the CREATE TABLE IF NOT EXISTS statements for `users`, `histories`
and `reports`. Use when the app user can create tables but cannot run
CREATE USER / GRANT statements.
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
        print('Please set MYSQL_USER, MYSQL_PASS and MYSQL_DB in your environment.')
        return

    pw_q = quote_plus(pw)
    uri = f"mysql+pymysql://{user}:{pw_q}@{host}:{port}/{db}?charset=utf8mb4"
    print('Connecting to MySQL as', user, 'to DB', db)

    engine = create_engine(uri, pool_pre_ping=True)

    stmts = [
        """
        CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          username VARCHAR(80) NOT NULL UNIQUE,
          email VARCHAR(120),
          password_hash VARCHAR(255) NOT NULL,
          password_token VARCHAR(255) DEFAULT NULL,
          token_created_at TIMESTAMP NULL DEFAULT NULL,
          created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          gender VARCHAR(10),
          age INT,
          weight FLOAT,
          height FLOAT
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        """,
        """
        CREATE TABLE IF NOT EXISTS histories (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          data TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        """,
        """
        CREATE TABLE IF NOT EXISTS reports (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT,
          type VARCHAR(80),
          detail TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        """,
    ]

    with engine.begin() as conn:
        for s in stmts:
            print('Applying statement snippet...')
            conn.execute(text(s))
        print('Done creating tables.')


if __name__ == '__main__':
    main()
