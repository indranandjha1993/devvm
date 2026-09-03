#!/usr/bin/env python3
"""ShortGen render service — local ffmpeg renderer for the shorts pipeline.

POST /render a json2video-style movie (or a flat scene list) and it stitches a
vertical short: per scene a Ken Burns image + Oswald caption, the audio drives
the scene length, scenes are concatenated, the mp4 comes back in the response.
GET /health for liveness. Stdlib only; ffmpeg does the work.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("RENDERER_PORT", "8088"))
FONT_NAME = os.environ.get("RENDERER_FONT", "Oswald")
PRESET = os.environ.get("RENDERER_PRESET", "veryfast")
CRF = os.environ.get("RENDERER_CRF", "20")
# Optional speedup: rewrite a public asset host to a VM-local one to skip the
# external round-trip (e.g. S3_REWRITE_FROM=https://<s3-hostname>
# S3_REWRITE_TO=http://127.0.0.1:9000). Off by default.
S3_REWRITE_FROM = os.environ.get("S3_REWRITE_FROM", "")
S3_REWRITE_TO = os.environ.get("S3_REWRITE_TO", "")

# Bound concurrent renders so we stay a polite neighbour on the dev VM.
SEM = threading.BoundedSemaphore(int(os.environ.get("RENDER_CONCURRENCY", "1")))


def log(msg):
    print(f"[shortgen-renderer] {msg}", flush=True)


def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError("ffmpeg failed: " + (p.stderr or "").strip()[-1500:])
    return p


def rewrite(url):
    if S3_REWRITE_FROM and S3_REWRITE_TO and url.startswith(S3_REWRITE_FROM):
        return S3_REWRITE_TO + url[len(S3_REWRITE_FROM):]
    return url


def download(url, dest, tries=3):
    url = rewrite(url)
    last = "unknown error"
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "shortgen-renderer"})
            with urllib.request.urlopen(req, timeout=60) as r, open(dest, "wb") as f:
                shutil.copyfileobj(r, f)
            if os.path.getsize(dest) > 0:
                return
            last = "empty file"
        except Exception as e:
            last = str(e)
    raise RuntimeError(f"download failed for {url}: {last}")


def ass_escape(text):
    # Curly braces are ASS override delimiters; neutralise them, then map newlines.
    return text.replace("\\", "\\\\").replace("{", "(").replace("}", ")")


def wrap(text, width=18, max_lines=3):
    lines, cur = [], ""
    for word in text.split():
        candidate = (cur + " " + word).strip()
        if len(candidate) <= width or not cur:
            cur = candidate
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return "\\N".join(lines[:max_lines])


_ALIGN = {
    "bottom-center": 2, "bottom-left": 1, "bottom-right": 3,
    "center": 5, "center-center": 5, "mid-center": 5,
    "top-center": 8, "top-left": 7, "top-right": 9,
}


def hex_to_ass(color, default="&H00FFFFFF"):
    """#RRGGBB -> ASS &HAABBGGRR (opaque)."""
    if not color:
        return default
    c = str(color).strip().lstrip("#")
    if len(c) == 6:
        rr, gg, bb = c[0:2], c[2:4], c[4:6]
        return f"&H00{bb}{gg}{rr}".upper()
    return default


def font_px(style, w, h):
    """Resolve a json2video-style font-size (e.g. '9vw', '64px', 'Nvh') to pixels."""
    fs = (style or {}).get("font-size")
    if isinstance(fs, str):
        s = fs.strip().lower()
        try:
            if s.endswith("vw"):
                return max(24, int(float(s[:-2]) / 100.0 * w))
            if s.endswith("vh"):
                return max(24, int(float(s[:-2]) / 100.0 * h))
            if s.endswith("px"):
                return int(float(s[:-2]))
            return int(float(s))
        except ValueError:
            pass
    elif isinstance(fs, (int, float)):
        return int(fs)
    return int(h * 0.052)  # ~100px tall at 1920


def build_ass(text, w, h, style=None):
    """Per-scene ASS caption with an animated entrance, honouring json2video text settings."""
    style = style or {}
    fontsize = font_px(style, w, h)
    align = _ALIGN.get(str(style.get("position", "bottom-center")).lower(), 2)
    margin_v = int(h * 0.16) if align in (1, 2, 3) else int(h * 0.08)
    color = hex_to_ass(style.get("font-color"))
    font = style.get("font-family") or FONT_NAME
    body = wrap(ass_escape(text.upper()))
    # \fad: 150ms fade-in.  \fscx/\fscy + \t: scale from 70% -> 100% over 250ms.
    entrance = r"{\fad(150,0)\fscx70\fscy70\t(0,250,\fscx100\fscy100)}"
    return f"""[Script Info]
ScriptType: v4.00+
PlayResX: {w}
PlayResY: {h}
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Caption,{font},{fontsize},{color},{color},&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,4,3,{align},60,60,{margin_v},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,9:59:59.99,Caption,,0,0,0,,{entrance}{body}
"""


