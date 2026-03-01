from api import app
from models import FoodMenu, DessertMenu, DrinkMenu

with app.app_context():
    print('food_count:', FoodMenu.query.count())
    print('dessert_count:', DessertMenu.query.count())
    print('drink_count:', DrinkMenu.query.count())
