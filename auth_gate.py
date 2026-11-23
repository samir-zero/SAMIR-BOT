import json
import os
import sys
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
KEYS_FILE = "keys.json"


def load_keys_from_gitlab():
    if not PRIVATE_TOKEN:
        raise RuntimeError("GITLAB_PRIVATE_TOKEN set nahi hai")

    proj = urllib.parse.quote(PROJECT_PATH, safe="")
    file_path = urllib.parse.quote(KEYS_FILE, safe="")
    branch_q = urllib.parse.quote(BRANCH, safe="")
    # cache-buster query taake hamesha fresh file aaye
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

    # Agar data ke andar "keys" ya "passwords" ya "users" list/dict ho
    if isinstance(data, dict):
        for container_key in ("keys", "passwords", "users", "data"):
            if container_key in data and isinstance(data[container_key], (dict, list)):
                found = find_password_entry(data[container_key], target)
                if found is not None:
                    return found

        # Direct dict match: {"PASS1": {...}}
        if target in data:
            return data[target]

        # Case-insensitive fallback match
        for k, v in data.items():
            if str(k).strip().lower() == target.lower():
                return v

    # Agar list ho: [{"key": "PASS1", ...}] ya [{"password": "PASS1", ...}]
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


def check_expired(entry) -> bool:
    if not isinstance(entry, dict):
        return False

    status = str(entry.get("status", "")).strip().lower()
    if status in ("expired", "disabled", "revoked", "inactive", "false", "0"):
        return True

    exp_val = (
        entry.get("expires_at")
        or entry.get("expiry")
        or entry.get("expire_at")
        or entry.get("expires")
    )
    if not exp_val:
        return False

    formats = (
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%d %H:%M",
        "%Y-%m-%d",
        "%d-%m-%Y %H:%M:%S",
        "%d-%m-%Y",
    )
    for fmt in formats:
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

    entry = find_password_entry(data, password)
    if entry is None:
        print("Galat password.")
        sys.exit(1)

    if check_expired(entry):
        print("expired")
        sys.exit(1)

    print("Password valid hai. Server start ho raha hai...")


if __name__ == "__main__":
    verify_access()
