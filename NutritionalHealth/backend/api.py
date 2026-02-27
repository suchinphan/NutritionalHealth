from flask import Flask, request, jsonify, send_file, Response, session, redirect, url_for, current_app
from sqlalchemy import func, create_engine, text
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
import os
import io
import csv
import re
import json
import logging
import secrets
import hashlib
import hmac
from datetime import datetime, timedelta, timezone
from urllib.parse import quote_plus
import pathlib
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView

# Application base directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Path to legacy SQLite DB (used only for advisory checks). Can be overridden via env.
DB_PATH = os.environ.get('DB_PATH', os.path.join(BASE_DIR, 'app.db'))

# Rate limiter (will be initialized with app later)
limiter = Limiter(key_func=get_remote_address)

# Import DB and models
from models import db, User, FoodMenu, FoodCategory, FoodType, DrinkMenu, DrinkType, DessertMenu, Submission, Report, History
from sqlalchemy import JSON as SA_JSON

def create_app():
    app = Flask(__name__)

    # ======================
    # Environment Mode
    # ======================
    ENV = os.environ.get("FLASK_ENV", "development")
    IS_PRODUCTION = ENV == "production"

    # ======================
    # SECRET KEY (Environment Only)
    # ======================
    secret_key = os.environ.get("SECRET_KEY")
    if not secret_key:
        raise RuntimeError("SECRET_KEY environment variable not set")

    app.config["SECRET_KEY"] = secret_key

    # ======================
    # Basic Security Config
    # ======================
    app.config.update(
        MAX_CONTENT_LENGTH=5 * 1024 * 1024,  # 5MB upload limit
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE="Lax",
        SESSION_COOKIE_SECURE=IS_PRODUCTION,
        PERMANENT_SESSION_LIFETIME=timedelta(hours=2),
        PREFERRED_URL_SCHEME="https" if IS_PRODUCTION else "http"
    )

    # ======================
    # Force HTTPS (Production Only)
    # ======================
    @app.before_request
    def force_https():
        if IS_PRODUCTION:
            forwarded_proto = request.headers.get("X-Forwarded-Proto", "")
            if not request.is_secure and forwarded_proto != "https":
                return redirect(request.url.replace("http://", "https://"), code=301)

    # ======================
    # Security Headers
    # ======================
    @app.after_request
    def set_security_headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"

        # HSTS (Production Only)
        if IS_PRODUCTION:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )

        # Stronger CSP
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self'; "
            "img-src 'self' data:; "
            "object-src 'none'; "
            "base-uri 'self'; "
            "frame-ancestors 'none';"
        )

        return response

    # ======================
    # Initialize Rate Limiter
    # ======================
    limiter.init_app(app)

    # ======================
    # MySQL Configuration
    # ======================
    cfg_path = os.path.join(BASE_DIR, "mysql_config.json")

    mysql_user = os.environ.get("MYSQL_USER")
    mysql_pass = os.environ.get("MYSQL_PASS")
    mysql_host = os.environ.get("MYSQL_HOST", "127.0.0.1")
    mysql_port = os.environ.get("MYSQL_PORT", "3306")
    mysql_db = os.environ.get("MYSQL_DB")

    # Optional config file fallback
    if os.path.exists(cfg_path):
        try:
            with open(cfg_path, "r", encoding="utf-8") as f:
                cfg = json.load(f)

            mysql_user = cfg.get("user") or cfg.get("username") or mysql_user
            mysql_pass = cfg.get("password") or cfg.get("pass") or mysql_pass
            mysql_host = cfg.get("host") or mysql_host
            mysql_port = str(cfg.get("port") or mysql_port)
            mysql_db = cfg.get("database") or cfg.get("db") or mysql_db

            app.logger.info("Loaded MySQL config from %s", cfg_path)

        except Exception as e:
            app.logger.warning("Failed to load mysql_config.json: %s", e)

    # ======================
    # Validate MySQL Config
    # ======================
    if not (mysql_user and mysql_pass and mysql_db):
        raise RuntimeError(
            "MySQL configuration missing. "
            "Set MYSQL_USER, MYSQL_PASS, MYSQL_DB or provide mysql_config.json"
        )

    # ======================
    # Build MySQL URI
    # ======================
    mysql_pass_q = quote_plus(mysql_pass)

    mysql_uri = (
        f"mysql+pymysql://{mysql_user}:{mysql_pass_q}"
        f"@{mysql_host}:{mysql_port}/{mysql_db}?charset=utf8mb4"
    )

    # ======================
    # Test Database Connection
    # ======================
    try:
        test_engine = create_engine(mysql_uri, pool_pre_ping=True)
        with test_engine.connect():
            pass
        test_engine.dispose()

        app.config["SQLALCHEMY_DATABASE_URI"] = mysql_uri

    except Exception:
        app.logger.exception("MySQL connection failed. Aborting startup.")
        raise

    # ======================
    # SQLAlchemy Settings
    # ======================
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
        "pool_pre_ping": True,
        "pool_recycle": 280
    }

    db.init_app(app)

    # ======================
    # CORS Configuration
    # ======================
    frontend_origin = os.environ.get("FRONTEND_ORIGIN", "http://localhost:3000")

    CORS(
        app,
        resources={
            r"/*": {
                "origins": [frontend_origin],
                "methods": ["GET", "POST", "PUT", "DELETE"],
                "allow_headers": ["Content-Type", "Authorization"],
            }
        },
        supports_credentials=False
    )

    return app


# ======================
# CREATE APP INSTANCE
# ======================
app = create_app()

# Startup fingerprint to verify deployed file version at runtime
try:
    import hashlib, pathlib
    _api_path = pathlib.Path(__file__)
    _content = _api_path.read_bytes()
    _sha1 = hashlib.sha1(_content).hexdigest()
    print(f"🔥 API STARTUP: api.py sha1={_sha1}")
    print("VERSION 2 - CHANGE PASSWORD FIXED")
except Exception:
    print("🔥 API STARTUP: unable to compute api.py sha1")


# ------------------------
# จำกัดสิทธิ์เฉพาะ admin
# ------------------------
class AdminOnlyModelView(ModelView):
    def is_accessible(self):
        user_id = session.get("admin_user_id")
        if not user_id:
            return False

        user = User.query.get(user_id)
        return user and user.is_admin

    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for("admin_login"))

# ------------------------
# สร้าง Admin Panel
# ------------------------
admin = Admin(app, name='Admin Panel')

admin.add_view(AdminOnlyModelView(User, db.session))
admin.add_view(AdminOnlyModelView(FoodCategory, db.session))
admin.add_view(AdminOnlyModelView(FoodMenu, db.session))

# ------------------------
# Route สำหรับ login admin
# ------------------------
import time
from flask import render_template_string

@limiter.limit("5 per minute")
@app.route('/admin-login', methods=['GET', 'POST'])
def admin_login():
    error = None

    if request.method == 'POST':
        username = (request.form.get('username') or '').strip()
        password = (request.form.get('password') or '').strip()

        # ป้องกัน brute force เบื้องต้น
        time.sleep(0.8)

        user = User.query.filter(func.lower(User.username) == username.lower()).first()

        if not user or not user.is_admin:
            error = "Invalid username or password"
        elif not check_password_hash(user.password_hash, password):
            error = "Invalid username or password"
        else:
            session.clear()
            session["admin_user_id"] = user.id
            session.permanent = True
            return redirect(url_for("admin.index"))

    return render_template_string("""
    <h2>Admin Login</h2>
    {% if error %}
        <p style="color:red;">{{ error }}</p>
    {% endif %}
    <form method="post">
        <input name="username" placeholder="Username" required><br><br>
        <input name="password" type="password" placeholder="Password" required><br><br>
        <button type="submit">Login</button>
    </form>
    """, error=error)

@app.route('/admin-logout', methods=['POST'])
def admin_logout():
    session.clear()
    return redirect(url_for("admin_login"))

@limiter.limit("60 per minute")
@app.route('/foods', methods=['GET'])
def get_foods():
    try:
        page = max(int(request.args.get('page', 1)), 1)
    except (ValueError, TypeError):
        page = 1

    try:
        per_page = min(max(int(request.args.get('per_page', 20)), 1), 100)
    except (ValueError, TypeError):
        per_page = 20

    pagination = FoodMenu.query.paginate(
        page=page,
        per_page=per_page,
        error_out=False
    )

    return jsonify({
        "total": pagination.total,
        "page": page,
        "per_page": per_page,  # เพิ่มให้ frontend ใช้ง่าย
        "items": [
            {
                "id": f.id,
                "name": f.name,
                "calories": f.calories,
                "food_category_id": f.category_id
            }
            for f in pagination.items
        ]
    })


@limiter.limit("60 per minute")
@app.route('/api/food-menus', methods=['GET'])
def get_food_menus_api():
    try:
        foods = FoodMenu.query.all()
        result = []
        for f in foods:
            cat_name = None
            try:
                if getattr(f, 'category', None):
                    cat_name = getattr(f.category, 'name', None)
            except Exception:
                cat_name = None

            result.append({
                'id': f.id,
                'name': getattr(f, 'name', None),
                'category': cat_name,
                'calories': float(f.calories) if getattr(f, 'calories', None) is not None else None
            })

        return jsonify(result)
    except Exception:
        app.logger.exception('get_food_menus_api error')
        return jsonify({'error': 'internal'}), 500


