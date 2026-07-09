import os
import sys
import re

KEYBINDS_PATH = os.path.expanduser("~/pro/dotfiles/hypr/modules/keybinds.lua")

def normalize_keys(keys_str):
    # Normalize a keys string for comparison (e.g. "SUPER + RETURN" -> "SUPER+RETURN")
    return keys_str.replace(" ", "").upper()

def format_action(cmd):
    cmd_stripped = cmd.strip()
    if cmd_stripped.startswith("hl."):
        # Native Lua dispatcher call
        return cmd_stripped
    elif cmd_stripped.startswith("programs."):
        # Reference to a program variable
        return f"hl.dsp.exec_cmd({cmd_stripped})"
    else:
        # Standard command string
        return f'hl.dsp.exec_cmd("{cmd_stripped}")'

def get_line_keys(line):
    # Parse keys from a lua line: hl.bind("keys", action) or hl.bind(mainMod .. " + keys", action)
    match = re.search(r'hl\.bind\(([^,]+),', line)
    if not match:
        return None
    keys_raw = match.group(1).strip()
    keys = (keys_raw
            .replace('mainMod', 'SUPER')
            .replace('"', '')
            .replace("'", '')
            .replace('..', '+')
            .replace(' ', '')
            .upper())
    if keys.startswith("SUPER++"):
        keys = keys.replace("SUPER++", "SUPER+")
    return keys

def read_keybinds():
    if not os.path.exists(KEYBINDS_PATH):
        return []
    with open(KEYBINDS_PATH, 'r') as f:
        return f.readlines()

def write_keybinds(lines):
    with open(KEYBINDS_PATH, 'w') as f:
        f.writelines(lines)

def main():
    if len(sys.argv) < 2:
        print("Usage: manage_keybinds.py [--add|--delete|--edit] ...")
        sys.exit(1)

    action = sys.argv[1]

    if action == "--add":
        # Syntax: manage_keybinds.py --add "<keys>" "<cmd>"
        if len(sys.argv) < 4:
            print("Missing keys or command")
            sys.exit(1)
        keys = sys.argv[2]
        cmd = sys.argv[3]
        
        lines = read_keybinds()
        # Format key string to match mainMod convention if it starts with SUPER
        lua_keys = keys
        if keys.upper().startswith("SUPER"):
            rest = keys[5:].strip().lstrip("+").strip()
            lua_keys = f'mainMod .. " + {rest}"'
        else:
            lua_keys = f'"{keys}"'
            
        action_val = format_action(cmd)
        new_line = f'\nhl.bind({lua_keys}, {action_val})\n'
        lines.append(new_line)
        write_keybinds(lines)
        print("Bind added successfully")

    elif action == "--delete":
        # Syntax: manage_keybinds.py --delete "<keys>"
        if len(sys.argv) < 3:
            print("Missing keys to delete")
            sys.exit(1)
        target_keys = normalize_keys(sys.argv[2])
        
        lines = read_keybinds()
        new_lines = []
        deleted = False
        for line in lines:
            line_keys = get_line_keys(line)
            if line_keys and line_keys == target_keys:
                deleted = True
                continue # Skip this line to delete it
            new_lines.append(line)
            
        if deleted:
            write_keybinds(new_lines)
            print("Bind deleted successfully")
        else:
            print(f"Bind not found for keys: {sys.argv[2]}")
            sys.exit(1)

    elif action == "--edit":
        # Syntax: manage_keybinds.py --edit "<old_keys>" "<new_keys>" "<new_cmd>"
        if len(sys.argv) < 5:
            print("Missing edit parameters")
            sys.exit(1)
        old_keys = normalize_keys(sys.argv[2])
        new_keys = sys.argv[3]
        new_cmd = sys.argv[4]
        
        lines = read_keybinds()
        new_lines = []
        edited = False
        
        lua_keys = new_keys
        if new_keys.upper().startswith("SUPER"):
            rest = new_keys[5:].strip().lstrip("+").strip()
            lua_keys = f'mainMod .. " + {rest}"'
        else:
            lua_keys = f'"{new_keys}"'
            
        action_val = format_action(new_cmd)
        new_bind_line = f'hl.bind({lua_keys}, {action_val})\n'
        
        for line in lines:
            line_keys = get_line_keys(line)
            if line_keys and line_keys == old_keys:
                new_lines.append(new_bind_line)
                edited = True
            else:
                new_lines.append(line)
                
        if edited:
            write_keybinds(new_lines)
            print("Bind edited successfully")
        else:
            print(f"Bind not found to edit: {sys.argv[2]}")
            sys.exit(1)

if __name__ == "__main__":
    main()
