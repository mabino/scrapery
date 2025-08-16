FROM mcr.microsoft.com/playwright:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install lightweight window manager, VNC server and utilities
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       fluxbox x11vnc xvfb dbus-x11 procps net-tools ca-certificates fonts-liberation \
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
    && python3 -m pip install --upgrade pip setuptools \
    && python3 -m pip install --no-cache-dir -r /app/requirements.txt \
    && python3 -m playwright install --with-deps || true

COPY app.py /app/app.py
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 5900 9222 3000

# Defaults: allow mounting a host profile to /data/profile or providing a Playwright storageState at /data/session.json
ENV DISPLAY=:99
ENV VNC_PASSWORD=scrapery
ENV CHROMIUM_USER_DATA_DIR=/data/profile
ENV CHROMIUM_EXTRA_ARGS="--no-sandbox --disable-dev-shm-usage --disable-gpu"

CMD ["/app/start.sh"]
