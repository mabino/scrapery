FROM --platform=$BUILDPLATFORM mcr.microsoft.com/playwright:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install lightweight window manager, VNC server and utilities
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       fluxbox x11vnc xvfb dbus-x11 procps net-tools ca-certificates fonts-liberation socat \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash scrapery \
    && mkdir -p /data/profile /app
WORKDIR /app

# Copy app and requirements
COPY requirements.txt /app/requirements.txt

# Ensure python3 and pip are available for our Flask + Playwright Python usage
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && apt-get install -y --no-install-recommends git python3-websockify ca-certificates wget \
    && python3 -m pip install --upgrade pip setuptools \
    && python3 -m pip install --no-cache-dir -r /app/requirements.txt \
    && python3 -m playwright install --with-deps || true

COPY app.py /app/app.py
COPY start.sh /app/start.sh
COPY host_playwright_example.py /app/host_playwright_example.py
RUN chmod +x /app/start.sh

EXPOSE 5900 9222 3000
EXPOSE 6080

# Defaults: allow mounting a host profile to /data/profile or providing a Playwright storageState at /data/session.json
ENV DISPLAY=:99
ENV VNC_PASSWORD=scrapery
ENV CHROMIUM_USER_DATA_DIR=/data/profile
ENV CHROMIUM_EXTRA_ARGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --disable-setuid-sandbox --disable-dbus"

CMD ["/app/start.sh"]
