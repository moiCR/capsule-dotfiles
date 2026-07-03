import json
import subprocess

try:
    res = subprocess.run(["dunstctl", "history"], capture_output=True, text=True)
    if res.returncode == 0:
        raw = json.loads(res.stdout)
        data = raw.get("data", [])
        notifications = []
        for group in data:
            for item in group:
                body = item.get("body", {}).get("data", "")
                summary = item.get("summary", {}).get("data", "")
                appname = item.get("appname", {}).get("data", "")
                nid = item.get("id", {}).get("data", 0)
                notifications.append({
                    "id": nid,
                    "app": appname,
                    "summary": summary,
                    "body": body
                })
        # Reverse to show newest first
        notifications.reverse()
        print(json.dumps(notifications))
    else:
        print("[]")
except Exception:
    print("[]")
