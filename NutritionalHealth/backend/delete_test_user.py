from api import app
from models import db, User
from sqlalchemy import func

USERNAMES_TO_REMOVE = ['night_test_123']

with app.app_context():
    for uname in USERNAMES_TO_REMOVE:
        user = User.query.filter(func.lower(User.username) == uname.lower()).first()
        if user:
            print('Deleting user:', user.username, user.email)
            try:
                db.session.delete(user)
                db.session.commit()
                print('Deleted.')
            except Exception as e:
                db.session.rollback()
                print('Failed to delete', user.username, e)
        else:
            print('User not found:', uname)
