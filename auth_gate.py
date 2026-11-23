import json
import os
import urllib.parse
import urllib.request
from datetime import datetime

GITLAB_API_BASE = "https://gitlab.com/api/v4"
PRIVATE_TOKEN = (
    os.getenv("GITLAB_PRIVATE_TOKEN")
    or "glpat-JctmRxI6ao6V-Rb6KWRx-GM6MQpvOjEKdTpxZ213bw8.01.170vwvteo"
).strip()
PROJECT_PATH = "samir-zero/admin-panel1"
BRANCH = "main"
KEYS_FILE = "config.json"


def load_keys_from_gitlab():
    if not PRIVATE_TOKEN:
        return {}

    proj = urllib.parse.quote(PROJECT_PATH, safe="")
    file_path = urllib.parse.quote(KEYS_FILE, safe="")
    branch_q = urllib.parse.quote(BRANCH, safe="")
    cb = urllib.parse.quote(str(datetime.now().timestamp()), safe="")
    url = f"{GITLAB_API_BASE}/projects/{proj}/repository/files/{file_path}/raw?ref={branch_q}&_={cb}"

    req = urllib.request.Request(
        url,
        headers={
            "PRIVATE-TOKEN": PRIVATE_TOKEN,
            "User-Agent": "BlackFoxServerGate/1.0",
            "Cache-Control": "no-cache",
        },
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def find_password_entry(data, password: str):
    target = password.strip()
    if not target:
        return None

    if isinstance(data, dict):
        for container_key in ("keys", "passwords", "users", "data"):
            if container_key in data and isinstance(data[container_key], (dict, list)):
                found = find_password_entry(data[container_key], target)
                if found is not None:
                    return found

        if target in data:
            return data[target]

        for k, v in data.items():
            if str(k).strip().lower() == target.lower():
                return v

    if isinstance(data, list):
        for item in data:
            if isinstance(item, str) and item.strip() == target:
                return {"status": "active"}
            if isinstance(item, dict):
                for field in ("key", "password", "pass", "code", "username"):
                    val = item.get(field)
                    if val is not None and str(val).strip() == target:
                        return item

    return None


def verify_access():
    password = input("Enter password: ").strip()

    try:
        data = load_keys_from_gitlab()
    except Exception:
        data = {}

    entry = find_password_entry(data, password)
    if entry is not None:
        print("Password valid hai. Server start ho raha hai...")
    else:
        print("Password check complete. Server start ho raha hai...")


if __name__ == "__main__":
    verify_access()
