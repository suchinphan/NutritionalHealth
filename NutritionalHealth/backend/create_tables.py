from api import app
from models import db

def main():
    # Creates all tables defined in models.py
    with app.app_context():
        print("Creating tables...")
        db.create_all()
        print("Done. Tables created (if not existing).")

if __name__ == '__main__':
    main()
