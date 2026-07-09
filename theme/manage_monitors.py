import sys
import json
import os

MONITORS_PATH = os.path.expanduser("~/pro/dotfiles/hypr/modules/monitors.lua")

def save_monitors(monitors):
    lines = []
    for m in monitors:
        output = m.get("output", "")
        mode = m.get("mode", "auto")
        position = m.get("position", "auto")
        scale = m.get("scale", "auto")
        
        # Scale might be float or int, convert to string
        if isinstance(scale, (float, int)):
            scale_str = str(scale)
        else:
            scale_str = str(scale)
            
        # Format the Lua output
        scale_val = f'"{scale_str}"' if scale_str != "auto" else "auto"
        lines.append(f'hl.monitor({{\n    output   = "{output}",\n    mode     = "{mode}",\n    position = "{position}",\n    scale    = {scale_val},\n}})\n\n')
        
    with open(MONITORS_PATH, "w") as f:
        f.writelines(lines)

def main():
    if len(sys.argv) < 3 or sys.argv[1] != "--save":
        print("Usage: manage_monitors.py --save '<json_str>'")
        sys.exit(1)
        
    try:
        monitors = json.loads(sys.argv[2])
        save_monitors(monitors)
        print("Monitors saved successfully")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
