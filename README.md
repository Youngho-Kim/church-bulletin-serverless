# ⛪ 온라인 주간 주보 시스템 (Church Digital Bulletin)

> **실사용자 150~200명 규모의 주간 주보 서비스를 위한 Flutter 반응형 웹/앱 및 Firebase 서버리스(Serverless) 프로덕션 시스템**

[![Live Demo](https://img.shields.io/badge/Live_Demo-Firebase_Hosting-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://church-bulletin-service.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-Web_%26_Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase_BaaS-orange?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)

---

## 1. 프로젝트 배경 및 목표 (Problem & Goal)

기존 양면 3단 접이식 종이 주보(PDF)는 스마트폰 화면에서 글씨가 작아 가독성이 떨어지고, 매주 인쇄 및 배포에 반복적인 리소스가 소요되었습니다.  
별도의 앱 설치나 회원가입 없이 **카카오톡 링크 클릭만으로 PC와 모바일 모두에서 즉시 열람 가능한 디지털 주보 플랫폼**과, 비개발자 관리자도 매주 5분 내에 주보 및 활동 사진을 등록할 수 있는 **관리자(Admin) CMS**를 구축했습니다.

### 핵심 설계 목표
* **비용 효율적 서버리스 아키텍처:** 주일 오전에 읽기(Read) 트래픽이 집중되는 스파이크성 워크로드에 맞춰 상시 서버 비용 없이 자동 확장되는 Firebase BaaS 채택
* **크로스 디바이스 반응형 UI:** PC 웹에서는 전통 종이 주보의 3단 점선 양식을 유지하고, 모바일에서는 가독성을 높인 2줄 카드형 레이아웃으로 자동 전환
* **QA 협업을 고려한 설계 (Design for Testability):** QA 조직의 API 및 E2E 검증을 위한 REST API 명세서, DB 스키마, RBAC 보안 권한 매트릭스 문서화

---

## 2. 시스템 아키텍처 (System Architecture)

```text
+-----------------------------------------------------------------------------------+
|                       [ Client Layer: Flutter Web / Mobile ]                      |
|                                                                                   |
|   +-----------------------------------+     +---------------------------------+   |
|   |   ViewerScreen (성도용 열람 화면)   |     |   AdminScreen (관리자 관리 화면)  |   |
|   |  - LayoutBuilder 반응형 분기       |     |  - Firebase Auth 로그인 인증     |   |
|   |    * Mobile (<520px): 2줄 카드형   |     |  - ImagePicker 클라이언트 압축    |   |
|   |    * PC Web (>=520px): 3단 점선형  |     |    (maxWidth: 1200, quality: 80)|   |
|   +-----------------+-----------------+     +--------+---------------+--------+   |
+---------------------|--------------------------------|---------------|------------+
                      | (1) Read Only                  | (2) Auth      | (3) Write
                      | (Unauthenticated)              | (JWT Token)   | (Admin UID)
                      v                                v               v
+-----------------------------------------------------------------------------------+
|                      [ Backend Layer: Google Firebase BaaS ]                      |
|                                                                                   |
|   +-----------------------------+    +----------------------------------------+   |
|   |   Firebase Authentication   |    |            Firebase Hosting            |   |
|   |  - Email/Password 인증      |    |  - 정적 웹 에셋 배포 (build/web)        |   |
|   |  - ID Token (JWT) 발급      |    |  - --pwa-strategy=none (캐시 고착 방지) |   |
|   +--------------+--------------+    +----------------------------------------+   |
|                  |                                                                |
|                  +-----------------------+-----------------------+                |
|                  v                       v                       v                |
|   +-----------------------------+    +----------------------------------------+   |
|   |       Cloud Firestore       |    |            Firebase Storage            |   |
|   |  - Bulletins/{id}    |    |  - bulletins/{YYYY-MM-DD}/{file}.jpg   |   |
|   |  - Rules: Read(All),        |    |  - CORS: Origin[*] GET 허용            |   |
|   |           Write(Admin UID)  |    |  - Rules: Read(All), Write(Admin UID)  |   |
|   +-----------------------------+    +----------------------------------------+   |
+-----------------------------------------------------------------------------------+
```

---

## 3. 주요 엔지니어링 구현 내용

### ① 뷰포트 기반 이원화 반응형 레이아웃 (`lib/screens/viewer_screen.dart`)
* `LayoutBuilder`를 통해 화면 가로 폭(`constraints.maxWidth < 520`)을 실시간 감지하여 UI 구조를 분기했습니다.
* **PC Web (`>= 520px`):** 좌측 예배 순서와 우측 담당자 열의 글자 자간을 양끝 균등 배분(`MainAxisAlignment.spaceBetween`)하고, 중앙 설명 양옆의 빈 공간을 동적 점선 리더선(`_buildDotLine`)으로 채워 전통 종이 주보의 심미성을 구현했습니다.
* **Mobile (`< 520px`):** 좁은 화면에서의 텍스트 겹침을 원천 차단하기 위해 `순서 ── 담당자` 상단 행과 `설명` 하단 카드의 2줄 구조로 자동 전환됩니다.

### ② 클라이언트 사이드 이미지 자동 압축 및 Storage 파이프라인 (`lib/screens/admin_screen.dart`)
* 고화질 스마트폰 원본 사진(장당 4~8MB)을 그대로 업로드할 경우 발생하는 스토리지 및 일일 다운로드 트래픽(1GB 무료 한도) 초과를 방지하기 위해 `image_picker`의 리사이징 옵션(`maxWidth: 1200, imageQuality: 80`)을 적용했습니다.
* 별도 백엔드 이미지 처리 서버 없이 클라이언트에서 장당 200~300KB 수준으로 압축 후 Firebase Storage에 직접 업로드하고 다운로드 URL을 Firestore 문서에 트랜잭션 형태로 바인딩합니다.

### ③ 서버 측 보안 규칙(Security Rules) 기반 RBAC 접근 제어
* 프론트엔드 UI 숨김 처리만으로는 REST API 직접 호출 우회를 막을 수 없으므로, Firestore와 Storage의 서버 측 Security Rules에 `request.auth.uid` 검증을 적용하여 **비로그인 읽기(Read-Only)와 관리자 전용 쓰기(Write)**를 엄격히 분리했습니다.

---

## 4. 프로덕션 트러블슈팅 (Production Troubleshooting)

실제 웹 배포 및 크로스 디바이스 검증 과정에서 발생한 핵심 이슈와 근본 원인 해결(RCA) 내역입니다.

| 이슈 구분 | 발생 증상 및 원인 | 해결 방안 (Engineering Solution) |
| :--- | :--- | :--- |
| **외부 이미지 CORS 차단** | 초기 Google Drive 외부 링크 연동 시 Flutter Web CanvasKit 렌더러에서 브라우저 CORS 정책 위반(`statusCode: 0`) 발생 | 외부 링크 방식을 폐기하고, 클라이언트 자동 압축 후 Firebase Storage에 직접 업로드하는 자체 미디어 파이프라인으로 전환 |
| **Storage 버킷 CORS 정책** | Storage 업로드 성공 후 웹 브라우저에서 썸네일 호출 시 `statusCode: 0` 에러 발생 | Google Cloud Shell에서 `cors.json`을 정의하고 `gsutil cors set` 명령어로 버킷 레벨의 `GET` 요청 CORS 헤더 허용 |
| **동적 텍스트 UI 오버플로우** | `'박XX 담임목사님'` 등 7글자 이상의 긴 직함 입력 시 우측 고정폭 열에서 `RIGHT OVERFLOWED BY 37 PIXELS` 발생 | 좌우 열 너비를 88px로 확장하고, 6글자 이상 텍스트에 `FittedBox(fit: BoxFit.scaleDown)` 방어 로직 적용 |
| **배포 후 캐시 고착 이슈** | `firebase deploy` 완료 후에도 Flutter Web의 기본 Service Worker가 이전 빌드를 캐싱하여 신규 배포본 미반영 | 빌드 파이프라인에 `--pwa-strategy=none` 옵션을 적용해 Service Worker 캐시 고착을 제거하고 배포 즉시 최신 버전 반영 |

---

## 5. 화면 미리보기 (Screenshots)

| PC 웹 뷰어 (3단 점선 양식) | 모바일 뷰어 (2줄 카드형) | 관리자 사진 압축 업로드 |
| :---: | :---: | :---: |
| ![PC Viewer](docs/images/pc_viewer.png) | ![Mobile Viewer](docs/images/mobile_viewer.png) | ![Admin Upload](docs/images/admin_upload.png) |

---

## 6. 기술 문서 및 QA 핸드오프 산출물 (`docs/`)

개발 완료 후 QA 조직이 블랙박스/화이트박스 테스트를 즉시 수행할 수 있도록 아래 공식 문서를 작성하여 관리하고 있습니다.

* 📄 **[구축 및 트러블슈팅 보고서](docs/교회온라인_주보_구축_및_트러블슈팅_보고서.docx):** 전체 시스템 설계, 구현 상세, 트러블슈팅 요약 및 주간 운영 매뉴얼
* 📄 **[QA 검증 및 API 명세서](docs/교회온라인_주보_QA_검증_및_API_명세서.docx):** Firebase REST API 엔드포인트 명세, cURL 샘플, DB 스키마 정의서, 보안 권한 매트릭스 및 E2E 테스트 케이스

---

## 7. 로컬 실행 및 배포 방법 (Build & Deploy)

```bash
# 1. 의존성 패키지 설치
flutter pub get

# 2. 로컬 웹 개발 서버 실행
flutter run -d chrome

# 3. 프로덕션 릴리즈 빌드 (캐시 방지 전략 적용) 및 Firebase Hosting 배포
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting
```