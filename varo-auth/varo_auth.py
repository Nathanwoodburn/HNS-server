import requests
import json

def flask_login(request):
    dict = request.form.to_dict()
    keys = dict.keys()
    keys = list(keys)[0]
    keys = json.loads(keys)
    auth_request = keys['request']
    return login(auth_request)

def login(request):
    r = requests.get(f'https://auth.varo.domains/verify/{request}')
    r = r.json()
    if r['success'] == False:
        return False
    
    if 'data' in r:
        data = r['data']
        if 'name' in data:
            return data['name']
    return False