import os
import sys
import re
import json

INPUT_PATH = os.path.expanduser("~/pro/dotfiles/hypr/modules/input.lua")

def read_input_config():
    if not os.path.exists(INPUT_PATH):
        return {}
    with open(INPUT_PATH, "r") as f:
        content = f.read()
        
    config = {}
    
    # regex matches
    kb_layout_match = re.search(r'kb_layout\s*=\s*"([^"]*)"', content)
    accel_profile_match = re.search(r'accel_profile\s*=\s*"([^"]*)"', content)
    follow_mouse_match = re.search(r'follow_mouse\s*=\s*([0-9.-]+)', content)
    sensitivity_match = re.search(r'sensitivity\s*=\s*([0-9.-]+)', content)
    natural_scroll_match = re.search(r'natural_scroll\s*=\s*(true|false)', content)
    
    config["kb_layout"] = kb_layout_match.group(1) if kb_layout_match else "us"
    config["accel_profile"] = accel_profile_match.group(1) if accel_profile_match else "flat"
    config["follow_mouse"] = int(follow_mouse_match.group(1)) if follow_mouse_match else 1
    config["sensitivity"] = float(sensitivity_match.group(1)) if sensitivity_match else 0.0
    config["natural_scroll"] = natural_scroll_match.group(1) == "true" if natural_scroll_match else False
    
    return config

def write_input_config(config):
    if not os.path.exists(INPUT_PATH):
        return
    with open(INPUT_PATH, "r") as f:
        content = f.read()
        
    # Replace options using safe group references \g<1> to prevent digit collision
    content = re.sub(r'(kb_layout\s*=\s*)"[^"]*"', r'\g<1>"{}"'.format(config.get("kb_layout", "us")), content)
    content = re.sub(r'(accel_profile\s*=\s*)"[^"]*"', r'\g<1>"{}"'.format(config.get("accel_profile", "flat")), content)
    content = re.sub(r'(follow_mouse\s*=\s*)[0-9.-]+', r'\g<1>{}'.format(config.get("follow_mouse", 1)), content)
    content = re.sub(r'(sensitivity\s*=\s*)[0-9.-]+', r'\g<1>{}'.format(config.get("sensitivity", 0.0)), content)
    content = re.sub(r'(natural_scroll\s*=\s*)(true|false)', r'\g<1>{}'.format("true" if config.get("natural_scroll", False) else "false"), content)
    
    with open(INPUT_PATH, "w") as f:
        f.write(content)

def main():
    if len(sys.argv) < 2:
        print("Usage: manage_input.py [--get|--save <json_str>]")
        sys.exit(1)
        
    action = sys.argv[1]
    if action == "--get":
        config = read_input_config()
        print(json.dumps(config))
    elif action == "--save":
        if len(sys.argv) < 3:
            print("Missing config JSON string")
            sys.exit(1)
        try:
            config = json.loads(sys.argv[2])
            write_input_config(config)
            print("Input config saved successfully")
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)

if __name__ == "__main__":
    main()
