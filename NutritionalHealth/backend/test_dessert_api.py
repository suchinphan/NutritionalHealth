from api import app

with app.test_client() as client:
    resp = client.get('/api/dessert-menus')
    print(resp.status)
    print(resp.get_data(as_text=True))