@limiter.limit("60 per minute")
@app.route('/api/dessert-menus', methods=['GET'])
def get_dessert_menus_api():
    try:
        # Use information_schema to avoid ORM errors when DB schema is legacy
        schema = db.engine.url.database
        col_q = text("SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema=:schema AND table_name='dessert_menus'")
        cols = {r[0] for r in db.session.execute(col_q, {"schema": schema}).fetchall()}

        result = []
        if 'name' in cols:
            rows = db.session.execute(text("SELECT id, name, calories FROM dessert_menus")).fetchall()
            for r in rows:
                result.append({
                    'id': int(r[0]),
                    'name': r[1],
                    'calories': float(r[2]) if r[2] is not None else None
                })
        else:
            rows = db.session.execute(text("SELECT id, dessert_name, calories FROM dessert_menus")).fetchall()
            for r in rows:
                result.append({
                    'id': int(r[0]),
                    'name': r[1],
                    'calories': float(r[2]) if r[2] is not None else None
                })

        return jsonify(result)
    except Exception:
        app.logger.exception('get_dessert_menus_api error')
        return jsonify({'error': 'internal'}), 500

# -----------------------------
# FOOD TYPES (หน้าเลือกประเภท)
# -----------------------------
@app.route("/api/food-types")
def api_food_types():
    return jsonify([
        {"id": ft.id, "name": ft.name}
        for ft in FoodType.query.all()
    ])


# -----------------------------
# FOOD CATEGORIES (ตามประเภท)
# -----------------------------
@app.route("/api/food-categories")
def api_food_categories():
    food_type_id = request.args.get("food_type_id", type=int)

    q = FoodCategory.query
    if food_type_id:
        q = q.filter(FoodCategory.food_type_id == food_type_id)

    return jsonify([
        {"id": c.id, "name": c.name}
        for c in q.all()
    ])

@app.route("/api/drink-types")
def api_drink_types():
    return jsonify([
        {"id": d.id, "name": d.name}
        for d in DrinkType.query.all()
    ])

# -----------------------------
# FOOD MENUS (ตามหมวด)
# -----------------------------
@app.route("/api/food-menus-simple")
def api_food_menus_simple():
    category_id = request.args.get("category_id", type=int)

    q = FoodMenu.query

    if category_id:
        q = q.filter(FoodMenu.category_id == category_id)

    # ✅ ตัดเมนูที่ไม่ใช่อาหารจริง
    q = q.filter(FoodMenu.is_dessert == False)

    return jsonify([
        {
            "id": m.id,
            "name": m.name,
            "calories": m.calories
        }
        for m in q.all()
    ])

@limiter.limit("60 per minute")
@app.route('/api/drink-menus', methods=['GET'])
def get_drink_menus_api():
    try:
        # Allow filtering by drink_type_id so each drink type shows its own menus
        drink_type_id = request.args.get('drink_type_id', type=int)
        q = DrinkMenu.query
        if drink_type_id:
            q = q.filter(DrinkMenu.drink_type_id == drink_type_id)

        drinks = q.all()
        result = [
            {
                'id': dr.id,
                'name': getattr(dr, 'name', None),
                'calories': float(getattr(dr, 'calories', None)) if getattr(dr, 'calories', None) is not None else None
            }
            for dr in drinks
        ]
        return jsonify(result)
    except Exception:
        app.logger.exception('get_drink_menus_api error')
        return jsonify({'error': 'internal'}), 500
# Register admin blueprint if available
try:
    from admin.admin_routes import admin_bp
    app.register_blueprint(admin_bp, url_prefix='/admin')
    app.logger.info('Admin blueprint registered at /admin')
except Exception:
    app.logger.info('Admin blueprint not available')

# configure basic logging
logging.basicConfig(level=logging.INFO)
app.logger.setLevel(logging.INFO)

def ensure_db():
    with app.app_context():
        db.create_all()

ensure_db()


# ======================
# Startup diagnostics
# ======================
try:
    uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    app.logger.info('SQLALCHEMY_DATABASE_URI=%s', uri)
    with app.app_context():
        with db.engine.connect() as conn:
            res = conn.execute("SELECT @@port AS port, DATABASE() AS db")
            row = res.first()
            app.logger.info('SELECT @@port, DATABASE(): %s', row)
except Exception:
    pass


