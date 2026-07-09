import os
import re
import json

def parse_desktop_file(filepath):
    try:
        with open(filepath, 'r', errors='ignore') as f:
            content = f.read()
            
        # Focus on [Desktop Entry] section
        entry_match = re.search(r'\[Desktop Entry\](.*?)(?=\n\[|$)', content, re.DOTALL)
        if not entry_match:
            return None
            
        entry = entry_match.group(1)
        
        # Filter out background tools / system services
        nodisplay = re.search(r'^NoDisplay\s*=\s*(true|1)', entry, re.IGNORECASE | re.MULTILINE)
        if nodisplay:
            return None
            
        name_match = re.search(r'^Name\s*=\s*(.*)', entry, re.MULTILINE)
        exec_match = re.search(r'^Exec\s*=\s*(.*)', entry, re.MULTILINE)
        icon_match = re.search(r'^Icon\s*=\s*(.*)', entry, re.MULTILINE)
        
        if not name_match or not exec_match:
            return None
            
        name = name_match.group(1).strip()
        exec_val = exec_match.group(1).strip()
        # Strip wayland/mime variables from exec
        exec_clean = re.sub(r'%[fFuUiDdnNkstv]', '', exec_val).strip()
        
        icon = icon_match.group(1).strip() if icon_match else "application-x-executable"
        
        return {
            'name': name,
            'exec': exec_clean,
            'icon': icon
        }
    except Exception:
        return None

def main():
    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/share/applications"
    ]
    apps = {}
    for d in dirs:
        if not os.path.exists(d):
            continue
        for f in os.listdir(d):
            if f.endswith('.desktop'):
                path = os.path.join(d, f)
                parsed = parse_desktop_file(path)
                if parsed:
                    apps[parsed['name']] = parsed
                    
    sorted_apps = sorted(apps.values(), key=lambda x: x['name'].lower())
    print(json.dumps(sorted_apps))

if __name__ == "__main__":
    main()
