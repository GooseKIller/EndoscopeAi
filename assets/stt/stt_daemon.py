#!/usr/bin/env python
"""
Local mic → Whisper STT daemon for Endoscopy AI (Windows).

Outputs JSON lines to stdout:
  {"text": "..."}   # UTF‑8

Env vars:
  WHISPER_MODEL   tiny|base|small|... (default: small)
  LANG            ru|en|... (default: ru)
  CHUNK_SEC       float seconds per chunk (default: 2.0)
  SAMPLE_RATE     int (default: 16000)
  DEVICE_INDEX    int sounddevice input device index (default: None -> default device)

Quit protocol (optional): if stdin closes or receives line starting with 'quit', we exit.
"""

import os
import sys
import json
import queue
import threading
import tempfile
import numpy as np
import os, torch

import sounddevice as sd
import soundfile as sf
import whisper
import os, tempfile, soundfile as sf, numpy as np

os.environ.setdefault("OMP_NUM_THREADS", "2")
os.environ.setdefault("MKL_NUM_THREADS", "2")
torch.set_num_threads(2)

os.environ["PYTHONIOENCODING"] = "utf-8"
os.environ["TOKENIZERS_PARALLELISM"] = "false" 

MODEL_TYPE = os.environ.get("WHISPER_MODEL", "small")
LANG = os.environ.get("LANG", "ru")
CHUNK_SEC = float(os.environ.get("CHUNK_SEC", "2"))
SAMPLE_RATE = int(os.environ.get("SAMPLE_RATE", "16000"))
DEVICE_INDEX = os.environ.get("DEVICE_INDEX")
DEVICE_INDEX = int(DEVICE_INDEX) if DEVICE_INDEX not in (None, "", "None") else None

print(f"__STT_LOADING_MODEL__:{MODEL_TYPE}", flush=True)
model = whisper.load_model(MODEL_TYPE)
print("__STT_MODEL_READY__", flush=True)

# queue for audio callback
_audio_q: "queue.Queue[np.ndarray]" = queue.Queue()


def _audio_cb(indata, frames, time_, status):  # pragma: no cover
    if status:
        print(f"__STT_SD_STATUS__:{status}", file=sys.stderr, flush=True)
    # copy to avoid referencing internal buffer
    _audio_q.put(indata.copy())


def _stdin_watcher(stop_event: threading.Event):
    """Watch stdin; if closed or line 'quit' -> set stop_event."""
    try:
        for line in sys.stdin:
            if line.strip().lower().startswith("quit"):
                stop_event.set()
                break
    except Exception:  # pragma: no cover
        pass
    finally:
        stop_event.set()


def _transcribe_chunk(audio: np.ndarray) -> str:
    # ensure mono float32, shape (frames,)
    if audio.ndim > 1:
        audio = audio[:, 0]
    audio = audio.astype(np.float32)

    # создаём пустой временный файл и сразу закрываем дескриптор
    fd, path = tempfile.mkstemp(suffix=".wav")
    os.close(fd)
    try:
        sf.write(path, audio, SAMPLE_RATE)        # записываем WAV
        result = model.transcribe(
            path,
            language=LANG,
            fp16=False,
            verbose=False,
        )
        return result.get("text", "").strip()
    except Exception as e:                        # pragma: no cover
        return f"__ERROR__ {e}"
    finally:
        try:
            os.remove(path)                       # чистим за собой
        except OSError:
            pass


def main():
    stop_event = threading.Event()

    # watch stdin in a thread (non‑blocking main audio loop)
    t = threading.Thread(target=_stdin_watcher, args=(stop_event,), daemon=True)
    t.start()

    chunk_frames = int(SAMPLE_RATE * CHUNK_SEC)
    buf = np.empty((0, 1), dtype=np.float32)

    with sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        dtype="float32",
        callback=_audio_cb,
        device=DEVICE_INDEX,
    ):
        while not stop_event.is_set():
            try:
                new_frames = _audio_q.get(timeout=0.1)
            except queue.Empty:
                continue
            buf = np.concatenate([buf, new_frames], axis=0)
            while len(buf) >= chunk_frames:
                chunk = buf[:chunk_frames]
                buf = buf[chunk_frames:]
                text = _transcribe_chunk(chunk)
                if text:
                    print(json.dumps({"text": text}, ensure_ascii=False), flush=True)

    print("__STT_EXIT__", flush=True)


if __name__ == "__main__":
    main()
