import sys
import re
from api import app
from models import db, User
from werkzeug.security import generate_password_hash, check_password_hash

def set_password(username: str, new_password: str):
    with app.app_context():
        # ค้นหาผู้ใช้จากฐานข้อมูล
        user = User.query.filter(func.lower(User.username) == username.lower()).first()
        
        if not user:
            print(f'User not found: {username}')  # แจ้งไม่พบผู้ใช้
            return 2  # คืนค่า 2 เพื่อแสดงว่าผู้ใช้ไม่พบ

        # ตรวจสอบเงื่อนไขรหัสผ่าน
        if len(new_password) < 8:
            print("รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร")
            return 1
        
        if not re.search(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])', new_password):
            print("รหัสผ่านต้องมีตัวพิมพ์ใหญ่ พิมพ์เล็ก ตัวเลข และอักขระพิเศษ")
            return 2
        
        # ตรวจสอบว่ารหัสผ่านใหม่ไม่เหมือนกับรหัสผ่านเก่า
        if check_password_hash(user.password_hash, new_password):
            print("รหัสผ่านใหม่ไม่สามารถเหมือนรหัสผ่านเดิมได้")
            return 3  # ถ้ารหัสผ่านใหม่เหมือนเดิมให้แสดงผลว่าไม่สามารถใช้รหัสผ่านเดิมได้
        
        # ทำการแฮชรหัสผ่านใหม่
        user.password_hash = generate_password_hash(new_password)
        
        # ลบรหัสผ่านชั่วคราวถ้ามี
        user.temp_password_hash = None
        user.temp_password_expires_at = None
        
        try:
            db.session.commit()
            print(f'Password updated for {username}')  # แจ้งว่าเปลี่ยนรหัสผ่านสำเร็จ
            return 0  # คืนค่า 0 แสดงว่าทำสำเร็จ
        except Exception as e:
            db.session.rollback()
            print('Database error:', e)  # แจ้งหากมีข้อผิดพลาดจากฐานข้อมูล
            return 4  # คืนค่า 4 เมื่อเกิดข้อผิดพลาดจากฐานข้อมูล

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: python set_user_password.py <username> <new_password>')
        sys.exit(1)
    username = sys.argv[1]
    new_password = sys.argv[2]
    sys.exit(set_password(username, new_password))