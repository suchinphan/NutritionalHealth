import json,urllib.request,urllib.error

def post(payload):
    url='http://127.0.0.1:5000/forgot-password'
    data=json.dumps(payload).encode()
    req=urllib.request.Request(url,data=data,headers={'Content-Type':'application/json'})
    try:
        resp=urllib.request.urlopen(req,timeout=5)
        print('STATUS',resp.getcode())
        print(resp.read().decode())
    except urllib.error.HTTPError as e:
        print('STATUS',e.code)
        try:
            print(e.read().decode())
        except Exception:
            print('BODY READ ERROR')
    except Exception as e:
        print('ERROR',e)

if __name__=='__main__':
    post({'username':'night_test_123','email':'night_test_123@gmail.co'})
    post({'username':'night_test_123','email':'night_test_123@example.com'})