def render_scene(idx, scene, workdir, w, h, fps):
    img = os.path.join(workdir, f"img{idx}")
    aud = os.path.join(workdir, f"aud{idx}.mp3")
    download(scene["image_url"], img)
    download(scene["audio_url"], aud)

    # scale to cover -> crop -> Ken Burns zoom. d is kept large (>= a 30s scene)
    # so the zoom never resets within a clip; -shortest trims to the audio length.
    vf = (
        f"scale={w}:{h}:force_original_aspect_ratio=increase,"
        f"crop={w}:{h},"
        f"zoompan=z='min(zoom+0.0006,1.15)':d=900:s={w}x{h}:fps={fps}"
    )
    text = (scene.get("on_screen_text") or "").strip()
    if text:
        ass_path = os.path.join(workdir, f"cap{idx}.ass")
        with open(ass_path, "w", encoding="utf-8") as f:
            f.write(build_ass(text, w, h, scene.get("style")))
        vf += f",ass={ass_path}"
    vf += ",format=yuv420p"

    out = os.path.join(workdir, f"scene{idx:03d}.mp4")
    run([
        "ffmpeg", "-y",
        "-loop", "1", "-i", img,
        "-i", aud,
        "-vf", vf,
        "-r", str(fps),
        "-c:v", "libx264", "-preset", PRESET, "-crf", CRF, "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2",
        "-shortest", "-movflags", "+faststart",
        out,
    ])
    return out


def concat(scene_files, workdir, out):
    list_path = os.path.join(workdir, "concat.txt")
    with open(list_path, "w", encoding="utf-8") as f:
        for p in scene_files:
            f.write(f"file '{p}'\n")
    run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", list_path,
        "-c", "copy", "-movflags", "+faststart", out,
    ])


def render_movie(payload):
    w = int(payload.get("width", 1080))
    h = int(payload.get("height", 1920))
    fps = int(payload.get("fps", 30))
    scenes = payload.get("scenes") or []
    workdir = tempfile.mkdtemp(prefix="shortgen-")
    try:
        files = [render_scene(i, s, workdir, w, h, fps) for i, s in enumerate(scenes)]
        final = os.path.join(workdir, "final.mp4")
        if len(files) == 1:
            shutil.copy(files[0], final)
        else:
            concat(files, workdir, final)
        with open(final, "rb") as f:
            return f.read()
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def normalize(raw):
    """Map a json2video movie payload (or a flat scene list) to one internal shape.

    Accepts {scenes:[{image_url,audio_url,on_screen_text}]} or a json2video
    {movie:{scenes:[{elements:[...]}]}}, with or without a one-item list wrapper.
    """
    if isinstance(raw, list):
        raw = raw[0] if raw else {}
    draft = raw.get("draft_id")
    movie = raw.get("movie") if isinstance(raw.get("movie"), dict) else raw
    width = int(movie.get("width", raw.get("width", 1080)))
    height = int(movie.get("height", raw.get("height", 1920)))
    fps = int(raw.get("fps", movie.get("fps", 30)))
    scenes = []
    for sc in movie.get("scenes", []):
        if isinstance(sc, dict) and "elements" in sc:  # json2video scene
            img = aud = None
            text, style = "", {}
            for el in sc.get("elements", []):
                kind = el.get("type")
                if kind == "image" and not img:
                    img = el.get("src")
                elif kind == "audio" and not aud:
                    aud = el.get("src")
                elif kind == "text":
                    text = el.get("text", "")
                    style = dict(el.get("settings", {}) or {})
                    style.setdefault("position", el.get("position", "bottom-center"))
            scenes.append({"image_url": img, "audio_url": aud,
                           "on_screen_text": text, "style": style})
        elif isinstance(sc, dict):  # native scene
            scenes.append({"image_url": sc.get("image_url"),
                           "audio_url": sc.get("audio_url"),
                           "on_screen_text": sc.get("on_screen_text", ""),
                           "style": sc.get("style", {})})
    return {"draft_id": draft, "width": width, "height": height,
            "fps": fps, "scenes": scenes}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):  # silence default per-request stderr noise
        pass

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/health"):
            return self._json(200, {"status": "ok"})
        return self._json(404, {"error": "not found"})

    def do_POST(self):
        if not self.path.startswith("/render"):
            return self._json(404, {"error": "not found"})
        length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = normalize(json.loads(self.rfile.read(length) or b"{}"))
        except Exception as e:
            return self._json(400, {"error": f"bad json body: {e}"})
        scenes = payload.get("scenes") or []
        if not scenes:
            return self._json(400, {"error": "no scenes in request"})
        bad = [i + 1 for i, s in enumerate(scenes)
               if not s.get("image_url") or not s.get("audio_url")]
        if bad:
            return self._json(400, {"error": f"scenes missing image/audio src: {bad}"})

        draft = payload.get("draft_id", "draft")
        if not SEM.acquire(timeout=600):
            return self._json(503, {"error": "renderer busy"})
        try:
            data = render_movie(payload)
            self.send_response(200)
            self.send_header("Content-Type", "video/mp4")
            self.send_header("Content-Disposition", f'attachment; filename="{draft}.mp4"')
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            log(f"rendered draft={draft} scenes={len(scenes)} bytes={len(data)}")
        except Exception as e:
            log(f"ERROR draft={draft}: {e}")
            self._json(500, {"error": str(e)})
        finally:
            SEM.release()


def main():
    if not shutil.which("ffmpeg"):
        print("ffmpeg not found on PATH", file=sys.stderr)
        sys.exit(1)
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    log(f"listening on :{PORT} (font={FONT_NAME}, preset={PRESET}, crf={CRF})")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
