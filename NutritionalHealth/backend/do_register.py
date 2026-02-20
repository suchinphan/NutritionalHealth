import json, urllib.request, urllib.error

def post(payload):
    url = 'http://127.0.0.1:5000/register'
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
    payload = {
        'username':'night1',
        'email':'night1@gmail.com',
        'password':'Aa1!abcd',
        'confirm_password':'Aa1!abcd'
    }
    post(payload)
