import os
import json

path = os.path.expanduser('~/pro/dotfiles/theme/types')
themes = []

if os.path.exists(path):
    for f in os.listdir(path):
        if f.endswith('.json'):
            file_path = os.path.join(path, f)
            try:
                with open(file_path, 'r') as file:
                    data = json.load(file)
                
                # ID must match the filename without extension for apply-theme.sh to work
                theme_id = os.path.splitext(f)[0]
                
                # Name is read from JSON if present, otherwise generated from ID
                theme_name = data.get('name')
                if not theme_name:
                    raw_name = theme_id.replace('_', ' ')
                    words = raw_name.split()
                    formatted_words = []
                    for w in words:
                        if w.lower() == 'oled':
                            formatted_words.append('OLED')
                        else:
                            formatted_words.append(w.title())
                    theme_name = ' '.join(formatted_words)
                
                themes.append({
                    'id': theme_id,
                    'name': theme_name,
                    'bg': data.get('bg', '#000000'),
                    'accent': data.get('accent', '#ffffff'),
                    'mode': data.get('mode', 'dark'),
                    'fg': data.get('fg', '#ffffff'),
                    'fgMuted': data.get('fgMuted', '#aaaaaa')
                })
            except Exception as e:
                import sys
                print(f"Error reading {f}: {e}", file=sys.stderr)

# Sort themes alphabetically by ID
themes.sort(key=lambda x: x['id'])
print(json.dumps(themes))
