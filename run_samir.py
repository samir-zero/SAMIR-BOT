cd ~/glory/Glory
cat <<'EOF' > run_samir.py
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

ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]|\^\[\[[0-9;]*~")


def strip_ansi(s: str) -> str:
    return ANSI_RE.sub("", s)


def is_block_art(s: str) -> bool:
    plain = strip_ansi(s).strip()
    if not plain:
        return False
    block_chars = sum(1 for ch in plain if ch in "█╗═╝╚╔║▀▄▌▐")
    return block_chars >= 6 and (block_chars / len(plain)) > 0.30


def clean_text(s: str) -> str:
    s = re.sub(r"Ariyan\s*H4cks", "SAMIR", s, flags=re.IGNORECASE)
    s = re.sub(r"@?AriyanPrime_A9x", "@SamirPrime", s, flags=re.IGNORECASE)
    s = re.sub(r"ARIYAN[\s_-]*A9X[\s_-]*BD", "SAMIR", s, flags=re.IGNORECASE)
    s = re.sub(r"ARIYAN[\s_-]*BD", "SAMIR", s, flags=re.IGNORECASE)
    s = re.sub(r"\bARIYAN\b", "SAMIR", s, flags=re.IGNORECASE)
    return s


proc = subprocess.Popen(
    [sys.executable, "main.py"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
    errors="replace",
)

art_buf = []
banner_shown = 0


def flush_art() -> None:
    global art_buf, banner_shown
    if not art_buf:
        return
    if len(art_buf) >= 4:
        banner_shown += 1
        if banner_shown == 1:
            sys.stdout.write("\n" + SAMIR_BANNER + "\n\n")
            sys.stdout.flush()
    else:
        for item in art_buf:
            sys.stdout.write(clean_text(item))
            sys.stdout.flush()
    art_buf = []


try:
    for line in proc.stdout:
        if is_block_art(line):
            art_buf.append(line)
        else:
            flush_art()
            sys.stdout.write(clean_text(line))
            sys.stdout.flush()
    flush_art()
except KeyboardInterrupt:
    proc.terminate()
finally:
    proc.wait()
EOF
