from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timezone
from sqlalchemy import UniqueConstraint

db = SQLAlchemy()

# =========================
# USER MODEL
# =========================

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)

    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=True, index=True)

    password_hash = db.Column(db.String(512), nullable=False)

    # 🔐 Login token
    password_token = db.Column(db.String(255), nullable=True, unique=True, index=True)
    token_created_at = db.Column(db.DateTime, nullable=True)

    # 🔐 Temporary password
    temp_password_hash = db.Column(db.String(512), nullable=True)
    temp_password_expires_at = db.Column(db.DateTime, nullable=True)

    # 🔐 Reset password
    # Store only the hash of the reset token; unique to ensure a token maps to a single user
    reset_token_hash = db.Column(db.String(255), nullable=True, unique=True, index=True)
    reset_token_expires_at = db.Column(db.DateTime, nullable=True)
    # 🔐 Reset OTP (one-time numeric code)
    reset_otp_hash = db.Column(db.String(255), nullable=True)
    reset_otp_expires_at = db.Column(db.DateTime, nullable=True)
    # Count of failed OTP verification attempts
    reset_otp_attempts = db.Column(db.Integer, nullable=True, default=0)

    # 👑 Admin flag
    is_admin = db.Column(db.Boolean, default=False, nullable=False)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )

    # 👤 Profile
    gender = db.Column(db.String(10))
    age = db.Column(db.Integer)
    weight = db.Column(db.Float)
    height = db.Column(db.Float)

    # 🔗 Relationships
    histories = db.relationship(
        'History',
        backref='user',
        cascade="all, delete-orphan",
        lazy=True
    )

    submissions = db.relationship(
        'Submission',
        backref='user',
        cascade="all, delete-orphan",
        lazy=True
    )

    selections = db.relationship(
        'UserSelection',
        backref='user',
        cascade="all, delete-orphan",
        lazy=True
    )

    reports = db.relationship(
        'Report',
        backref='user',
        cascade="all, delete-orphan",
        lazy=True
    )


# =========================
# HISTORY TABLE
# =========================

class History(db.Model):
    __tablename__ = 'histories'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)

    data = db.Column(db.Text)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )


# =========================
# REPORT TABLE
# =========================

class Report(db.Model):
    __tablename__ = 'reports'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)

    type = db.Column(db.String(80))
    detail = db.Column(db.Text)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )


# =========================
# SUBMISSION TABLE
# =========================

class Submission(db.Model):
    __tablename__ = 'submissions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)

    anon_id = db.Column(db.String(255), unique=True, nullable=True, index=True)
    data = db.Column(db.Text)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )


# =========================
# FOOD TABLES
# =========================

class FoodType(db.Model):
    __tablename__ = "food_types"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False, index=True)

    categories = db.relationship("FoodCategory", backref="food_type", lazy=True)


class FoodCategory(db.Model):
    __tablename__ = "food_categories"

    id = db.Column(db.Integer, primary_key=True)

    food_type_id = db.Column(
        db.Integer,
        db.ForeignKey("food_types.id"),
        nullable=False,
        index=True
    )

    name = db.Column(db.String(150), nullable=False)

    menus = db.relationship("FoodMenu", backref="category", lazy=True)

    __table_args__ = (
        UniqueConstraint('food_type_id', 'name', name='uix_foodtype_name'),
    )


class FoodMenu(db.Model):
    __tablename__ = "food_menus"

    id = db.Column(db.Integer, primary_key=True)

    category_id = db.Column(
        db.Integer,
        db.ForeignKey("food_categories.id"),
        nullable=False,
        index=True
    )

    name = db.Column(db.String(200), nullable=False, index=True)

    calories = db.Column(db.Float)
    protein = db.Column(db.Float)
    carbs = db.Column(db.Float)
    fat = db.Column(db.Float)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )


# =========================
# DRINK TABLES
# =========================

class DrinkType(db.Model):
    __tablename__ = "drink_types"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), unique=True, nullable=False, index=True)

    menus = db.relationship("DrinkMenu", backref="drink_type", lazy=True)


class DrinkMenu(db.Model):
    __tablename__ = "drink_menus"

    id = db.Column(db.Integer, primary_key=True)

    drink_type_id = db.Column(
        db.Integer,
        db.ForeignKey("drink_types.id"),
        nullable=False,
        index=True
    )

    name = db.Column(db.String(200), nullable=False, index=True)

    calories = db.Column(db.Float)
    sugar = db.Column(db.Float)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )


# =========================
# DESSERT TABLE
# =========================

class DessertMenu(db.Model):
    __tablename__ = "dessert_menus"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False, index=True)

    calories = db.Column(db.Float)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )


# =========================
# USER SELECTION TABLE
# =========================

class UserSelection(db.Model):
    __tablename__ = "user_selections"

    id = db.Column(db.Integer, primary_key=True)

    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    food_type_id = db.Column(db.Integer, db.ForeignKey("food_types.id"), nullable=True, index=True)
    category_id = db.Column(db.Integer, db.ForeignKey("food_categories.id"), nullable=True, index=True)
    menu_id = db.Column(db.Integer, db.ForeignKey("food_menus.id"), nullable=True, index=True)
    dessert_menu_id = db.Column(db.Integer, db.ForeignKey("dessert_menus.id"), nullable=True, index=True)
    drink_type_id = db.Column(db.Integer, db.ForeignKey("drink_types.id"), nullable=True, index=True)
    drink_menu_id = db.Column(db.Integer, db.ForeignKey("drink_menus.id"), nullable=True, index=True)

    meal = db.Column(db.String(100), nullable=False)
    duration = db.Column(db.Integer, nullable=False)

    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        index=True
    )

    # Relationships
    food_type = db.relationship("FoodType")
    category = db.relationship("FoodCategory")
    menu = db.relationship("FoodMenu")
    dessert = db.relationship("DessertMenu")
    drink_type = db.relationship("DrinkType")
    drink_menu = db.relationship("DrinkMenu")

    __table_args__ = (
        db.Index("idx_user_created", "user_id", "created_at"),
    )
