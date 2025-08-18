#!/bin/bash
set -e

mkdir -p /data/profile

# Start dbus
export DISPLAY=${DISPLAY:-:0}

# Clean any stale X locks and start X virtual framebuffer
rm -f /tmp/.X*-lock || true
Xvfb ${DISPLAY} -screen 0 1280x720x24 &
XVFB_PID=$!

# Start fluxbox window manager
fluxbox &

# Start x11vnc, with or without a password
if [ "${VNC_NO_PASSWORD,,}" == "true" ]; then
  echo "Starting VNC without password."
  x11vnc -forever -shared -display ${DISPLAY} -rfbport 5900 &
else
  echo "Starting VNC with password."
  if [ -z "$VNC_PASSWORD" ]; then
    VNC_PASSWORD="scrapery"
  fi
  PASSWD_PATH=/tmp/vnc_passwd
  if [ ! -f "$PASSWD_PATH" ]; then
    x11vnc -storepasswd "$VNC_PASSWORD" "$PASSWD_PATH"
  fi
  x11vnc -forever -shared -rfbauth $PASSWD_PATH -display ${DISPLAY} -rfbport 5900 &
fi
VNC_PID=$!

# Start websockify / noVNC so the desktop is accessible from a browser
if [ ! -d /opt/novnc ]; then
  mkdir -p /opt/novnc
  echo "Downloading noVNC..."
  git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc || true
  git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify || true
fi
/opt/novnc/utils/websockify/run 6080 --web /opt/novnc localhost:5900 || true &
WS_PID=$!

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

"$CHROME_BIN" \
  --no-first-run \
  --remote-debugging-port=9223 \
  --remote-allow-origins=* \
  $CHROMIUM_EXTRA_ARGS \
  $USER_DATA_ARG &
CHROME_PID=$!

# Use socat to proxy Chrome's debugging port from localhost:9223 to 0.0.0.0:9222
# This works around Chrome ignoring --remote-debugging-address=0.0.0.0
socat TCP-LISTEN:9222,bind=0.0.0.0,fork TCP:localhost:9223 &
SOCAT_PID=$!

# Start Flask control API
python3 /app/app.py &
API_PID=$!

wait $API_PID

# Cleanup
kill $CHROME_PID || true
kill $SOCAT_PID || true
kill $VNC_PID || true
kill $XVFB_PID || true
