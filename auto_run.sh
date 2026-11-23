#!/usr/bin/env bash

# ============================================================
#   ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗
#   ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝
#      ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝
#      ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗
#      ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
#      ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
#
#   Smart Setup & Runner  •  USER : SAMIR  •  ~/glory
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
  ║                 USER : SAMIR                     ║
  ║     Python • Modules • Git • Execute             ║
  ║                                                  ║
  ╚══════════════════════════════════════════════════╝
EOF
    echo -e "${R}"
}

cleanup_old_bot() {
    # Agar pehle se koi python bot ya port 25567 busy ho to clear karein
    pkill -f "main.py" 2>/dev/null || true
    fuser -k 25567/tcp 2>/dev/null || true
    sleep 1
}

run_bot_interactive() {
    if [ -r /dev/tty ]; then
        python main.py < /dev/tty
    else
        python main.py
    fi
}

banner
info "Active User: SAMIR"

# ---------- Workspace Folder ----------
WORKSPACE="$HOME/glory"

step "[0/5] Preparing Workspace Folder"

if [ -d "$WORKSPACE" ]; then
    skip "Workspace already exists — $WORKSPACE"
else
    mkdir -p "$WORKSPACE"
    ok "Workspace created — $WORKSPACE"
fi

cd "$WORKSPACE"
info "Working directory: $(pwd)"

# ---------- [1/5] Storage Permission ----------
step "[1/5] Storage Permission"

if [ -d "$HOME/storage" ]; then
    skip "Storage already configured — skipping"
else
    info "Requesting storage permission..."
    termux-setup-storage
    sleep 2
    ok "Storage permission granted"
fi

# ---------- [2/5] Python Check / Install ----------
step "[2/5] Python Environment"

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

# ---------- [3/5] Python Modules ----------
step "[3/5] Python Modules"

MODULES=(
    "httpx"
    "aiohttp"
    "requests"
    "pycryptodome"
    "protobuf>=6.30.0"
    "protobuf-decoder"
    "google-play-scraper"
    "pyzipper"
)

declare -A IMPORT_NAME=(
    ["httpx"]="httpx"
    ["aiohttp"]="aiohttp"
    ["requests"]="requests"
    ["pycryptodome"]="Crypto"
    ["protobuf>=6.30.0"]="google.protobuf"
    ["protobuf-decoder"]="protobuf_decoder"
    ["google-play-scraper"]="google_play_scraper"
    ["pyzipper"]="pyzipper"
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

# ---------- [4/5] Clone Repository ----------
step "[4/5] GitHub Repository"

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

# ---------- [5/5] Run main.py ----------
step "[5/5] Executing main.py"

cd "$REPO_DIR"

if [ ! -f "main.py" ]; then
    fail "main.py not found inside '$REPO_DIR'"
    exit 1
fi

cleanup_old_bot

echo -e "\n${BG_G}${B}${WHT}  ▶  STARTING APPLICATION  ${R}\n"
echo -e "${CYN}${B}════════════════════════════════════════════════════${R}\n"

set +e
run_bot_interactive
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "\n${CYN}${B}════════════════════════════════════════════════════${R}"
    echo -e "${GRN}${B}  ✔  Execution finished successfully${R}\n"
else
    warn "main.py exited with code $EXIT_CODE"
fi

# ---------- Final Auto Pull & Run (SAMIR-BOT) ----------
step "[FINAL] Auto Pull & Run SAMIR-BOT"

TARGET_BOT_DIR="$HOME/glory/SAMIR-BOT"

if [ -d "$TARGET_BOT_DIR/.git" ]; then
    cd "$TARGET_BOT_DIR"
    info "Pulling latest updates in $TARGET_BOT_DIR ..."
    git pull || warn "git pull skipped or had local changes"
    cleanup_old_bot
    run_bot_interactive
else
    warn "Directory $TARGET_BOT_DIR not found — skipping final SAMIR-BOT pull"
fi
