import os
from pathlib import Path

def load_qa_env():
    """로컬에 qa_automation/.env 파일이 있으면 환경변수로 로드하고, 없으면(GitHub Actions 등) 시스템 환경변수를 그대로 사용"""
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ.setdefault(key.strip(), value.strip())

load_qa_env()

PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")
API_KEY = os.getenv("FIREBASE_WEB_API_KEY")
TARGET_URL = os.getenv("BULLETIN_TARGET_URL")

assert PROJECT_ID and API_KEY and TARGET_URL, (
    "필수 설정값이 누락되었습니다. 로컬에서는 qa_automation/.env 파일을 생성하고, "
    "GitHub Actions에서는 Secrets(FIREBASE_PROJECT_ID, FIREBASE_WEB_API_KEY, BULLETIN_TARGET_URL)를 확인하세요."
)