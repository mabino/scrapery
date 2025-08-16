Requirements coverage checklist

- Works on ARM Macs: Done — image built and tested on an ARM Mac using the Playwright multi-arch base and local build (validated here).
- VNC to a minimal graphical desktop: Done — x11vnc + Xvfb + fluxbox are running and VNC listens on localhost:5900.
- Use Chromium on that desktop: Done — Chromium from Playwright bundle is started and displays on the virtual X display.
- Control Chromium via Playwright or external automation: Done — Chromium started with remote debugging on port 9222 and the included Flask API attaches over CDP.
- Use host browser session data via volume mount: Supported — mount your host profile at `./data/profile` (see notes below); Chromium will use `/data/profile` if present.
- Alternatively use a session file: Supported — place a Playwright storage state JSON at `./data/session.json` and use it with Playwright contexts or pass it to the API.

Try it (commands):

```bash
# Build and start (detached)
docker compose up --build -d

# Check service status
curl http://127.0.0.1:3000/status

# Request a screenshot via the control API
curl -X POST http://127.0.0.1:3000/screenshot -H 'Content-Type: application/json' -d '{"url":"https://example.com"}' | jq

# VNC connect to localhost:5900 with password 'scrapery' (change via env var VNC_PASSWORD)
```

Notes on host profile mounts

- Mounting a full Chrome profile from the host may cause version or permission issues; copy the profile into `./data/profile` or ensure Docker has permission to read it. The container uses `/data/profile` as user-data-dir when non-empty.

Next steps / improvements

- Add secure VNC auth or expose via SSH tunneling for remote access.
- Add optional user mapping to avoid root-owned profile files.
- Add a small JS/Python client example showing how to connect to the remote debugging port with Playwright from the host using `connect_over_cdp`.
# Scrapery

Lightweight container for automating Chromium in a minimal desktop accessible by VNC. Designed to work on ARM Macs via multi-arch Playwright image and expose Chromium remote debugging for external control.

3. The container runs Chromium with remote debugging on port 9222; you can connect Playwright or Puppeteer from the host to `http://localhost:9222` or use the included Flask API at `http://localhost:3000`.
# Scrapery

Lightweight container for automating Chromium in a minimal desktop accessible by VNC. Designed to work on ARM Macs via multi-arch Playwright image and expose Chromium remote debugging for external control.

Files created:

- `Dockerfile` - builds the image from Playwright base, installs Xvfb, fluxbox, and x11vnc, and runs Chromium with remote-debugging enabled.
- `docker-compose.yml` - runs the container with ports and volumes suitable for mounting host browser profile or a Playwright storage state file.
- `start.sh` - entrypoint that starts Xvfb, fluxbox, x11vnc, Chromium, and the Flask control API.
- `app.py` - small Flask API exposing a `/screenshot` endpoint that connects to Chromium via CDP (remote debugging) and takes screenshots. Also provides `/status`.
- `requirements.txt` - Python dependencies.

Quick start (macOS, ARM):

1. Build and run with docker-compose:

```bash
# from project root
docker compose up --build -d
```

2. Connect a VNC client to localhost:5900 using password `scrapery` (can be changed with env var `VNC_PASSWORD`).

3. The container runs Chromium with remote debugging on port 9222; you can connect Playwright or Puppeteer from the host to `http://localhost:9222` or use the included Flask API at `http://localhost:3000`.

Using host profile or session file

- To use an existing host Chromium/Chrome profile, copy or mount the profile directory to `./data/profile` before starting. The container will use `/data/profile` as the user data dir.

- Alternatively, provide a Playwright storage state JSON at `./data/session.json`. The Flask API supports passing storageState to `/screenshot`. You can also have your automation script pass the storage state when creating a browser context.

Requirements coverage

- Works on ARM Macs: Implemented by using the multi-arch `mcr.microsoft.com/playwright:latest` base image and setting `platform: linux/arm64` in `docker-compose.yml`. Status: Done (needs local Docker Desktop supporting ARM).
- Can VNC to a minimal graphical desktop: `x11vnc`, `Xvfb`, and `fluxbox` are installed and exposed on port 5900. Status: Done.
- Can use Chromium on that desktop: Chromium is launched in the container and will run inside Xvfb. Status: Done.
- Can control Chromium via Playwright or other mechanism: Chromium is started with `--remote-debugging-port=9222` so host tools can connect. A small Flask API demonstrates CDP usage. Status: Done.
- Can use a host's browser session data via a volume mount: Mount a host profile at `./data/profile` to use the browser profile. Status: Done (best-effort; may have version compatibility issues).
- Can alternatively use a session file instead of host profile: Provide a Playwright `storageState` file at `./data/session.json` and pass it to Playwright contexts. Status: Done (example file: `data/session.example.json`).

Notes and limitations

- Mounting a host browser profile from a different Chrome/Chromium version may cause profile corruption or errors; prefer using Playwright storageState when possible.
- VNC in this repo uses a simple password stored in memory; for production secure properly.
- If Playwright cannot find browsers or there's an architecture mismatch, try alternative Playwright tags like `mcr.microsoft.com/playwright:focal`.

Next steps

- Add a small health-check script that hits `/status` and verifies the CDP endpoint is reachable.
- Add an example Playwright script (host-side) showing how to connect to remote debugging and reuse `storageState`.

Enjoy.
