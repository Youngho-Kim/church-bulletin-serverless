import requests
import pytest
from config import PROJECT_ID, API_KEY

BASE_DOCUMENTS_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
BULLETINS_URL = f"{BASE_DOCUMENTS_URL}/DaebangBulletins"
SETTINGS_URL = f"{BASE_DOCUMENTS_URL}/ChurchSettings/info"


def get_latest_bulletin():
    """최신 주보 1건 조회 헬퍼 함수"""
    url = f"{BULLETINS_URL}?pageSize=1&orderBy=date%20desc&key={API_KEY}"
    res = requests.get(url, timeout=10)
    assert res.status_code == 200, f"Firestore 조회 실패: {res.status_code}, {res.text}"
    docs = res.json().get("documents", [])
    assert len(docs) > 0, "등록된 주보 문서가 0건입니다."
    return docs[0]


def test_public_read_access():
    """[TC-API-02] 비로그인 성도 권한으로 주보 목록 및 교회 안내(ChurchSettings/info) 조회 (200 OK 기대)"""
    doc = get_latest_bulletin()
    assert "fields" in doc, "주보 문서에 fields 데이터가 존재하지 않습니다."

    settings_res = requests.get(f"{SETTINGS_URL}?key={API_KEY}", timeout=10)
    assert settings_res.status_code == 200, f"ChurchSettings/info 조회 실패: {settings_res.status_code}"


def test_unauthorized_write_blocked():
    """[TC-API-01] 비로그인 상태 주보 및 교회 안내 변조/삭제 차단 검증 (403 PERMISSION_DENIED 기대)"""
    target_bulletin = f"{BULLETINS_URL}/9999-12-31?key={API_KEY}"

    patch_res = requests.patch(
        target_bulletin,
        json={"fields": {"sermonTitle": {"stringValue": "보안 침투 테스트"}}},
        timeout=10
    )
    assert patch_res.status_code == 403, f"보안 취약점! 비로그인 주보 PATCH 허용됨: {patch_res.status_code}"

    delete_res = requests.delete(target_bulletin, timeout=10)
    assert delete_res.status_code == 403, f"보안 취약점! 비로그인 주보 DELETE 허용됨: {delete_res.status_code}"

    settings_patch_res = requests.patch(
        f"{SETTINGS_URL}?key={API_KEY}",
        json={"fields": {"test": {"stringValue": "hack"}}},
        timeout=10
    )
    assert settings_patch_res.status_code == 403, f"보안 취약점! 비로그인 ChurchSettings 변조 허용됨: {settings_patch_res.status_code}"


def test_latest_bulletin_schema_v1_2():
    """[TC-DATA-01 / TC-UI-03~04] 최신 주보 필수 필드 및 presider/preacher 스키마 정합성 검증"""
    doc = get_latest_bulletin()
    fields = doc.get("fields", {})

    required_fields = [
        "date", "volume", "sundayPrayer", "nextWeekPrayer",
        "sundayHymn1", "sundayScripture", "sermonTitle", "preacher", "offeringHymn"
    ]

    missing_or_empty = []
    for field in required_fields:
        val = fields.get(field, {}).get("stringValue", "").strip()
        if not val:
            missing_or_empty.append(field)

    assert not missing_or_empty, f"최신 주보에 필수 항목 누락/공백 발생: {missing_or_empty}"

    # v1.2.0 예배 인도자(presider) 존재 여부 또는 preacher 폴백 가능 여부 확인
    presider = fields.get("presider", {}).get("stringValue", "").strip()
    preacher = fields.get("preacher", {}).get("stringValue", "").strip()
    effective_presider = presider if presider else preacher
    assert effective_presider, "예배 인도자(presider)와 설교자(preacher)가 모두 비어 있습니다."


def test_attached_images_and_youtube_validity():
    """[TC-API-03] 첨부된 Firebase Storage 이미지 URL(200 OK) 및 유튜브 링크 유효성 검사"""
    doc = get_latest_bulletin()
    fields = doc.get("fields", {})

    # 1. Storage 이미지 URL 상태 코드 및 CORS 정상 로드 검증
    image_values = fields.get("imageUrls", {}).get("arrayValue", {}).get("values", [])
    for img in image_values:
        img_url = img.get("stringValue", "")
        if img_url:
            res = requests.get(img_url, timeout=10)
            assert res.status_code == 200, f"이미지 로드 실패 (CORS 또는 파일 유실): {img_url} -> {res.status_code}"

    # 2. 유튜브 링크 유효성 검증 (입력된 경우에만)
    youtube_url = fields.get("youtubeUrl", {}).get("stringValue", "").strip()
    if youtube_url:
        assert youtube_url.startswith(("https://youtu.be/", "https://www.youtube.com/")), \
            f"잘못된 유튜브 URL 형식: {youtube_url}"