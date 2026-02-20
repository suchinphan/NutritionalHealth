-- As a privileged user (root) run:
CREATE DATABASE IF NOT EXISTS nutrition_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP USER IF EXISTS 'appuser'@'127.0.0.1';
DROP USER IF EXISTS 'appuser'@'localhost';

CREATE USER 'appuser'@'127.0.0.1' IDENTIFIED BY 'StrongP@ssw0rd!';
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'StrongP@ssw0rd!';

GRANT ALL PRIVILEGES ON nutrition_app.* TO 'appuser'@'127.0.0.1';
GRANT ALL PRIVILEGES ON nutrition_app.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;

-- ตาราง users
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
  height FLOAT,
  temp_password_hash VARCHAR(128),
  temp_password_expires_at DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ตาราง histories
CREATE TABLE IF NOT EXISTS histories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  data TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ตาราง reports
CREATE TABLE IF NOT EXISTS reports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  type VARCHAR(80),
  detail TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- If your MySQL client (eg. MySQL Workbench) has "safe updates" enabled
-- you may get Error Code: 1175 when running the UPDATE below. The
-- block below temporarily disables safe-updates for this session,
-- shows the number of rows that will be changed, performs the UPDATE
-- and then restores the previous safe-updates setting.

-- save current safe-updates value
SET @OLD_SQL_SAFE_UPDATES = @@SQL_SAFE_UPDATES;
-- disable safe-updates for this session
SET SQL_SAFE_UPDATES = 0;

-- preview: count rows to be updated
SELECT COUNT(*) AS rows_to_update FROM users WHERE created_at IS NULL;

-- perform the update
UPDATE users
SET created_at = NOW()
WHERE created_at IS NULL;

-- restore previous safe-updates value
SET SQL_SAFE_UPDATES = @OLD_SQL_SAFE_UPDATES;

-- Alternative (works without changing SQL_SAFE_UPDATES):
-- UPDATE users u
-- JOIN (SELECT id FROM users WHERE created_at IS NULL) t ON u.id = t.id
-- SET u.created_at = NOW();

-- USAGE:
-- 1) As root (or a privileged user) run this file to create the DB and tables:
--    mysql -u root -p < backend/mysql_schema.sql
-- 2) If you didn't create the app user in the file, create a user and grant
--    privileges (examples above). Use host 127.0.0.1 when connecting from the
--    app to avoid socket/host resolution differences.
-- 3) In your app session set env vars and start the Flask app:
--    $env:MYSQL_USER="appuser"
--    $env:MYSQL_PASS="StrongP@ssw0rd!"
--    $env:MYSQL_DB="nutrition_app"
--    $env:MYSQL_HOST="127.0.0.1"
--    python api.py

SELECT User, Host FROM mysql.user WHERE User='appuser';

USE nutrition_app;
SELECT id, username, email, created_at FROM users ORDER BY id DESC LIMIT 10;

