#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Запускает whisper‑command.exe, читает вывод (Heard '...' или Heard "...")
и шлёт UDP‑пакеты 'start' / 'stop' / 'dot' на 127.0.0.1:8765
"""

import subprocess, socket, pathlib, re, os, time, sys

# ──────────────────────────── настройки ────────────────────────────
ROOT   = pathlib.Path(__file__).resolve().parents[2]          # корень repo
EXE    = ROOT / 'third_party/whisper.cpp/build/bin/whisper-command.exe'
MODEL  = ROOT / 'third_party/whisper.cpp/models/ggml-small.bin'
CMDS   = ROOT / 'assets/stt/ru_command.txt'                       # start/stop/dot

CAPTURE = '0'                         # mic ID (смотрите --list-devices)
THREADS = str(os.cpu_count() // 2 or 2)
LANG    = 'en'                        # 'ru', если команды русские

UDP_ADDR = ('127.0.0.1', 8765)

# ────────────────────────── CLI аргументы ─────────────────────────
ARGS = [
    str(EXE), '-m', str(MODEL),
    '-l', LANG,
    '-t', THREADS,
    '-c', CAPTURE,
    '-p', "''",                     # пустой prompt  ('' работает в bash и cmd)
    '--commands', str(CMDS),
    # '--output-json',            # раскомментируйте, если ваш exe поддерживает
]

# шаблоны: JSON, Heard '...', Heard "..."
json_re   = re.compile(r'^\s*\{.*"text"\s*:\s*"([^"]+)".*\}$')
heard1_re = re.compile(r"^.*Heard '(.+?)'")
heard2_re = re.compile(r'^.*Heard "(.+?)"')

# ───────────────────────────── запуск ─────────────────────────────
print('[bridge] start:', ' '.join(ARGS), flush=True)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

proc = subprocess.Popen(
    ARGS,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

print('[bridge] whisper pid', proc.pid, flush=True)

while True:
    line = proc.stdout.readline()
    if not line:
        if proc.poll() is not None:
            print('[bridge] whisper exited', proc.returncode, flush=True)
            sys.exit(proc.returncode)
        time.sleep(0.02)
        continue

    # ----- расскомментируйте для полного лога -----
    print('[raw]', line.strip(), flush=True)
    # ----------------------------------------------

    line = line.strip()
    m = json_re.match(line) or heard1_re.match(line) or heard2_re.match(line)
    if not m:
        continue

    text = m.group(1).lower()

    if 'start' in text:
        cmd = 'start'
    elif 'stop' in text:
        cmd = 'stop'
    elif 'dot' in text:
        cmd = 'dot'
    else:
        cmd = ''

    if cmd:
        sock.sendto(cmd.encode(), UDP_ADDR)
        print('[bridge] →', cmd, flush=True)
