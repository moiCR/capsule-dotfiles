import os
import json
import sys

# Get path from argument or default to ~/Pictures/Wallpapers
path = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else '~/Pictures/Wallpapers')
images = []

if os.path.exists(path):
    for f in os.listdir(path):
        if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
            images.append({
                'name': os.path.splitext(f)[0].replace('_', ' ').title(),
                'path': os.path.join(path, f)
            })

images.sort(key=lambda x: x['name'])
print(json.dumps(images))
