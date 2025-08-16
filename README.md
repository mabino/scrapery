Scrapery — lightweight, VNC-accessible Chromium for automation

Overview
--------
Scrapery is a small Docker-based environment that provides:

- A minimal desktop (Xvfb + fluxbox) accessible via VNC or via a browser (noVNC).
- Chromium (from Playwright's bundled browsers) running on that desktop with remote-debugging enabled.
- A tiny Flask HTTP API that can attach to Chromium via CDP and perform actions (screenshot example included).
- Support for mounting a host Chromium profile directory or using a Playwright storageState JSON to reuse login sessions.

This repository provides a compose file and an example host-side Playwright script so you can run automation from your host while the browser runs inside the container.

Quick start (macOS, ARM)
------------------------

1. Build and run with Docker Compose (from project root):

```bash
docker compose up --build -d
```

2. Check the control API:

```bash
curl http://127.0.0.1:3000/status
```

3. Take a test screenshot using the API:

```bash
curl -X POST http://127.0.0.1:3000/screenshot \
	-H 'Content-Type: application/json' \
	-d '{"url":"https://example.com"}' | jq
```

4. View the desktop from a browser (noVNC):

Open http://localhost:6080/vnc.html and connect (VNC password default: `scrapery` — change via env `VNC_PASSWORD`).

Or connect via a VNC client to localhost:5900.

Host Playwright example
------------------------

There is a sample host script `host_playwright_example.py` that demonstrates how a host-side Playwright process can connect to the Chromium instance inside the container via CDP and drive it.

Usage:

```bash
# Ensure Playwright (Python) is installed on the host
pip install playwright
playwright install

# Run the example (container must be running)
python3 host_playwright_example.py
```

The example shows how to connect using `connect_over_cdp()` and take a screenshot. Replace the pseudo login steps with selectors for your target site.

Using host profile or session file
---------------------------------

- To reuse a host Chrome/Chromium profile, mount the profile directory at `./data/profile` before starting the container.
- Alternatively, provide a Playwright storage state JSON at `./data/session.json` and create contexts with `storageState=` in Playwright.

CI / Tests
----------

A basic GitHub Actions workflow is included at `.github/workflows/ci.yml`. It builds the Docker image, starts the container, waits for the control API and performs the screenshot test. This verifies the image builds and the automation pipe works.

Notes, caveats and next steps
---------------------------

- Mounting a live host browser profile may result in permission or version mismatches. If you see problems, copy the profile into `./data/profile` or use the `session.json` approach.
- The container exposes Chromium remote debugging on port 9222 without auth; for production or remote exposure, use SSH tunneling or a secured proxy.
- noVNC is bundled at runtime and served on port 6080 so you can access the desktop from a browser — this eliminates the need for a separate VNC client.

If you want, I can (pick one):

- Add a small host-side Playwright example that uses a specific site's login flow (if you provide selectors).
- Harden security for remote debugging and noVNC.
- Add user mapping to avoid root-owned profile directories when mounting the host profile.
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
