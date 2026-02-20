#!/usr/bin/env python3
"""Simple Python test script for the API (register -> login -> update profile -> export).

Run from backend folder:
  python test_api.py

Requires `requests` (pip install requests)
"""
import requests
import os
import sys

BASE = os.environ.get('API_BASE', 'http://127.0.0.1:5000')

USERNAME = 'pytester'
PASSWORD = 'P@ssw0rd1!'
EMAIL = 'pytester@example.com'


def register():
    r = requests.post(f'{BASE}/register', json={'username': USERNAME, 'password': PASSWORD, 'email': EMAIL})
    print('register', r.status_code, r.text)
    return r


def login():
    r = requests.post(f'{BASE}/login', json={'username': USERNAME, 'password': PASSWORD})
    print('login', r.status_code, r.text)
    if r.status_code == 200:
        return r.json()
    return None


def update_profile(user_id, token):
    headers = {'Authorization': f'Bearer {token}'}
    r = requests.post(f'{BASE}/user/{user_id}', json={'gender':'ชาย','age':30,'weight':70,'height':175}, headers=headers)
    print('update_profile', r.status_code, r.text)
    return r


def export_csv(user_id, token):
    headers = {'Authorization': f'Bearer {token}'}
    r = requests.get(f'{BASE}/export/history/{user_id}', headers=headers)
    print('export_csv', r.status_code)
    return r


if __name__ == '__main__':
    print('Running API smoke test against', BASE)
    register()
    info = login()
    if not info:
        print('login failed, abort')
        sys.exit(1)
    token = info.get('authToken') or info.get('password_token')
    uid = info.get('id') or info.get('user_id')
    update_profile(uid, token)
    r = export_csv(uid, token)
    if r.status_code == 200:
        print('export returned', len(r.content), 'bytes')
    print('Done')
