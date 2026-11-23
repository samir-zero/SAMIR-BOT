import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime

GITLAB_API_BASE = "https://gitlab.com/api/v4"
PRIVATE_TOKEN = os.getenv("GITLAB_PRIVATE_TOKEN", "").strip()
PROJECT_PATH = "samir-zero/admin-panel1"
BRANCH = "main"
KEYS_FILE = "keys.json"


def load_keys_from_gitlab() -> dict:
    if not PRIVATE_TOKEN:
        raise RuntimeError("glpat-JctmRxI6ao6V-Rb6KWRx-GM6MQpvOjEKdTpxZ213bw8.01.170vwvteo")

    proj = urllib.parse.quote(PROJECT_PATH, safe="")
    file_path = urllib.parse.quote(KEYS_FILE, safe="")
    branch_q = urllib.parse.quote(BRANCH, safe="")
    url = f"{GITLAB_API_BASE}/projects/{proj}/repository/files/{file_path}/raw?ref={branch_q}"

    req = urllib.request.Request(
        url,
        headers={
            "PRIVATE-TOKEN": PRIVATE_TOKEN,
            "User-Agent": "BlackFoxServerGate/1.0",
        },
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def check_expired(entry: dict) -> bool:
    status = str(entry.get("status", "")).strip().lower()
    if status in ("expired", "disabled", "revoked"):
        return True

    exp_val = entry.get("expires_at") or entry.get("expiry")
    if not exp_val:
        return False

    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
        try:
            return datetime.now() >= datetime.strptime(str(exp_val).strip(), fmt)
        except ValueError:
            continue

    return False


def verify_access():
    password = input("Enter password: ").strip()
    if not password:
        print("Password khali nahi ho sakta.")
        sys.exit(1)

    try:
        data = load_keys_from_gitlab()
    except Exception as e:
        print(f"Admin panel/GitLab connection error: {e}")
        sys.exit(1)

    keys_map = data.get("keys") if isinstance(data.get("keys"), dict) else data
    if not isinstance(keys_map, dict) or password not in keys_map:
        print("Galat password.")
        sys.exit(1)

    entry = keys_map[password]
    if isinstance(entry, dict) and check_expired(entry):
        print("expired")
        sys.exit(1)

    print("Password valid hai. Server start ho raha hai...")
