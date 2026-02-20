import json, urllib.request, urllib.error

def post(payload):
    url = 'http://127.0.0.1:5000/forgot-password'
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type':'application/json'})
    try:
        resp = urllib.request.urlopen(req, timeout=10)
        print('STATUS', resp.getcode())
        print(resp.read().decode())
    except urllib.error.HTTPError as e:
        print('STATUS', e.code)
        try:
            print(e.read().decode())
        except Exception:
            print('ERROR reading body')
    except Exception as e:
        print('ERROR', e)

if __name__ == '__main__':
    print('Test 1: wrong email')
    post({'username':'night_test_123','email':'night_test_123@gmail.co'})
    print('\nTest 2: correct email')
    post({'username':'night_test_123','email':'night_test_123@example.com'})
