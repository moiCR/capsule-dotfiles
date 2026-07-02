import os
import json

path = os.path.dirname(os.path.abspath(__file__))
langs = []
for f in os.listdir(path):
    if f.endswith('.json') and f != 'current.json':
        code = f.split('.')[0]
        try:
            with open(os.path.join(path, f), 'r') as file:
                data = json.load(file)
                name = data.get('lang_name', code.upper())
                langs.append({'id': code, 'name': name})
        except Exception:
            langs.append({'id': code, 'name': code.upper()})

langs.sort(key=lambda x: x['name'])
print(json.dumps(langs))
