import shutil
import socket
import subprocess
import tempfile
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class AudioHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/audio":
            self.send_error(404)
            return

        url = urllib.parse.parse_qs(parsed.query).get("url", [None])[0]
        if not url:
            self.send_error(400)
            return

        try:
            with tempfile.TemporaryDirectory() as directory:
                output = str(Path(directory) / "audio.%(ext)s")

                res = subprocess.run(
                    [
                        "yt-dlp",
                        "--quiet",
                        "--no-playlist",
                        "--extract-audio",
                        "--audio-format",
                        "m4a",
                        "-o",
                        output,
                        url,
                    ],
                    capture_output=True,
                    text=True,
                    timeout=300,
                    check=False,
                )

                if res.returncode != 0:
                    self.send_error(500)
                    return

                audio_file = next(
                    Path(directory).glob("*.m4a"),
                    None,
                )
                if audio_file is None:
                    self.send_error(500)
                    return

                self.send_response(200)
                self.send_header(
                    "Content-Type",
                    "audio/mp4",
                )
                self.send_header(
                    "Content-Disposition",
                    'attachment; filename="audio.m4a"',
                )
                self.send_header(
                    "Content-Length",
                    str(audio_file.stat().st_size),
                )
                self.end_headers()

                with audio_file.open("rb") as file:
                    shutil.copyfileobj(file, self.wfile, length=256 * 1024)

        except BrokenPipeError:
            pass

        except subprocess.TimeoutExpired:
            self.send_error(504)

        except Exception:
            self.send_error(500)


def get_local_ip():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]


if __name__ == "__main__":
    PORT = 8080

    print(f"listening: [http://{get_local_ip()}:{PORT}]\n")

    ThreadingHTTPServer(
        ("0.0.0.0", PORT),
        AudioHandler,
    ).serve_forever()
