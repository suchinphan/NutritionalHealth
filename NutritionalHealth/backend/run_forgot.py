from api import app
from models import User
import json

with app.app_context():
    u = User.query.filter(User.email != None).first()
    if not u:
        print('No user with email found; aborting')
    else:
        print('Using user:', u.id, u.username, u.email)
        client = app.test_client()
        resp = client.post('/forgot-password', json={'username': u.username, 'email': u.email})
        print('Status:', resp.status_code)
        try:
            print('JSON:', resp.get_json())
        except Exception:
            print('Raw:', resp.data)
