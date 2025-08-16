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
- **Technical note**: Chrome runs on internal port 9223, with `socat` proxying connections from `0.0.0.0:9222` to `localhost:9223`. This works around Chrome ignoring the `--remote-debugging-address=0.0.0.0` flag in containerized environments.

Future features:

- A small host-side Playwright example that uses a specific site's login flow.
- Add user mapping to avoid root-owned profile directories when mounting the host profile.
