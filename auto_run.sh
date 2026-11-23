#!/usr/bin/env bash
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
║               USER : SAMIR                       ║
║     Python • Modules • Git • Execute             ║
║                                                  ║
╚══════════════════════════════════════════════════╝
EOF
  echo -e "${R}"
}

banner
info "Active User: SAMIR"

WORKSPACE="$HOME/glory"
REPO_DIR="$WORKSPACE/SAMIR-BOT"

if [ ! -d "$REPO_DIR" ]; then
  mkdir -p "$WORKSPACE"
  git clone "https://github.com/samir-zero/SAMIR-BOT.git" "$REPO_DIR" >/dev/null 2>&1 || true
fi

# Sirf aakhri mein yeh command run hogi
step "[FINAL] Running SAMIR-BOT"
cd "$HOME/glory/SAMIR-BOT"
git pull
if [ -r /dev/tty ]; then
  python main.py < /dev/tty
else
  python main.py
fi
