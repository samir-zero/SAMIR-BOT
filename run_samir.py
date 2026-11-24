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
    if "║" in s and any(k in s.upper() for k in ("ARIYAN", "A9X", "SAMIR")):
        return "║                    SAMIR                     ║\n"
    s = re.sub(r"Ariyan\s*H4cks", "SAMIR", s, flags=re.IGNORECASE)
    s = re.sub(r"@?AriyanPrime_A9x", "@SamirPrime", s, flags=re.IGNORECASE)
    s = re.sub(r"ARIYAN[\s_-]*A9X[\s_-]*BD", "SAMIR", s, flags=re.IGNORECASE)
    s = re.sub(r"ARIYAN[\s_-]*BD", "SAMIR", s, flags=re.IGNORECASE)
    s = re.sub(r"\bARIYAN\b", "SAMIR", s, flags=re.IGNORECASE)
    return s


proc = subprocess.Popen(
    [sys.executable, "-u", "main.py"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    bufsize=0,
)

art_buf = []
banner_shown = 0
line_buf = b""


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


def emit_chunk(text: str, is_complete_line: bool) -> None:
    global art_buf
    if is_complete_line:
        if is_block_art(text):
            art_buf.append(text)
        else:
            flush_art()
            sys.stdout.write(clean_text(text))
            sys.stdout.flush()
    else:
        # Agar line abhi complete nahi hui (jaise \r ya progress bar), to flush_art karke turant likhein
        flush_art()
        sys.stdout.write(clean_text(text))
        sys.stdout.flush()


try:
    while True:
        chunk = proc.stdout.read(64)
        if not chunk:
            break
        line_buf += chunk
        while b"\n" in line_buf or b"\r" in line_buf:
            n_idx = line_buf.find(b"\n")
            r_idx = line_buf.find(b"\r")
            if r_idx != -1 and (n_idx == -1 or r_idx < n_idx):
                part = line_buf[: r_idx + 1].decode("utf-8", errors="replace")
                line_buf = line_buf[r_idx + 1 :]
                emit_chunk(part, is_complete_line=False)
            else:
                part = line_buf[: n_idx + 1].decode("utf-8", errors="replace")
                line_buf = line_buf[n_idx + 1 :]
                emit_chunk(part, is_complete_line=True)

    if line_buf:
        emit_chunk(line_buf.decode("utf-8", errors="replace"), is_complete_line=True)
    flush_art()
except KeyboardInterrupt:
    proc.terminate()
finally:
    proc.wait()
EOF
