#!/usr/bin/env python3
"""Local plain-HTTP mirror for Hex.pm.

Claude Code on the web routes egress through a secure web proxy that filters by
TLS-client fingerprint. curl / Python / Node are allowed, but Erlang/OTP's TLS
stack is not — so `mix local.hex` and `mix deps.get` get a 503 from the proxy
and fail. This tiny relay accepts plain HTTP on localhost and re-fetches each
request through Python's (allowed) TLS stack.

Point Hex at it with HEX_MIRROR / HEX_BUILDS_URL. Hex still verifies registry
signatures and tarball checksums end-to-end, so relaying over localhost HTTP is
safe — the bytes are authenticated by Hex regardless of transport.

Usage: hex-mirror.py [port]   (default 8899)
"""
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = {
    "/repo": "https://repo.hex.pm",
    "/builds": "https://builds.hex.pm",
}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        prefix = next(
            (p for p in UPSTREAM if self.path == p or self.path.startswith(p + "/")),
            None,
        )
        if prefix is None:
            self.send_error(404, "no upstream mapping")
            return

        url = UPSTREAM[prefix] + (self.path[len(prefix):] or "/")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "hex-mirror/1.0"})
            with urllib.request.urlopen(req, timeout=60) as upstream:
                body = upstream.read()
                self.send_response(upstream.status)
                for header in ("Content-Type", "Content-Encoding"):
                    value = upstream.headers.get(header)
                    if value:
                        self.send_header(header, value)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
        except urllib.error.HTTPError as err:
            body = err.read()
            self.send_response(err.code)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception as err:  # noqa: BLE001 - relay any failure as 502
            body = str(err).encode()
            self.send_response(502)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, *_args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8899
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
