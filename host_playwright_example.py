"""
Host-side Playwright example that connects to the running container's Chromium via CDP
and performs navigation and a simple login flow example (pseudo-credentials).

Usage: ensure the container is running and that port 9222 is reachable from the host.

python3 host_playwright_example.py
"""
from playwright.sync_api import sync_playwright

CDP_ENDPOINT = "http://127.0.0.1:9222"

with sync_playwright() as p:
    # Connect to the browser over CDP
    browser = p.chromium.connect_over_cdp(CDP_ENDPOINT)
    try:
        # Create a new context and page via CDP connection
        context = browser.contexts[0] if browser.contexts else browser.new_context()
        page = context.new_page()
        # Example: navigate to a login page and fill credentials
        page.goto('https://example.com')
        print('Title:', page.title())
        # -- Replace below with actual selectors/steps from the real target --
        # page.goto('https://example.com/login')
        # page.fill('#username', 'MY_USERNAME')
        # page.fill('#password', 'MY_PASSWORD')
        # page.click('#submit')
        # page.wait_for_load_state('networkidle')
        # print('Logged in, URL:', page.url)
        # Take a screenshot
        page.screenshot(path='host_connected_screenshot.png', full_page=True)
        print('Screenshot saved to host_connected_screenshot.png')
    finally:
        try:
            context.close()
        except Exception:
            pass
        try:
            browser.close()
        except Exception:
            pass
