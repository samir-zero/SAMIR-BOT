#!/usr/bin/env bash

# ============================================================
#   ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗
#   ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝
#      ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝
#      ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗
#      ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
#      ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
#
#   Smart Setup & Runner  •  Everything in ~/glory
# ============================================================

set -euo pipefail

# ---------- Colors ----------
R="\033[0m"; B="\033[1m"; D="\033[2m"
RED="\033[0;31m"; GRN="\033[0;32m"; YEL="\033[0;33m"
BLU="\033[0;34m"; MAG="\033[0;35m"; CYN="\033[0;36m"; WHT="\033[0;37m"
BG_G="\033[42m"

# ---------- Helpers ----------
ok()    { echo -e "  ${GRN}${B}✔${R} ${GRN}$1${R}"; }
skip()  { echo -e "  ${MAG}${B}↷${R} ${MAG}$1${R}"; }
warn()  { echo -e "  ${YEL}${B}⚠${R} ${YEL}$1${R}"; }
fail()  { echo -e "  ${RED}${B}✘${R} ${RED}$1${R}"; }
info()  { echo -e "  ${CYN}${B}ℹ${R} ${WHT}$1${R}"; }
step()  {
    echo -e "\n${BLU}${B}▶ $1${R}"
    echo -e "${D}────────────────────────────────────────────────────${R}"
}

# ---------- Banner ----------
banner() {
    clear
    echo -e "${CYN}${B}"
    cat <<'EOF'
  ╔══════════════════════════════════════════════════╗
  ║                                                  ║
  ║        🚀  TERMUX AUTO SETUP & RUNNER  🚀        ║
  ║                  USER:SAMIR                      ║
  ║     Python • Modules • Git • Execute             ║
  ║                                                  ║
  ╚══════════════════════════════════════════════════╝
EOF
    echo -e "${R}"
}

banner

# ---------- Sabse Pehle Python Install (Pass Se Bhi Pehle) ----------
step "[0/5] Python Install & Pass Verification"

if command -v python >/dev/null 2>&1; then
    skip "Python already installed — $(python --version 2>&1)"
else
    info "Sabse pehle Python install ho raha hai..."
    pkg update -y >/dev/null 2>&1
    pkg install -y python -y >/dev/null 2>&1
    ok "Python installed — $(python --version 2>&1)"
fi

if [ ! -e /dev/tty ]; then
    fail "TTY terminal nahi mila. Script ko interactive terminal mein chalayein."
    exit 1
fi

read -rp "  Enter Admin Panel Pass: " USER_PASS < /dev/tty
USER_PASS="$(echo "$USER_PASS" | xargs)"

if [ -z "$USER_PASS" ]; then
    fail "Invalid pass"
    exit 1
fi

AUTH_STATUS="$(python - "$USER_PASS" <<'PYEOF'
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
        raise RuntimeError("GITLAB_PRIVATE_TOKEN set nahi hai")

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


password = sys.argv[1].strip()
try:
    data = load_keys_from_gitlab()
except Exception as e:
    print(f"ERROR:{e}")
    sys.exit(0)

entry = find_password_entry(data, password)
if entry is None:
    print("INVALID")
elif check_expired(entry):
    print("EXPIRED")
else:
    print("VALID")
PYEOF
)"

case "$AUTH_STATUS" in
    "VALID")
        ok "Pass verified — sabse pehle pyzipper aur baaki commands run ho rahe hain..."
        ;;
    "EXPIRED")
        fail "Expired"
        exit 1
        ;;
    "INVALID")
        fail "Invalid pass"
        exit 1
        ;;
    ERROR:*)
        fail "Admin panel connection error: ${AUTH_STATUS#ERROR:}"
        exit 1
        ;;
    *)
        fail "Invalid pass"
        exit 1
        ;;
esac

# ---------- Pass Ke Baad Sabse Pehle pyzipper ----------
python -m pip install pyzipper

# ---------- Workspace Folder ----------
WORKSPACE="$HOME/glory"

step "[1/5] Preparing Workspace Folder"

if [ -d "$WORKSPACE" ]; then
    skip "Workspace already exists — $WORKSPACE"
else
    mkdir -p "$WORKSPACE"
    ok "Workspace created — $WORKSPACE"
fi

cd "$WORKSPACE"
info "Working directory: $(pwd)"

# ---------- [2/5] Storage Permission ----------
step "[2/5] Storage Permission"

if [ -d "$HOME/storage" ]; then
    skip "Storage already configured — skipping"
else
    info "Requesting storage permission..."
    termux-setup-storage
    sleep 2
    ok "Storage permission granted"
fi

# ---------- [3/5] Python & Git Check / Install ----------
step "[3/5] Python & Git Environment"

if command -v python >/dev/null 2>&1; then
    skip "Python already installed — $(python --version 2>&1)"
else
    info "Installing Python & Git..."
    pkg update -y >/dev/null 2>&1
    pkg install -y python git >/dev/null 2>&1
    ok "Python installed — $(python --version 2>&1)"
fi

if ! command -v git >/dev/null 2>&1; then
    info "Installing Git..."
    pkg install -y git >/dev/null 2>&1
    ok "Git installed"