def ensure_temp_columns():
    """Ensure `temp_password_hash` and `temp_password_expires_at` exist on users table.

    This runs at app startup so existing DBs are migrated in-place.
    """
    from sqlalchemy import text
    table = 'users'
    # run inside app context so SQLAlchemy engine is available
    try:
        with app.app_context():
            engine = db.engine
            dialect = engine.dialect.name
            with engine.connect() as conn:
                if dialect == 'mysql':
                    # MySQL: use SHOW COLUMNS
                    r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'temp_password_hash'"))
                    col = r.first()
                    if col is None:
                        app.logger.info('Adding temp_password_hash column (MySQL)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_hash VARCHAR(512)"))
                    else:
                        # If existing column is too small for current hash algorithms, enlarge it.
                        # The column definition is in col[1]=Field and col[2]=Type depending on driver; safer to query INFORMATION_SCHEMA.
                        info = conn.execute(text(f"SELECT CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = :table AND COLUMN_NAME = 'temp_password_hash' AND TABLE_SCHEMA = DATABASE()"), {'table': table}).first()
                        try:
                            maxlen = int(info[0]) if info and info[0] else None
                        except Exception:
                            maxlen = None
                        if not maxlen or maxlen < 512:
                            app.logger.info('Altering temp_password_hash column to VARCHAR(512) (was %s)', maxlen)
                            conn.execute(text(f"ALTER TABLE {table} MODIFY COLUMN temp_password_hash VARCHAR(512)"))
                    r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'temp_password_expires_at'"))
                    if r.first() is None:
                        app.logger.info('Adding temp_password_expires_at column (MySQL)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_expires_at DATETIME"))
                # Ensure reset_token_hash and reset_token_expires_at exist
                r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'reset_token_hash'"))
                if r.first() is None:
                    app.logger.info('Adding reset_token_hash column (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_token_hash VARCHAR(255)"))
                r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'reset_token_expires_at'"))
                if r.first() is None:
                    app.logger.info('Adding reset_token_expires_at column (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_token_expires_at DATETIME"))
                # Ensure reset_otp_hash, reset_otp_expires_at, reset_otp_attempts exist
                r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'reset_otp_hash'"))
                if r.first() is None:
                    app.logger.info('Adding reset_otp_hash column (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_otp_hash VARCHAR(255)"))
                r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'reset_otp_expires_at'"))
                if r.first() is None:
                    app.logger.info('Adding reset_otp_expires_at column (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_otp_expires_at DATETIME"))
                r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'reset_otp_attempts'"))
                if r.first() is None:
                    app.logger.info('Adding reset_otp_attempts column (MySQL)')
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_otp_attempts INT DEFAULT 0"))

                # For non-MySQL dialects (e.g., SQLite) ensure columns via PRAGMA
                if dialect != 'mysql':
                    # SQLite (or others): use PRAGMA table_info
                    r = conn.execute(text(f"PRAGMA table_info({table})"))
                    cols = [row[1] for row in r]
                    if 'temp_password_hash' not in cols:
                        app.logger.info('Adding temp_password_hash column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_hash TEXT"))
                    if 'temp_password_expires_at' not in cols:
                        app.logger.info('Adding temp_password_expires_at column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN temp_password_expires_at DATETIME"))
                    # Ensure reset_token_hash and reset_token_expires_at exist
                    if 'reset_token_hash' not in cols:
                        app.logger.info('Adding reset_token_hash column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_token_hash TEXT"))
                    if 'reset_token_expires_at' not in cols:
                        app.logger.info('Adding reset_token_expires_at column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_token_expires_at DATETIME"))
                    # Ensure reset_otp_* columns exist for SQLite
                    if 'reset_otp_hash' not in cols:
                        app.logger.info('Adding reset_otp_hash column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_otp_hash TEXT"))
                    if 'reset_otp_expires_at' not in cols:
                        app.logger.info('Adding reset_otp_expires_at column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_otp_expires_at DATETIME"))
                    if 'reset_otp_attempts' not in cols:
                        app.logger.info('Adding reset_otp_attempts column (SQLite)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN reset_otp_attempts INTEGER DEFAULT 0"))
    except Exception as e:
        app.logger.warning('ensure_temp_columns failed: %s', e)


# Ensure temp columns exist for backward compatibility
ensure_temp_columns()


def ensure_food_is_dessert_column():
    """Ensure `is_dessert` boolean column exists on `food_menus`.

    This runs at startup to make the change in-place for existing DBs.
    """
    from sqlalchemy import text
    table = 'food_menus'
    try:
        with app.app_context():
            engine = db.engine
            dialect = engine.dialect.name
            with engine.connect() as conn:
                if dialect == 'mysql':
                    r = conn.execute(text(f"SHOW COLUMNS FROM {table} LIKE 'is_dessert'"))
                    if r.first() is None:
                        app.logger.info('Adding is_dessert column (MySQL)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN is_dessert TINYINT(1) DEFAULT 0"))
                else:
                    # SQLite / others
                    r = conn.execute(text(f"PRAGMA table_info({table})"))
                    cols = [row[1] for row in r]
                    if 'is_dessert' not in cols:
                        app.logger.info('Adding is_dessert column (SQLite/other)')
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN is_dessert INTEGER DEFAULT 0"))
    except Exception as e:
        app.logger.warning('ensure_food_is_dessert_column failed: %s', e)


# Ensure food_menus has is_dessert column
ensure_food_is_dessert_column()


def save_history_record(user_id, data_obj):
    """Save a History record. If the `data` column supports JSON, store
    the object directly; otherwise serialize to JSON text (ensure_ascii=False).

    This keeps backward compatibility when DB uses TEXT vs JSON column types.
    """
    try:
        col_type = None
        try:
            col_type = History.__table__.c.data.type
        except Exception:
            col_type = None

        # If DB column is JSON/JSONB type, store the object directly
        if col_type is not None and isinstance(col_type, SA_JSON):
            h = History(user_id=user_id, data=data_obj)
        else:
            # Fallback: dump to string for TEXT columns
            h = History(user_id=user_id, data=json.dumps(data_obj, ensure_ascii=False, default=str))

        db.session.add(h)
        db.session.commit()
        return h
    except Exception:
        db.session.rollback()
        app.logger.exception('save_history_record failed for user %s', user_id)
        raise


def token_valid_for_user(user: User, token: str) -> bool:
    """Return True if token matches and is not expired.

    TTL days can be configured via env `TOKEN_TTL_DAYS` (default 30).
    """
    if not user or not user.password_token or token != user.password_token:
        return False
    try:
        ttl_days = int(os.environ.get('TOKEN_TTL_DAYS', '30'))
    except Exception:
        ttl_days = 30
    if not user.token_created_at:
        return True
    try:
        age = datetime.now(timezone.utc) - user.token_created_at
        return age <= timedelta(days=ttl_days)
    except Exception:
        return True

# NOTE: automatic SQLite->MySQL migration at startup was removed because it
# caused fragile reflection/serialization errors in some environments.
# Use the provided `migrate_with_config.py` script to preview and perform
# a safe migration when ready. If a local SQLite DB exists, log an advisory
# message instead of attempting an automatic migration here.
if 'mysql' in app.config.get('SQLALCHEMY_DATABASE_URI', ''):
    sqlite_path = pathlib.Path(DB_PATH)
    if sqlite_path.exists():
        app.logger.info(
            'Local SQLite DB found at %s. To migrate users to MySQL run: migrate_with_config.py --preview --migrate',
            DB_PATH,
        )

@app.route('/init-db', methods=['POST'])
def init_db():
    """
    Initialize database (EXTREMELY DANGEROUS).
    Only allowed in DEBUG mode + localhost + ADMIN_SECRET.
    """

    # ❌ ห้ามรันใน production เด็ดขาด
    if not app.debug:
        return jsonify({'error': 'forbidden'}), 403

    admin_secret = os.environ.get("ADMIN_SECRET")
    provided = request.headers.get("X-Admin-Secret")

    # ต้องมี secret และต้องตรงกัน
    if not admin_secret or provided != admin_secret:
        return jsonify({'error': 'forbidden'}), 403

    # อนุญาตเฉพาะเรียกจากเครื่อง server เท่านั้น
    if request.remote_addr not in ("127.0.0.1", "::1"):
        return jsonify({'error': 'local requests only'}), 403

    try:
        db.drop_all()
        db.create_all()
        return jsonify({'status': 'ok', 'msg': 'db initialized'})
    except Exception:
        app.logger.exception("DB init failed")
        return jsonify({'error': 'database error'}), 500

@app.route('/register', methods=['POST'], strict_slashes=False)
def register():

    # -------------------------
    # Require JSON
    # -------------------------
    if not request.is_json:
        return jsonify({'error': 'JSON body required'}), 400

    data = request.get_json(silent=True) or {}

    username = (data.get('username') or '').strip()
    password = data.get('password') or ''
    confirm = data.get('confirm_password')
    email = (data.get('email') or '').strip().lower()

    app.logger.info(
        'Register attempt: username=%s email=%s',
        username,
        email
    )

    # -------------------------
    # Block Guest registrations
    # -------------------------
    is_guest_flag = data.get('is_guest')
    if is_guest_flag is True:
        return jsonify({'error': 'guest cannot be registered'}), 400

    uname = username.lower()
    mail = email.lower()
    if uname.startswith('guest_') or mail.startswith('guest+'):
        return jsonify({'error': 'guest cannot be registered'}), 400

    # -------------------------
    # Validation
    # -------------------------
    if not username or not password:
        return jsonify({'error': 'username and password are required'}), 400

    if confirm is not None and confirm != '' and password != confirm:
        return jsonify({'error': 'password and confirm_password do not match'}), 400

    if not email:
        return jsonify({'error': 'email is required'}), 400

    # -------------------------
    # Validate email format
    # -------------------------
    email_pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$'
    if not re.match(email_pattern, email):
        return jsonify({'error': 'invalid email format'}), 400

    # NOTE: Do not restrict TLDs here. Email must match DB exactly on lookup.

    if len(username) < 4:
        return jsonify({'error': 'username must be at least 4 characters long'}), 400

    if len(password) < 8:
        return jsonify({'error': 'password must be at least 8 characters long'}), 400

    # Password must be strong (uppercase, lowercase, number, special character)
    strong_pattern = r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])'
    if not re.search(strong_pattern, password):
        return jsonify({
            'error': 'password must include uppercase, lowercase, number and special character'
        }), 400

    # -------------------------
    # Check duplicates (case-insensitive)
    # -------------------------
    try:
        if User.query.filter(func.lower(User.username) == username.lower()).first():
            return jsonify({'error': 'username exists'}), 400

        if User.query.filter(func.lower(User.email) == email.lower()).first():
            return jsonify({'error': 'email already in use'}), 400
    except Exception:
        app.logger.exception('DB lookup failed during register')
        return jsonify({'error': 'database error'}), 500

    # -------------------------
    # Create user
    # -------------------------
    try:
        pwd_hash = generate_password_hash(password)
        token = secrets.token_urlsafe(32)

        user = User(
            username=username,
            email=email,
            password_hash=pwd_hash,
            password_token=token,
            token_created_at=datetime.now(timezone.utc)
        )

        db.session.add(user)
        db.session.commit()

    except Exception:
        db.session.rollback()
        app.logger.exception('DB commit failed during register')
        return jsonify({'error': 'database error'}), 500

    # -------------------------
    # Response
    # -------------------------
    try:
        created_at = user.created_at.isoformat()
    except Exception:
        created_at = datetime.now(timezone.utc).isoformat()

    return jsonify({
        'success': True,
        'id': user.id,
        'user_id': user.id,
        'username': user.username,
        'email': user.email,
        'authToken': token,
        'password_token': token,
        'created_at': created_at,
        'data': {
            'userid': user.id,
            'authToken': token
        }
    }), 201


@limiter.limit("5 per minute")
@app.route('/login', methods=['POST'], strict_slashes=False)
def login():
    time.sleep(0.6)  # 🔐 mitigate brute force timing

    # -------------------------
    # Get JSON safely
    # -------------------------
    if not request.is_json:
        return jsonify({'error': 'JSON body required'}), 400

    data = request.get_json(silent=True) or {}
    username_input = (data.get('username') or '').strip()
    password = data.get('password') or ''

    if not username_input or not password:
        return jsonify({'error': 'username and password required'}), 400


    # -------------------------
    # Lookup user (email or username)
    # -------------------------
    try:
        # If the input contains an @ assume an email and compare case-insensitively.
        # Otherwise compare username case-insensitively.
        if '@' in username_input:
            user = User.query.filter(func.lower(User.email) == username_input.lower()).first()
        else:
            user = User.query.filter(func.lower(User.username) == username_input.lower()).first()
    except Exception:
        app.logger.exception('DB lookup failed during login')
        return jsonify({'message': 'database error'}), 500

    app.logger.info('Login attempt: input=%s found=%s', username_input, 'yes' if user else 'no')

    # If user not found -> authentication error (don't leak which)
    if not user:
        app.logger.info('Login failed: user not found input=%s', username_input)
        return jsonify({'message': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'}), 401

    # -------------------------
    # Check permanent password (using werkzeug check_password_hash)
    # -------------------------
    perm_ok = False
    try:
        if user.password_hash:
            perm_ok = check_password_hash(user.password_hash, password)
    except Exception:
        perm_ok = False

    # -------------------------
    # Check temporary password
    # -------------------------
    temp_ok = False
    if user and user.temp_password_hash and user.temp_password_expires_at:
        try:
            expires = user.temp_password_expires_at

            # If string → parse
            if isinstance(expires, str):
                try:
                    expires = datetime.fromisoformat(expires)
                except Exception:
                    expires = datetime.strptime(
                        expires,
                        '%Y-%m-%d %H:%M:%S'
                    )

            # If naive → treat as UTC
            if expires.tzinfo is None:
                expires = expires.replace(tzinfo=timezone.utc)

            if datetime.now(timezone.utc) <= expires:
                temp_ok = check_password_hash(
                    user.temp_password_hash,
                    password
                )
            else:
                app.logger.info(
                    'Temporary password expired for user_id=%s',
                    user.id
                )
        except Exception:
            temp_ok = False

    # -------------------------
    # Success case
    # -------------------------
    if perm_ok or temp_ok:
        # generate a server-side token (keeps compatibility with other endpoints)
        new_token = secrets.token_urlsafe(32)
        user.password_token = new_token
        user.token_created_at = datetime.now(timezone.utc)

        # If login via temp password only → clear it
        if temp_ok and not perm_ok:
            user.temp_password_hash = None
            user.temp_password_expires_at = None

        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return jsonify({'message': 'database error'}), 500

        app.logger.info('Login success: user_id=%s perm_ok=%s temp_ok=%s', user.id, perm_ok, temp_ok)

        return jsonify({
            'message': 'Login successful',
            'id': user.id,
            'user_id': user.id,
            'username': user.username,
            'email': user.email,
            'authToken': new_token,
            'password_token': new_token,
            'data': {
                'userid': user.id,
                'authToken': new_token
            }
        }), 200

    # -------------------------
    # Failure: wrong password
    # -------------------------
    app.logger.info('Login failed: invalid credentials user_id=%s', user.id if user else 'unknown')
    return jsonify({'message': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'}), 401

@limiter.limit("30 per minute")
@app.route('/user/<int:user_id>', methods=['GET', 'POST'])
def user_info(user_id):
    user = User.query.get_or_404(user_id)
    # Require Authorization for both GET and POST
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401

    token = auth.split(' ', 1)[1].strip()

    if not token_valid_for_user(user, token):
        return jsonify({'error': 'invalid or expired token'}), 401

    if request.method == 'GET':
        return jsonify({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'gender': user.gender,
            'age': user.age,
            'weight': user.weight,
            'height': user.height
        })

    # POST -> update personal info
    data = request.json or {}
    user.gender = data.get('gender', user.gender)
    user.age = data.get('age', user.age)
    user.weight = data.get('weight', user.weight)
    user.height = data.get('height', user.height)

    try:
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({'error': 'database error'}), 500

    return jsonify({'status': 'updated'})

@limiter.limit("5 per minute")
@app.route('/admin/set-password', methods=['POST'])
def admin_set_password():
    """
    Admin helper to set a user's permanent password.
    Protected by ADMIN_SECRET (header only).
    Disabled automatically outside development unless explicitly allowed.
    """

    # =========================
    # 🔒 Environment restriction
    # =========================
    if os.environ.get("FLASK_ENV") != "development":
        return jsonify({'error': 'forbidden'}), 403

    # =========================
    # 🔒 Header secret check
    # =========================
    admin_secret = os.environ.get('ADMIN_SECRET')
    provided = request.headers.get('X-Admin-Secret')

    if not admin_secret or not provided or not secrets.compare_digest(provided, admin_secret):
        return jsonify({'error': 'forbidden'}), 403

    # =========================
    # 📥 Input
    # =========================
    data = request.json or {}
    username = (data.get('username') or '').strip()
    password = (data.get('password') or '').strip()

    if not username or not password:
        return jsonify({'error': 'username and password required'}), 400

    # =========================
    # 🔒 Password policy
    # =========================
    if len(password) < 8 \
       or not re.search(r'[A-Z]', password) \
       or not re.search(r'[a-z]', password) \
       or not re.search(r'\d', password) \
       or not re.search(r'[!@#$%&*()]', password):
        return jsonify({
            'error': 'password must include upper, lower, digit, special and be 8+ chars'
        }), 400

    user = User.query.filter(func.lower(User.username) == username.lower()).first()

    # 🔐 ไม่เปิดเผยว่ามี user หรือไม่
    if not user:
        return jsonify({'status': 'ok'}), 200

    try:
        # =========================
        # 🔄 Set new permanent password
        # =========================
        user.password_hash = generate_password_hash(password)

        # Clear temp password
        user.temp_password_hash = None
        user.temp_password_expires_at = None

        # 🔄 Rotate login token immediately
        user.password_token = secrets.token_urlsafe(32)
        user.token_created_at = datetime.now(timezone.utc)

        # Mark password change time
        user.password_changed_at = datetime.now(timezone.utc)

        db.session.commit()

    except Exception:
        db.session.rollback()
        app.logger.exception('Failed to set admin password')
        return jsonify({'error': 'database error'}), 500

    return jsonify({'status': 'ok'}), 200


@limiter.limit("60 per minute")   
@app.route("/food-types")
def get_food_types():
    types = FoodType.query.all()
    return jsonify([
        {"id": t.id, "name": t.name}
        for t in types
    ])


@limiter.limit("30 per minute")
@app.route('/menus', methods=['GET'])
def get_menus():
    """Return menu names, optionally filtered by category name via ?category=..."""
    try:
        category = (request.args.get('category') or '').strip()
        q = FoodMenu.query

        if category:
            # Flexible matching: exact -> contains -> grouped mappings (Thai phrases)
            cat_lower = category.lower()

            # 1) Try ORM exact/contains match; if DB schema is missing columns fall back to raw SQL
            cat = None
            cat_id = None
            # Detect whether this request is asking for carb-like categories so
            # we can explicitly exclude desserts at the DB level (protects
            # against mis-labelled rows in FoodMenu).
            is_carb_request = any(t in cat_lower for t in ['carb', 'carbo', 'carb', 'คาร์โบ', 'คาร์โบไฮเดรต', 'ข้าว', 'แป้ง', 'เส้น', 'rice', 'noodle', 'pasta', 'bread'])
            try:
                cat = FoodCategory.query.filter(func.lower(FoodCategory.name) == cat_lower).first()
                if not cat:
                    cat = FoodCategory.query.filter(func.lower(FoodCategory.name).like(f"%{cat_lower}%")).first()
                if cat:
                    cat_id = cat.id
            except Exception:
                from sqlalchemy import text
                # fallback: query only id and name using raw SQL to avoid ORM column mismatches
                res = db.session.execute(text("SELECT id, name FROM food_categories WHERE lower(name)=:n LIMIT 1"), {'n': cat_lower}).first()
                if res:
                    cat_id = res[0]

            # 3) grouped keywords: "ครบ 5 หมู่" => return union of typical five-group categories
            if cat_id is None:
                if any(t in cat_lower for t in ['ครบ 5', '5 หมู่', 'อาหารครบ']):
                    from sqlalchemy import text
                    res = db.session.execute(text("SELECT id, name FROM food_categories")).fetchall()
                    keep = []
                    keys = ['protein', 'โปรตีน', 'ผัก', 'ผลไม้', 'vegetable', 'carb', 'คาร์โบไฮเดรต', 'แป้ง', 'fat', 'ไขมัน', 'นม', 'dairy']
                    for r in res:
                        cid, cname = r[0], (r[1] or '')
                        name_l = cname.lower()
                        if any(k in name_l for k in keys):
                            keep.append(cid)
                    if keep:
                        q = q.filter(FoodMenu.category_id.in_(keep))
                    else:
                        return jsonify({'items': []})

            # 4) weight-loss / ลดน้ำหนัก
            if cat_id is None and any(t in cat_lower for t in ['ลดน้ำหนัก', 'weight']):
                from sqlalchemy import text
                res = db.session.execute(text("SELECT id, name FROM food_categories")).fetchall()
                keep = [r[0] for r in res if any(k in (r[1] or '').lower() for k in ['ลดน้ำหนัก', 'weight', 'low'])]
                if keep:
                    q = q.filter(FoodMenu.category_id.in_(keep))
                else:
                    return jsonify({'items': []})

            # 5) muscle building / สร้างกล้าม
            if cat_id is None and any(t in cat_lower for t in ['สร้างกล้าม', 'กล้าม', 'muscle']):
                from sqlalchemy import text
                res = db.session.execute(text("SELECT id, name FROM food_categories")).fetchall()
                keep = [r[0] for r in res if any(k in (r[1] or '').lower() for k in ['กล้าม', 'muscle', 'build', 'สร้าง'])]
                if keep:
                    q = q.filter(FoodMenu.category_id.in_(keep))
                else:
                    return jsonify({'items': []})

            # 6) default: if we found a single matching category earlier, filter by it
            if cat_id is not None:
                q = q.filter(FoodMenu.category_id == cat_id)

            # If caller requested carb-like category, ensure we exclude desserts
            # from the FoodMenu results. Prefer the explicit `is_dessert` column
            # if available; otherwise fall back to excluding names present in
            # the DessertMenu table.
            if is_carb_request:
                try:
                    if hasattr(FoodMenu, 'is_dessert'):
                        q = q.filter(FoodMenu.is_dessert == False)
                    else:
                        # Fallback: exclude any FoodMenu whose name also exists in DessertMenu
                        try:
                            dessert_names = [d[0] for d in DessertMenu.query.with_entities(DessertMenu.dessert_name).all()]
                            if dessert_names:
                                q = q.filter(~FoodMenu.name.in_(dessert_names))
                        except Exception:
                            # If querying DessertMenu fails, don't break the request; just log.
                            app.logger.exception('Failed to query DessertMenu for fallback exclusion')
                except Exception:
                    app.logger.exception('Failed to apply dessert exclusion for carb category')

        items = q.order_by(FoodMenu.name.asc()).limit(500).all()
        return jsonify({'items': [m.name for m in items]})
    except Exception:
        app.logger.exception('Failed to fetch menus')
        return jsonify({'items': []}), 500


@limiter.limit("30 per minute")
@app.route('/drink-menus', methods=['GET'])
def get_drink_menus():
    """Return drink menu names, optionally filtered by drink type via ?type=..."""
    try:
        dtype = (request.args.get('type') or '').strip()
        q = DrinkMenu.query

        if dtype:
            dt = DrinkType.query.filter(func.lower(DrinkType.name) == dtype.lower()).first()
            if not dt:
                return jsonify({'items': []})
            q = q.filter(DrinkMenu.drink_type_id == dt.id)

        items = q.order_by(DrinkMenu.name.asc()).limit(500).all()
        return jsonify({'items': [m.name for m in items]})
    except Exception:
        app.logger.exception('Failed to fetch drink menus')
        return jsonify({'items': []}), 500


@limiter.limit("30 per minute")
@app.route('/desserts', methods=['GET'])
def get_desserts():
    """Return desserts list. Optionally allow category filter via ?category=."""
    try:
        # There is a dedicated DessertMenu table; simply return names (optionally could filter by category later)
        items = DessertMenu.query.order_by(DessertMenu.dessert_name.asc()).limit(500).all()
        return jsonify({'items': [d.name for d in items]})
    except Exception:
        app.logger.exception('Failed to fetch desserts')
        return jsonify({'items': []}), 500


@limiter.limit("30 per minute")
@app.route('/menu-info', methods=['POST'])
def menu_info():
    """Batch lookup for menu names -> calories.

    Request JSON: { "names": ["Name1", "Name2"] }
    Response JSON: { "items": [{"name": "Name1", "kcal": 123}, ...] }
    """
    try:
        if not request.is_json:
            return jsonify({'error': 'JSON body required'}), 400
        data = request.get_json(silent=True) or {}
        names = data.get('names') or []
        if not isinstance(names, list):
            return jsonify({'error': 'names must be list'}), 400

        out = []
        for n in names:
            if not n or not isinstance(n, str):
                out.append({'name': n, 'kcal': None})
                continue
            name = n.strip()
            # try exact match case-insensitive on DessertMenu first
            try:
                d = DessertMenu.query.filter(func.lower(DessertMenu.dessert_name) == name.lower()).first()
                if d:
                    out.append({'name': name, 'kcal': d.calories})
                    continue
            except Exception:
                app.logger.exception('dessert lookup failed')

            try:
                f = FoodMenu.query.filter(func.lower(FoodMenu.name) == name.lower()).first()
                if f:
                    out.append({'name': name, 'kcal': f.calories})
                    continue
            except Exception:
                app.logger.exception('food lookup failed')

            # not found
            out.append({'name': name, 'kcal': None})

        return jsonify({'items': out})
    except Exception:
        app.logger.exception('menu-info failed')
        return jsonify({'items': []}), 500

@limiter.limit("10 per minute")
@app.route('/add-menu', methods=['POST'])
def add_menu():
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401

    token = auth.split(' ', 1)[1].strip()
    user = User.query.filter_by(password_token=token).first()

    if not user or not token_valid_for_user(user, token):
        return jsonify({'error': 'invalid or expired token'}), 401

    if not user or not user.is_admin:
        return jsonify({'error': 'admin only'}), 403

    data = request.json or {}
    food_category_id = data.get('food_category_id')
    name = data.get('name')
    calories = data.get('calories')

    if not food_category_id or not name:
        return jsonify({'error': 'food_category_id and name required'}), 400

    category = FoodCategory.query.get(food_category_id)
    if not category:
        return jsonify({'error': 'invalid food_category_id'}), 400

    try:
        calories = int(calories) if calories is not None else None
    except ValueError:
        return jsonify({'error': 'calories must be number'}), 400

    try:
        menu = FoodMenu(
            category_id=food_category_id,
            name=name,
            calories=calories
        )
        db.session.add(menu)
        db.session.commit()
    except Exception:
        db.session.rollback()
        return jsonify({'error': 'database error'}), 500

    return jsonify({
        'status': 'ok',
        'id': menu.id,
        'name': menu.name
    })
    
@limiter.limit("20 per minute")
@app.route('/history/anon/<string:anon_id>', methods=['GET'])
def get_anon_history(anon_id):
    """Return submissions for an anonymous id."""
    subs = Submission.query.filter_by(anon_id=anon_id).order_by(Submission.created_at.asc()).all()
    items = []
    for s in subs:
        data_field = s.data
        try:
            if isinstance(data_field, str):
                parsed = json.loads(data_field)
                data_field = parsed
        except Exception:
            pass
        items.append({'id': s.id, 'data': data_field, 'created_at': s.created_at.isoformat()})
    return jsonify({'history': items})

@limiter.limit("10 per minute")
@app.route('/report', methods=['POST'])
def report():
    # Ensure JSON
    if not request.is_json:
        return jsonify({'error': 'invalid content type'}), 400

    data = request.get_json() or {}
    user_id = data.get('user_id')
    rtype = (data.get('type') or '').strip()
    detail = (data.get('detail') or '').strip()

    # Validate required fields
    if not rtype or not detail:
        return jsonify({'error': 'type and detail are required'}), 400

    # Length validation
    if len(rtype) > 100:
        return jsonify({'error': 'type too long (max 100 characters)'}), 400

    if len(detail) > 2000:
        return jsonify({'error': 'detail too long (max 2000 characters)'}), 400

    # If user_id provided, require valid token
    if user_id is not None:
        auth = request.headers.get('Authorization') or ''
        if not auth.startswith('Bearer '):
            return jsonify({'error': 'authorization required'}), 401

        token = auth.split(' ', 1)[1].strip()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'user not found'}), 404

        if not token_valid_for_user(user, token):
            return jsonify({'error': 'invalid or expired token'}), 401

    # Save report safely
    try:
        rep = Report(
            user_id=user_id,
            type=rtype,
            detail=detail
        )
        db.session.add(rep)
        db.session.commit()
        return jsonify({'status': 'reported', 'id': rep.id}), 201

    except Exception:
        db.session.rollback()
        return jsonify({'error': 'database error'}), 500

@limiter.limit("20 per minute")
@app.route('/submit', methods=['POST'])
def submit():
    """Accept a submission payload.

    JSON accepted:
      - Registered user:
        {
          "user_id": <int>,
          "data": {...}
        }
        Requires: Authorization: Bearer <token>

      - Anonymous:
        {
          "anon_id": "<client-generated-id>",
          "data": {...}
        }
        Server enforces one submission per anon_id
    """

    # Ensure JSON
    if not request.is_json:
        return jsonify({'error': 'JSON body required'}), 400

    data = request.get_json(silent=True) or {}
    user_id = data.get('user_id')
    anon_id = data.get('anon_id')
    payload = data.get('data')

    # Validate payload format
    if not isinstance(payload, dict):
        return jsonify({'error': 'data must be an object'}), 400

    

    # =========================
    # REGISTERED USER FLOW
    # =========================
    if user_id is not None:

        # Validate user_id type
        try:
            user_id = int(user_id)
        except (TypeError, ValueError):
            return jsonify({'error': 'user_id must be integer'}), 400

        # Check Authorization header
        auth = request.headers.get('Authorization') or ''
        if not auth.startswith('Bearer '):
            return jsonify({'error': 'authorization required'}), 401

        token = auth.split(' ', 1)[1].strip()

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'user not found'}), 404

        if not token_valid_for_user(user, token):
            return jsonify({'error': 'invalid or expired token'}), 401

        # Save submission
        s = Submission(
            user_id=user.id,
            anon_id=None,
            data=json.dumps(payload)
        )

        db.session.add(s)
        try:
            db.session.commit()
        except Exception:
            db.session.rollback()
            return jsonify({'error': 'database error'}), 500

        return jsonify({'status': 'ok', 'id': s.id}), 201

    # =========================
    # ANONYMOUS FLOW
    # =========================
    if not anon_id:
        return jsonify({'error': 'anon_id required for anonymous submission'}), 400

    if not isinstance(anon_id, str):
        return jsonify({'error': 'anon_id must be string'}), 400

    if len(anon_id) > 100:
        return jsonify({'error': 'anon_id too long'}), 400

    # Check duplicate
    existing = Submission.query.filter_by(anon_id=anon_id).first()
    if existing:
        return jsonify({'error': 'anonymous submission already used'}), 403

    s = Submission(
        user_id=None,
        anon_id=anon_id,
        data=json.dumps(payload)
    )

    db.session.add(s)

    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        return jsonify({'error': 'anonymous submission already used'}), 403
    except Exception:
        db.session.rollback()
        return jsonify({'error': 'database error'}), 500

    return jsonify({'status': 'ok', 'id': s.id}), 201

@limiter.limit("30 per minute")
@app.route('/anon-status/<string:anon_id>', methods=['GET'])
def anon_status(anon_id):
    """Return whether an anonymous id may still submit (true/false).

    Frontend can call this to show immediate feedback before attempting a POST.
    """
    
    existing = Submission.query.filter_by(anon_id=anon_id).first()
    return jsonify({'can_submit': existing is None})

@limiter.limit("5 per minute")
@app.route('/export/history/<int:user_id>', methods=['GET'])
def export_history_csv(user_id):
    # require token
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401
    token = auth.split(' ', 1)[1].strip()
    user = User.query.get_or_404(user_id)
    if not token_valid_for_user(user, token):
        return jsonify({'error': 'invalid or expired token'}), 401
    histories = []
    for h in user.histories:
        histories.append({'id': h.id, 'user_id': h.user_id, 'created_at': h.created_at.isoformat(), 'data': h.data})
    csv_bytes = csv_utils.histories_to_csv_bytes(histories)
    # ส่งเป็น attachment สำหรับดาวน์โหลด
    return Response(
        csv_bytes,
        mimetype='text/csv; charset=utf-8',
        headers={
            'Content-Disposition': f'attachment; filename=history_user_{user_id}.csv'
        }
    )

@limiter.limit("20 per minute")
@app.route('/history/<int:user_id>', methods=['GET'])
def get_history(user_id):

    # Require token
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401

    token = auth.split(' ', 1)[1].strip()
    user = User.query.get_or_404(user_id)

    if not token_valid_for_user(user, token):
        return jsonify({'error': 'invalid or expired token'}), 401

    histories = []

    for h in user.histories:
        # If stored as JSON text, try to parse back to object for API
        data_field = h.data
        try:
            if isinstance(data_field, str):
                parsed = json.loads(data_field)
                data_field = parsed
        except Exception:
            # keep raw value if parsing fails
            pass

        histories.append({
            'id': h.id,
            'user_id': h.user_id,
            'created_at': h.created_at.isoformat(),
            'data': data_field
        })

    return jsonify({'history': histories}), 200


@limiter.limit("20 per minute")
@app.route('/save-partial-selection', methods=['POST'])
def save_partial_selection():
    """
    Save a partial selection (no meal/duration required) as a History record.
    Requires Authorization: Bearer <token>
    """

    auth_header = request.headers.get("Authorization") or ""
    if not auth_header.startswith("Bearer "):
        return jsonify({"error": "authorization required"}), 401

    token = auth_header.split(" ", 1)[1].strip()

    try:
        user = User.query.filter_by(password_token=token).first()
    except Exception:
        app.logger.exception("Token lookup failed")
        return jsonify({"error": "database error"}), 500

    if not user or not token_valid_for_user(user, token):
        return jsonify({"error": "invalid or expired token"}), 401

    if not request.is_json:
        return jsonify({"error": "JSON body required"}), 400

    data = request.get_json(silent=True) or {}

    try:
        h = save_history_record(user.id, data)
        return jsonify({"status": "saved", "history_id": h.id}), 201
    except Exception:
        app.logger.exception('Partial history insert failed for user %s', user.id)
        return jsonify({"error": "database error"}), 500

@limiter.limit("3 per minute")
@app.route('/export/history/<int:user_id>/excel', methods=['GET'])
def export_history_excel(user_id):
    # ใช้ pandas/openpyxl ถ้ามี
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401
    token = auth.split(' ', 1)[1].strip()
    user = User.query.get_or_404(user_id)
    if not token_valid_for_user(user, token):
        return jsonify({'error': 'invalid or expired token'}), 401
    histories = []
    for h in user.histories:
        histories.append({'id': h.id, 'user_id': h.user_id, 'created_at': h.created_at.isoformat(), 'data': h.data})
    try:
        excel_bytes = csv_utils.histories_to_excel_bytes(histories)
    except RuntimeError:
        return jsonify({'error': 'pandas required for excel export'}), 400
    return Response(
        excel_bytes,
        mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        headers={'Content-Disposition': f'attachment; filename=history_user_{user_id}.xlsx'}
    )

@limiter.limit("5 per minute")
@app.route('/import/users', methods=['POST'])
def import_users():
    """
    Admin only.
    Expect multipart/form-data with file field 'file' (CSV)
    CSV headers: username,email,password (password optional)
    """

    # =========================
    # 🔐 1. Require Admin Token
    # =========================
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401

    token = auth.split(' ', 1)[1].strip()
    admin_user = User.query.filter_by(password_token=token).first()

    if not admin_user or not admin_user.is_admin or not token_valid_for_user(admin_user, token):
        return jsonify({'error': 'admin only'}), 403

    # =========================
    # 📁 2. Validate File
    # =========================
    file = request.files.get('file')
    if not file:
        return jsonify({'error': 'file required'}), 400

    if not file.filename.lower().endswith('.csv'):
        return jsonify({'error': 'only csv allowed'}), 400

    try:
        data = file.read()
        users = csv_utils.csv_bytes_to_users_list(data)
    except Exception:
        app.logger.exception("Invalid CSV during import_users")
        return jsonify({'error': 'invalid csv'}), 400

    created = []
    skipped = []

    # =========================
    # 👤 3. Process Users
    # =========================
    for u in users:
        username = (u.get('username') or '').strip()
        email = (u.get('email') or '').strip()

        if not username:
            skipped.append({'reason': 'missing username'})
            continue

        if User.query.filter(func.lower(User.username) == username.lower()).first():
            skipped.append({'username': username, 'reason': 'already exists'})
            continue

        pwd = u.get('password')

        # 🔐 Validate or generate password
        if pwd:
            if len(pwd) < 8:
                skipped.append({'username': username, 'reason': 'weak password'})
                continue

            if not re.search(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])', pwd):
                skipped.append({'username': username, 'reason': 'weak password'})
                continue
        else:
            pwd = secrets.token_urlsafe(12)

        try:
            token = secrets.token_urlsafe(32)

            user = User(
                username=username,
                email=email,
                password_hash=generate_password_hash(pwd),
                password_token=token,
                token_created_at=datetime.now(timezone.utc)
            )

            db.session.add(user)
            db.session.commit()   # ✅ commit ทีละ user

            created.append({
                'id': user.id,
                'username': user.username
            })

        except Exception:
            app.logger.exception("DB error during user import")
            db.session.rollback()
            skipped.append({'username': username, 'reason': 'db error'})

    return jsonify({
        'created': created,
        'created_count': len(created),
        'skipped': skipped,
        'skipped_count': len(skipped)
    })

@limiter.limit("3 per minute")
@app.route('/forgot-password', methods=['POST'])
def forgot_password():

    print("🔥 FORGOT PASSWORD ENDPOINT CALLED")

    time.sleep(0.8)

    if not request.is_json:
        print("❌ Not JSON")
        return jsonify({'error': 'Invalid JSON format. Please provide a valid JSON object.'}), 400

    data = request.get_json(silent=True) or {}
    print("📦 Received JSON:", data)

    username = (data.get('username') or '').strip()
    email = (data.get('email') or '').strip()

    print("👤 Username:", username)
    print("📧 Email:", email)

    if not username or not email:
        print("❌ Missing username or email")
        return jsonify({'error': 'Both username and email must be provided.'}), 400

    # Exact match on email (case-insensitive)
    user = User.query.filter(
        func.lower(User.username) == username.lower(),
        func.lower(User.email) == email.lower()
    ).first()

    if not user:
        print("❌ User not found")
        return jsonify({'error': 'ไม่พบชื่อผู้ใช้'}), 404

    try:
        # Generate a raw reset token and a 6-digit OTP. Store only hashes.
        reset_token = secrets.token_urlsafe(32)
        otp = f"{secrets.randbelow(10**6):06d}"
        app.logger.info("GENERATING RESET TOKEN+OTP for user id=%s", user.id)

        # Use HMAC-SHA256 with server secret to hash token and otp
        secret = current_app.config.get('SECRET_KEY', '')
        if not secret:
            app.logger.error('SECRET_KEY not set; cannot generate reset hashes')
            return jsonify({'error': 'server configuration error'}), 500

        token_hmac = hmac.new(secret.encode('utf-8'), reset_token.encode('utf-8'), hashlib.sha256).hexdigest()
        otp_hmac = hmac.new(secret.encode('utf-8'), otp.encode('utf-8'), hashlib.sha256).hexdigest()

        # Persist hashes and expiries (token 15 minutes, otp 5 minutes)
        user.reset_token_hash = token_hmac
        user.reset_token_expires_at = datetime.utcnow() + timedelta(minutes=15)
        user.reset_otp_hash = otp_hmac
        user.reset_otp_expires_at = datetime.utcnow() + timedelta(minutes=5)
        user.reset_otp_attempts = 0

        db.session.commit()

        # Double-check persistence
        persisted = User.query.get(user.id)
        if not persisted or not persisted.reset_token_hash or not persisted.reset_otp_hash:
            app.logger.error('Failed to persist reset_token_hash/reset_otp_hash for user id=%s', user.id)
            return jsonify({'error': 'Failed to generate reset credentials'}), 500

        app.logger.info('Reset token+otp stored for user id=%s expires=%s/%s', user.id, persisted.reset_token_expires_at, persisted.reset_otp_expires_at)

    except Exception as e:
        db.session.rollback()
        app.logger.exception("Error saving reset token for user id=%s: %s", user.id if user else None, e)
        return jsonify({'error': 'Failed to generate reset token, please try again later.'}), 500

    # Return the plain token only in debug/testing mode. In production
    # do NOT return or log the raw token; it must be sent via email only.
    if not reset_token:
        app.logger.error('Generated reset_token is empty for user id=%s', user.id)
        return jsonify({'error': 'Failed to generate reset token'}), 500

    if app.debug:
        # For testing only: return username, email, reset token and OTP
        app.logger.info('Returning reset_token and otp in debug response for user id=%s', user.id)
        return jsonify({
            'status': 'ok',
            'username': user.username,
            'email': user.email,
            'reset_token': reset_token,
            'otp': otp
        }), 200
    else:
        # Production: do NOT return token or otp in response. Send via email instead.
        app.logger.info('Reset credentials generated for user id=%s (not returned in response)', user.id)
        return jsonify({'status': 'ok'}), 200

@limiter.limit("5 per minute")
@app.route('/reset-password', methods=['POST'])
def reset_password():
    import time
    time.sleep(0.5)  # Mitigate timing attacks

    if not request.is_json:
        return jsonify({'error': 'JSON body required'}), 400

    data = request.json or {}
    reset_token = (data.get('reset_token') or '').strip()
    new_password = data.get('new_password') or ''

    # Accept username and email in the request for additional verification,
    # but do NOT use them to identify the user when updating the DB.
    username = (data.get('username') or '').strip()
    email = (data.get('email') or '').strip()

    # Reject other disallowed fields that should never be provided here
    forbidden_keys = {'user_id', 'password_token', 'auth_token', 'token'}
    present_forbidden = forbidden_keys.intersection(set(k.lower() for k in data.keys()))
    if present_forbidden:
        app.logger.warning('reset-password called with forbidden keys: %s', present_forbidden)
        return jsonify({'error': 'invalid request fields'}), 400

    # Reject Authorization header for this endpoint (token must be in body)
    if request.headers.get('Authorization'):
        app.logger.warning('reset-password called with Authorization header')
        return jsonify({'error': 'authorization not allowed for this endpoint'}), 400

    # Enforce required fields: reset_token and new_password
    if not reset_token:
        return jsonify({'error': 'reset_token required'}), 400
    if not new_password:
        return jsonify({'error': 'new_password required'}), 400

    # Password length and strength validation
    if len(new_password) < 8:
        return jsonify({'error': 'password must be at least 8 characters long'}), 400

    if not re.search(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])', new_password):
        return jsonify({
            'error': 'password must include uppercase, lowercase, number, and special character'
        }), 400

    user = None
    # Token-only flow
    otp = (data.get('otp') or '').strip()

    if reset_token:
        # Basic token sanity check
        if len(reset_token) < 16:
            return jsonify({'error': 'invalid token'}), 400

        # Hash the provided token using HMAC-SHA256 with server secret (constant-time comparisons later)
        secret = current_app.config.get('SECRET_KEY', '')
        if not secret:
            app.logger.error('SECRET_KEY not set; cannot verify reset token')
            return jsonify({'error': 'server configuration error'}), 500
        hashed_token = hmac.new(secret.encode('utf-8'), reset_token.encode('utf-8'), hashlib.sha256).hexdigest()

        # Ensure token hash maps to a single user (sanity check)
        try:
            dup_count = db.session.query(User).filter_by(reset_token_hash=hashed_token).count()
        except Exception:
            app.logger.exception('DB error during token duplicate check')
            return jsonify({'error': 'database error'}), 500

        if dup_count == 0:
            return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400
        if dup_count > 1:
            app.logger.error('reset_token hash duplicated in DB (count=%s)', dup_count)
            return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400

        # Look up the user by reset_token hash and lock the row to prevent reuse
        try:
            user = db.session.query(User).filter_by(reset_token_hash=hashed_token).with_for_update().first()
        except Exception:
            app.logger.exception('DB error during token lookup')
            return jsonify({'error': 'database error'}), 500

        if not user:
            return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400

        # Check if the token has expired (normalize timezone awareness)
        expires = user.reset_token_expires_at
        if not expires:
            return jsonify({'error': 'โทเคนหมดอายุ'}), 400
        # If stored datetime is naive, assume UTC
        try:
            if expires.tzinfo is None:
                expires = expires.replace(tzinfo=timezone.utc)
        except Exception:
            pass

        if datetime.now(timezone.utc) > expires:
            return jsonify({'error': 'โทเคนหมดอายุ'}), 400


        # Additional strict check: ensure the stored token hash exactly matches (constant-time)
        try:
            if not hmac.compare_digest((user.reset_token_hash or ''), hashed_token):
                return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400
        except Exception:
            return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400

        # OTP must be present
        if not otp:
            return jsonify({'error': 'otp required'}), 400

        # Check OTP attempts
        try:
            attempts = int(user.reset_otp_attempts or 0)
        except Exception:
            attempts = 0
        if attempts >= 5:
            # Exceeded attempts -> clear token and otp
            user.reset_token_hash = None
            user.reset_token_expires_at = None
            user.reset_otp_hash = None
            user.reset_otp_expires_at = None
            user.reset_otp_attempts = 0
            db.session.commit()
            return jsonify({'error': 'OTP attempts exceeded'}), 400

        # Verify OTP hash (constant-time)
        otp_hmac_candidate = hmac.new(secret.encode('utf-8'), otp.encode('utf-8'), hashlib.sha256).hexdigest()
        otp_ok = False
        try:
            if user.reset_otp_hash and hmac.compare_digest(user.reset_otp_hash, otp_hmac_candidate):
                otp_ok = True
        except Exception:
            otp_ok = False

        # Check OTP expiry
        otp_expires = user.reset_otp_expires_at
        if not otp_expires:
            # treat as expired
            otp_ok = False
        else:
            try:
                if otp_expires.tzinfo is None:
                    otp_expires = otp_expires.replace(tzinfo=timezone.utc)
            except Exception:
                pass
            if datetime.now(timezone.utc) > otp_expires:
                otp_ok = False

        if not otp_ok:
            # increment attempts
            try:
                user.reset_otp_attempts = (int(user.reset_otp_attempts or 0) + 1)
                db.session.commit()
            except Exception:
                db.session.rollback()
            # If attempts reached limit, clear creds
            try:
                if int(user.reset_otp_attempts or 0) >= 5:
                    user.reset_token_hash = None
                    user.reset_token_expires_at = None
                    user.reset_otp_hash = None
                    user.reset_otp_expires_at = None
                    user.reset_otp_attempts = 0
                    db.session.commit()
            except Exception:
                db.session.rollback()
            return jsonify({'error': 'invalid otp'}), 400

    # Now that we found the user from the token, verify provided username/email
    if username and username.lower() != (user.username or '').lower():
        return jsonify({'error': 'โทเคนนี้ไม่ตรงกับบัญชีที่ทำการขอรีเซ็ตรหัสผ่าน'}), 400
    if email and email.lower() != (user.email or '').lower():
        return jsonify({'error': 'โทเคนนี้ไม่ตรงกับบัญชีที่ทำการขอรีเซ็ตรหัสผ่าน'}), 400

    # **Check if the new password is the same as the current password**
    if check_password_hash(user.password_hash, new_password):
        return jsonify({'error': 'new password cannot be the same as the current password'}), 400

    try:
        # Set the new password after hashing it
        user.password_hash = generate_password_hash(new_password)

        # Clear the reset token and its expiration time, and OTP fields
        user.reset_token_hash = None
        user.reset_token_expires_at = None
        user.reset_otp_hash = None
        user.reset_otp_expires_at = None
        user.reset_otp_attempts = 0

        # Rotate the login token for security
        user.password_token = secrets.token_urlsafe(32)
        user.token_created_at = datetime.now(timezone.utc)

        db.session.commit()

        # Log success
        current_app.logger.info(f"Password for user {user.username} reset successfully.")

    except Exception as e:
        db.session.rollback()
        current_app.logger.exception(f"Error resetting password for user {user.username}: {e}")
        return jsonify({'error': 'database error'}), 500

    return jsonify({'status': 'password reset successful'}), 200


@limiter.limit("10 per minute")
@app.route('/reset-token-info', methods=['POST'])
def reset_token_info():
    """Given a reset_token (plain from email), return the username and a masked
    email for the account that the token grants access to.

    This endpoint proves possession of the token and is intended for the
    frontend reset page to confirm which account the token belongs to.
    """

    if not request.is_json:
        return jsonify({'error': 'JSON body required'}), 400

    data = request.get_json(silent=True) or {}
    reset_token = (data.get('reset_token') or '').strip()

    if not reset_token or len(reset_token) < 16:
        return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400

    # Do not accept Authorization header for this flow
    if request.headers.get('Authorization'):
        return jsonify({'error': 'authorization not allowed'}), 400

    secret = current_app.config.get('SECRET_KEY', '')
    if not secret:
        app.logger.error('SECRET_KEY not set; cannot verify reset token')
        return jsonify({'error': 'server configuration error'}), 500
    hashed_token = hmac.new(secret.encode('utf-8'), reset_token.encode('utf-8'), hashlib.sha256).hexdigest()

    try:
        user = db.session.query(User).filter_by(reset_token_hash=hashed_token).first()
    except Exception:
        app.logger.exception('DB error during reset-token-info lookup')
        return jsonify({'error': 'database error'}), 500

    if not user:
        return jsonify({'error': 'โทเคนไม่ถูกต้อง'}), 400

    # Check expiry
    expires = user.reset_token_expires_at
    if not expires:
        return jsonify({'error': 'โทเคนหมดอายุ'}), 400
    try:
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
    except Exception:
        pass


@limiter.limit("30 per minute")
@app.route('/user-selections/<int:user_id>', methods=['GET'])
def get_user_selections(user_id):
    """Return user's selections with resolved menu/dessert/drink names."""
    auth = request.headers.get('Authorization') or ''
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'authorization required'}), 401

    token = auth.split(' ', 1)[1].strip()
    user = User.query.get_or_404(user_id)
    if not token_valid_for_user(user, token):
        return jsonify({'error': 'invalid or expired token'}), 401

    try:
        items = []
        sels = UserSelection.query.filter_by(user_id=user.id).order_by(UserSelection.created_at.asc()).all()
        for s in sels:
            name = None
            item_type = None
            details = None
            if s.menu:
                name = s.menu.name
                item_type = 'menu'
                details = {'id': s.menu.id, 'calories': s.menu.calories}
            elif s.dessert:
                name = s.dessert.name
                item_type = 'dessert'
                details = {'id': s.dessert.id, 'calories': s.dessert.calories}
            elif s.drink_menu:
                name = s.drink_menu.name
                item_type = 'drink'
                details = {'id': s.drink_menu.id}

            items.append({
                'id': s.id,
                'created_at': s.created_at.isoformat(),
                'meal': s.meal,
                'duration': s.duration,
                'type': item_type,
                'name': name,
                'details': details
            })

        return jsonify({'selections': items}), 200
    except Exception:
        app.logger.exception('Failed to fetch user selections')
        return jsonify({'selections': []}), 500

    if datetime.now(timezone.utc) > expires:
        return jsonify({'error': 'โทเคนหมดอายุ'}), 400

    # Mask email for privacy: show first char and domain, e.g. j****@example.com
    def mask_email(e):
        try:
            if not e or '@' not in e:
                return ''
            local, domain = e.split('@', 1)
            if len(local) <= 1:
                mlocal = '*'
            else:
                mlocal = local[0] + '*' * (min(4, max(1, len(local)-1)))
            return f"{mlocal}@{domain}"
        except Exception:
            return ''

    return jsonify({
        'username': user.username,
        'email': mask_email(user.email)
    }), 200


@limiter.limit("30 per minute")
@app.route('/me', methods=['GET'])
def me():
    auth_header = request.headers.get('Authorization')

    print("AUTH HEADER:", auth_header)

    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({'error': 'Missing token'}), 401

    token = auth_header.split(" ")[1]

    print("TOKEN EXTRACTED:", token)

    user = User.query.filter_by(password_token=token).first()

    print("USER FOUND:", user)

    if not user:
        return jsonify({'error': 'Invalid token'}), 401

    return jsonify({
        "id": user.id,
        "username": user.username,
        "email": user.email
    })

@limiter.limit("5 per minute")
@app.route('/change-password', methods=['POST'])
def change_password():
    # Change-password: support two modes
    # 1) Authenticated: Authorization: Bearer <password_token> (existing flow)
    # 2) Unauthenticated: provide username/email + old_password in JSON
    auth_header = request.headers.get('Authorization') or ''

    # Require JSON body
    if not request.is_json:
        return jsonify({'error': 'JSON body required'}), 400

    data = request.get_json() or {}

    user = None
    token = None
    # Attempt authenticated flow first if Authorization header provided
    if auth_header.startswith('Bearer '):
        token = auth_header.split(' ', 1)[1].strip()
        if token:
            try:
                user = User.query.filter_by(password_token=token).first()
            except Exception:
                app.logger.exception('DB error during password_token lookup')
                return jsonify({'error': 'database error'}), 500

            if not user or not token_valid_for_user(user, token):
                # Invalid token supplied — do not fail immediately; allow fallback
                # to username/email + old_password flow if present in the request.
                app.logger.info('Invalid or expired Authorization token provided; falling back to credential verification')
                user = None
                token = None

    # If no Authorization or token flow didn't resolve a user, try username/email + old_password
    if not user:
        username = (data.get('username') or '').strip()
        email = (data.get('email') or '').strip()
        old_password = data.get('old_password') or ''

        if not old_password or (not username and not email):
            return jsonify({'error': 'authorization required or provide username/email+old_password'}), 401

        # Lookup by email if contains @ else username (case-insensitive)
        try:
            if '@' in (username or ''):
                q = func.lower(User.email) == username.lower()
                user = User.query.filter(q).first()
            elif email:
                user = User.query.filter(func.lower(User.email) == email.lower()).first()
            else:
                user = User.query.filter(func.lower(User.username) == username.lower()).first()
        except Exception:
            app.logger.exception('DB lookup failed during unauthenticated change-password')
            return jsonify({'error': 'database error'}), 500

        if not user:
            return jsonify({'error': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'}), 401

        # Verify provided old password
        if not check_password_hash(user.password_hash, old_password):
            return jsonify({'error': 'invalid current password'}), 401

    # By here we have a valid `user` object (either via token or username+old_password)
    new_password = data.get('new_password') or ''

    if not new_password:
        return jsonify({'error': 'new_password required'}), 400

    # Password policy
    if len(new_password) < 8:
        return jsonify({'error': 'password must be at least 8 characters long'}), 400

    if not re.search(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])', new_password):
        return jsonify({'error': 'password must include uppercase, lowercase, number, and special character'}), 400

    # Ensure new password is not the same as current
    try:
        if check_password_hash(user.password_hash, new_password):
            return jsonify({'error': 'new password cannot be the same as the current password'}), 400
    except Exception:
        pass

    try:
        user.password_hash = generate_password_hash(new_password)

        # Clear any reset token/expiry
        user.reset_token_hash = None
        user.reset_token_expires_at = None

        # Rotate login token (invalidate other sessions)
        user.password_token = secrets.token_urlsafe(32)
        user.token_created_at = datetime.now(timezone.utc)

        db.session.commit()
        current_app.logger.info('Password changed for user id=%s (auth header present=%s)', user.id, bool(token))
    except Exception as e:
        db.session.rollback()
        current_app.logger.exception('Error changing password for user id=%s: %s', getattr(user, 'id', None), e)
        return jsonify({'error': 'database error'}), 500

    return jsonify({'message': 'เปลี่ยนรหัสผ่านสำเร็จ'}), 200


@limiter.limit("20 per minute")
@app.route('/save-selection', methods=['POST'])
def save_selection():
    """
    Save user food selection + meal + duration
    Requires Authorization: Bearer <token>
    """

    # =========================
    # 1️⃣ AUTH CHECK
    # =========================
    auth_header = request.headers.get("Authorization") or ""
    if not auth_header.startswith("Bearer "):
        return jsonify({"error": "authorization required"}), 401

    token = auth_header.split(" ", 1)[1].strip()

    try:
        user = User.query.filter_by(password_token=token).first()
    except Exception:
        app.logger.exception("Token lookup failed")
        return jsonify({"error": "database error"}), 500

    if not user or not token_valid_for_user(user, token):
        return jsonify({"error": "invalid or expired token"}), 401

    # =========================
    # 2️⃣ REQUIRE JSON
    # =========================
    if not request.is_json:
        return jsonify({"error": "JSON body required"}), 400

    data = request.get_json(silent=True) or {}

    # Support both name-based and id-based payloads. ID takes precedence.
    selected_type = data.get("selectedType")
    selected_category = data.get("selectedCategory")
    selected_menu = data.get("selectedMenu")
    selected_dessert = data.get("selectedDessert")
    selected_drink_type = data.get("selectedDrinkType")
    selected_drink_menu = data.get("selectedDrinkMenu")

    # Numeric id fields (preferred when provided)
    menu_id_payload = data.get('menu_id')
    dessert_menu_id_payload = data.get('dessert_menu_id')
    drink_menu_id_payload = data.get('drink_menu_id')

    meal = (data.get("meal") or "").strip()
    duration = data.get("duration")

    if not meal:
        return jsonify({"error": "meal is required"}), 400

    try:
        duration = int(duration)
        if duration <= 0:
            raise ValueError
    except Exception:
        return jsonify({"error": "duration must be positive integer"}), 400

    # =========================
    # 3️⃣ MAP NAME/ID → ID (ID takes precedence)
    # =========================
    food_type = FoodType.query.filter_by(name=selected_type).first() if selected_type else None
    category = FoodCategory.query.filter_by(name=selected_category).first() if selected_category else None

    # Resolve menu by id if provided, otherwise by name
    menu = None
    if menu_id_payload is not None:
        try:
            mid = int(menu_id_payload)
            menu = FoodMenu.query.get(mid)
        except Exception:
            menu = None
    elif selected_menu:
        menu = FoodMenu.query.filter_by(name=selected_menu).first()

    # Resolve dessert by id if provided, otherwise by name
    dessert = None
    if dessert_menu_id_payload is not None:
        try:
            did = int(dessert_menu_id_payload)
            dessert = DessertMenu.query.get(did)
        except Exception:
            dessert = None
    elif selected_dessert:
        # DessertMenu schema has varied historically (some tables use `name`,
        # others use `dessert_name`). Be defensive: inspect available
        # columns and query by the present column to avoid OperationalError.
        dessert = None
        try:
            cols = DessertMenu.__table__.columns.keys()
        except Exception:
            cols = []

        try:
            if 'name' in cols:
                dessert = DessertMenu.query.filter_by(name=selected_dessert).first()
            elif 'dessert_name' in cols:
                dessert = DessertMenu.query.filter_by(dessert_name=selected_dessert).first()
            else:
                # Fallback: try case-insensitive match on either attribute
                try:
                    dessert = DessertMenu.query.filter(func.lower(DessertMenu.name) == selected_dessert.lower()).first()
                except Exception:
                    try:
                        dessert = DessertMenu.query.filter(func.lower(DessertMenu.dessert_name) == selected_dessert.lower()).first()
                    except Exception:
                        dessert = None
        except Exception:
            current_app.logger.exception('dessert lookup failed')
            dessert = None

    drink_type = DrinkType.query.filter_by(name=selected_drink_type).first() if selected_drink_type else None

    # Resolve drink menu by id if provided, otherwise by name
    drink_menu = None
    if drink_menu_id_payload is not None:
        try:
            dm = int(drink_menu_id_payload)
            drink_menu = DrinkMenu.query.get(dm)
        except Exception:
            drink_menu = None
    elif selected_drink_menu:
        drink_menu = DrinkMenu.query.filter_by(name=selected_drink_menu).first()

    # Validate if name provided but not found
    if selected_type and not food_type:
        return jsonify({"error": "invalid food type"}), 400

    if selected_category and not category:
        return jsonify({"error": "invalid category"}), 400

    if (selected_menu or menu_id_payload is not None) and not menu:
        return jsonify({"error": "invalid menu"}), 400

    if (selected_dessert or dessert_menu_id_payload is not None) and not dessert:
        return jsonify({"error": "invalid dessert"}), 400

    if selected_drink_type and not drink_type:
        return jsonify({"error": "invalid drink type"}), 400

    if selected_drink_menu and not drink_menu:
        return jsonify({"error": "invalid drink menu"}), 400

    # =========================
    # 4️⃣ SAVE TO DB
    # =========================
    try:
        selection = UserSelection(
            user_id=user.id,
            food_type_id=food_type.id if food_type else None,
            category_id=category.id if category else None,
            menu_id=menu.id if menu else None,
            dessert_menu_id=dessert.id if dessert else None,
            drink_type_id=drink_type.id if drink_type else None,
            drink_menu_id=drink_menu.id if drink_menu else None,
            meal=meal,
            duration=duration
        )

        db.session.add(selection)
        db.session.commit()

        # Also persist a History record so the frontend can retrieve full data
        try:
            save_history_record(user.id, data)
        except Exception:
            app.logger.exception('History insert failed for user %s', user.id)

        return jsonify({
            "status": "saved",
            "selection_id": selection.id
        }), 201

    except Exception:
        db.session.rollback()
        app.logger.exception("Save selection failed")
        return jsonify({"error": "database error"}), 500

@app.route('/db-info', methods=['GET'])
def db_info():
    # 🔒 อนุญาตเฉพาะตอน debug mode เท่านั้น
    if not app.debug:
        return jsonify({'error': 'forbidden'}), 403

    try:
        uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
        masked = uri

        try:
            if '//' in uri and ':' in uri.split('//', 1)[1]:
                parts = uri.split('//', 1)
                creds_host = parts[1]
                if '@' in creds_host:
                    cred, rest = creds_host.split('@', 1)
                    if ':' in cred:
                        user, _ = cred.split(':', 1)
                        masked = parts[0] + '//' + f"{user}:***@" + rest
        except Exception:
            masked = uri

    except Exception:
        masked = '<unknown>'

    info = {
        'db_uri': masked,
        'using_mysql': ('mysql' in app.config.get('SQLALCHEMY_DATABASE_URI', ''))
    }

    try:
        cnt = User.query.count()
        sample = [u.username for u in User.query.limit(5).all()]
        info.update({
            'users_count': cnt,
            'users_sample': sample
        })
    except Exception as e:
        info.update({
            'users_count': None,
            'users_sample': [],
            'error': str(e)
        })

    return jsonify(info)

# ALTER USER 'your_mysql_user'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_password';
# FLUSH PRIVILEGES;

if __name__ == '__main__':
    app.run(
        debug=True,
        use_reloader=True,
        host='0.0.0.0',
        port=5000
    )