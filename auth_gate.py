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
KEYS_FILE = "config.json"


def load_keys_from_gitlab():
    if not PRIVATE_TOKEN:
        raise RuntimeError("Token missing")

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
    if exp_val is None or str(exp_val).strip() == "":
        return False

    exp_str = str(exp_val).strip()
    try:
        ts = float(exp_str)
        if ts > 0:
            return datetime.now().timestamp() >= ts
    except ValueError:
        pass

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
            return datetime.now() >= datetime.strptime(exp_str, fmt)
        except ValueError:
            continue

    return False


def verify_access():
    if not sys.stdin.isatty():
        print("Interactive terminal nahi mila (stdin non-interactive hai).")
        sys.exit(1)

    try:
        password = input("Enter password: ").strip()
    except EOFError:
        print("\nInput stream band hai.")
        sys.exit(1)

    if not password:
        print("Password zaroori hai.")
        sys.exit(1)

    try:
        data = load_keys_from_gitlab()
    except Exception:
        print("Server verification abhi connect nahi ho saka.")
        sys.exit(1)

    entry = find_password_entry(data, password)
    if entry is None:
        print("Galat password.")
        sys.exit(1)

    if isinstance(entry, dict) and check_expired(entry):
        print("expired")
        sys.exit(1)

    print("Password sahi hai. Start ho raha hai...")


if __name__ == "__main__":
    verify_access()