else
    skip "Git already installed"
fi

python -m pip install --upgrade pip >/dev/null 2>&1 || true
ok "pip is up to date"

# ---------- [4/5] Python Modules & Clone Repository ----------
step "[4/5] Python Modules & GitHub Repository"

MODULES=(
    "httpx"
    "aiohttp"
    "requests"
    "pycryptodome"
    "protobuf>=6.30.0"
    "protobuf-decoder"
    "google-play-scraper"
)

declare -A IMPORT_NAME=(
    ["httpx"]="httpx"
    ["aiohttp"]="aiohttp"
    ["requests"]="requests"
    ["pycryptodome"]="Crypto"
    ["protobuf>=6.30.0"]="google.protobuf"
    ["protobuf-decoder"]="protobuf_decoder"
    ["google-play-scraper"]="google_play_scraper"
)

for pkg in "${MODULES[@]}"; do
    imp="${IMPORT_NAME[$pkg]}"
    if python -c "import $imp" >/dev/null 2>&1; then
        skip "$pkg already installed"
    else
        info "Installing $pkg ..."
        if python -m pip install "$pkg" >/dev/null 2>&1; then
            ok "$pkg installed"
        else
            warn "$pkg failed to install (continuing)"
        fi
    fi
done

REPO_URL="https://github.com/mdariyan47484-ship-it/Glory.git"
REPO_DIR="$WORKSPACE/$(basename "$REPO_URL" .git)"

if [ -d "$REPO_DIR" ]; then
    info "Existing copy found — removing old one..."
    rm -rf "$REPO_DIR"
    skip "Old repository wiped"
fi

info "Cloning fresh copy into $WORKSPACE ..."
if git clone "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1; then
    ok "Repository cloned — $REPO_DIR"
else
    fail "Failed to clone repository"
    exit 1
fi

# ---------- [5/5] Create SAMIR Runner & Execute ----------
step "[5/5] Applying SAMIR & Executing"

if [ ! -f "$HOME/glory/Glory/main.py" ]; then
    fail "main.py not found inside '$HOME/glory/Glory'"
    exit 1
fi

cat <<'EOF' > "$HOME/glory/Glory/run_samir.py"
import re
import subprocess
import sys

SAMIR_BANNER = """
  ███████╗ █████╗ ███╗   ███╗██╗██████╗
  ██╔════╝██╔══██╗████╗ ████║██║██╔══██╗
  ███████╗███████║██╔████╔██║██║██████╔╝
  ╚════██║██╔══██║██║╚██╔╝██║██║██╔══██╗
  ███████║██║  ██║██║ ╚═╝ ██║██║██║  ██║
  ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝
""".strip("\n")


def is_art_line(s: str) -> bool:
    stripped = s.strip()
    if not stripped:
        return False
    art_chars = sum(1 for ch in stripped if ch in "█╗═╝╚╔║▀▄▌▐")
    return art_chars >= 6 and (art_chars / max(len(stripped), 1)) > 0.35


def clean_line(line: str) -> str:
    if "║" in line and ("ARIYAN" in line.upper() or "A9X" in line.upper() or "SAMIR" in line.upper()):
        return "║                    SAMIR                     ║\n"

    line = re.sub(r"ARIYAN[\s_-]*A9X[\s_-]*BD", "SAMIR", line, flags=re.IGNORECASE)
    line = re.sub(r"\bARIYAN\b", "SAMIR", line, flags=re.IGNORECASE)
    return line


proc = subprocess.Popen(
    [sys.executable, "main.py"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
    errors="replace",
)

art_buf = []
art_block_count = 0


def flush_art() -> None:
    global art_buf, art_block_count
    if not art_buf:
        return
    if len(art_buf) >= 4:
        art_block_count += 1
        if art_block_count == 1:
            sys.stdout.write(SAMIR_BANNER + "\n")
            sys.stdout.flush()
    else:
        for item in art_buf:
            sys.stdout.write(clean_line(item))
            sys.stdout.flush()
    art_buf = []


try:
    for raw_line in proc.stdout:
        cleaned_esc = re.sub(r"\^\[\[[0-9;]*~", "", raw_line)
        if not cleaned_esc.strip():
            if cleaned_esc:
                sys.stdout.write(cleaned_esc)
                sys.stdout.flush()
            continue

        if is_art_line(cleaned_esc):
            art_buf.append(cleaned_esc)
        else:
            flush_art()
            sys.stdout.write(clean_line(cleaned_esc))
            sys.stdout.flush()

    flush_art()
except KeyboardInterrupt:
    proc.terminate()
finally:
    proc.wait()
EOF

ok "SAMIR wrapper ready"

pkill -f "main.py" >/dev/null 2>&1 || true
pkill -f "app.py" >/dev/null 2>&1 || true
sleep 1

echo -e "\n${BG_G}${B}${WHT}  ▶  STARTING APPLICATION  ${R}\n"
echo -e "${CYN}${B}════════════════════════════════════════════════════${R}\n"

cd ~/glory/Glory && python run_samir.py

echo -e "\n${CYN}${B}════════════════════════════════════════════════════${R}"
echo -e "${GRN}${B}  ✔  Execution finished successfully${R}\n"
