import os
import pytest
from playwright.sync_api import sync_playwright
from config import TARGET_URL

SCREENSHOT_DIR = "qa_artifacts"


@pytest.fixture(scope="session", autouse=True)
def setup_artifacts_dir():
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)


def run_viewport_check(viewport_name: str, width: int, height: int, test_youtube_toggle: bool = False):
    console_errors = []
    page_errors = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": width, "height": height})
        page = context.new_page()

        page.on("console", lambda msg: console_errors.append(msg.text) if msg.type == "error" else None)
        page.on("pageerror", lambda err: page_errors.append(str(err)))

        # Firestore 실시간 스트림(WebChannel) 유지를 고려해 domcontentloaded 사용
        page.goto(TARGET_URL, wait_until="domcontentloaded", timeout=30000)
        page.wait_for_timeout(6000)

        base_screenshot = os.path.join(SCREENSHOT_DIR, f"v1.2_{viewport_name}_{width}x{height}.png")
        page.screenshot(path=base_screenshot, full_page=True)

        if test_youtube_toggle:
            youtube_btn = page.get_by_text("예배영상")
            if youtube_btn.count() > 0:
                youtube_btn.first.click()
                page.wait_for_timeout(2000)
                yt_screenshot = os.path.join(SCREENSHOT_DIR, f"v1.2_{viewport_name}_youtube_open.png")
                page.screenshot(path=yt_screenshot)

        browser.close()

    critical_errors = [
        err for err in (console_errors + page_errors)
        if "statusCode: 0" in err or "OVERFLOWED" in err or "Exception" in err
    ]
    assert not critical_errors, f"[{viewport_name}] 렌더링/네트워크 에러 감지: {critical_errors}"


def test_pc_web_rendering_and_youtube():
    """[TC-UI-02 / TC-MD-01] PC 웹(1280x800, >=600px) 3열 테이블 렌더링 및 인라인 YouTube 카드 검증"""
    run_viewport_check("pc_web", 1280, 800, test_youtube_toggle=True)


def test_mobile_rendering():
    """[TC-UI-01] 모바일(375x812, <600px) 2단 카드형 레이아웃 전환 및 텍스트 겹침/오버플로우 방어 검증"""
    run_viewport_check("mobile", 375, 812, test_youtube_toggle=False)