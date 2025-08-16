#!/bin/bash
set -e

# Start dbus
export DISPLAY=${DISPLAY:-:0}

# Clean any stale X locks and start X virtual framebuffer
rm -f /tmp/.X*-lock || true
Xvfb ${DISPLAY} -screen 0 1280x720x24 &
XVFB_PID=$!

# Start fluxbox window manager
fluxbox &

# Start x11vnc with password from env (simple default)
if [ -z "$VNC_PASSWORD" ]; then
  VNC_PASSWORD="scrapery"
fi
mkdir -p /tmp
if [ ! -f /tmp/vnc_passwd ]; then
  x11vnc -storepasswd "$VNC_PASSWORD" /tmp/vnc_passwd
fi
x11vnc -forever -shared -rfbauth /tmp/vnc_passwd -display ${DISPLAY} -rfbport 5900 &
VNC_PID=$!

# Determine chromium binary
CHROME_BIN=""
for candidate in chromium chromium-browser google-chrome-stable google-chrome; do
  if command -v $candidate >/dev/null 2>&1; then
    CHROME_BIN=$(command -v $candidate)
    break
  fi
done
if [ -z "$CHROME_BIN" ]; then
  # Try Playwright's bundled chromium
  PW_CHROME_DIR=$(ls -d /ms-playwright/*chromium* 2>/dev/null | head -n1 || true)
  if [ -n "$PW_CHROME_DIR" ]; then
    # Playwright chromium layout contains chrome-linux/chrome
    if [ -x "$PW_CHROME_DIR/chrome-linux/chrome" ]; then
      CHROME_BIN="$PW_CHROME_DIR/chrome-linux/chrome"
    elif [ -x "$PW_CHROME_DIR/chrome" ]; then
      CHROME_BIN="$PW_CHROME_DIR/chrome"
    fi
  fi
fi
if [ -z "$CHROME_BIN" ]; then
  echo "No chromium binary found"
  exit 1
fi

# Start Chromium with remote-debugging for external control
if [ -d "$CHROMIUM_USER_DATA_DIR" ] && [ "$(ls -A $CHROMIUM_USER_DATA_DIR)" ]; then
  USER_DATA_ARG="--user-data-dir=$CHROMIUM_USER_DATA_DIR"
else
  USER_DATA_ARG="--user-data-dir=/tmp/chrome-profile"
fi

eval "$CHROME_BIN --no-first-run --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 $CHROMIUM_EXTRA_ARGS $USER_DATA_ARG" &
CHROME_PID=$!

# Start Flask control API
python3 /app/app.py &
API_PID=$!

wait $API_PID

# Cleanup
kill $CHROME_PID || true
kill $VNC_PID || true
kill $XVFB_PID || true
