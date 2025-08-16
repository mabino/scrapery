import os
from flask import Flask, request, jsonify
from playwright.sync_api import sync_playwright
import threading

app = Flask(__name__)

PLAYWRIGHT_LOCK = threading.Lock()

@app.route('/')
def index():
    return jsonify({"status": "ok"})

@app.route('/screenshot', methods=['POST'])
def screenshot():
    data = request.json or {}
    url = data.get('url')
    storage_state = data.get('storageState')
    if not url:
        return jsonify({'error': 'url required'}), 400

    with PLAYWRIGHT_LOCK:
        with sync_playwright() as p:
            browser = p.chromium.connect_over_cdp('http://localhost:9223')
            context = browser.contexts[0] if browser.contexts else browser.new_context()
            # If provided, load storage state
            if storage_state:
                # storage_state should be a dict matching Playwright storageState
                context = browser.new_context(storage_state=storage_state)
            page = context.new_page()
            page.goto(url)
            path = '/tmp/screenshot.png'
            page.screenshot(path=path, full_page=True)
            # Cleanup
            page.close()
            context.close()
            browser.close()
    return jsonify({'screenshot': path})

@app.route('/status')
def status():
    return jsonify({'playwright': 'attached via CDP', 'vnc_port': 5900, 'debug_port': 9222})

if __name__ == '__main__':
    port = int(os.environ.get('API_PORT', '3000'))
    app.run(host='0.0.0.0', port=port)
