# ⛪ 대방교회 온라인 주간 주보 시스템 (Church Digital Bulletin)

> **실사용자 150~200명 규모의 주간 주보 서비스를 위한 Flutter 반응형 웹/앱 및 Firebase 서버리스(Serverless) 프로덕션 시스템 (`v1.2.0`)**

[![Live Demo](https://img.shields.io/badge/Live_Demo-Firebase_Hosting-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://church-bulletin-service.web.app)
[![Flutter](https://img.shields.io/badge/Flutter-Web_%26_Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase_BaaS-orange?style=for-the-badge&logo=firebase&logoColor=white)](https://firebase.google.com)
[![Release](https://img.shields.io/badge/Release-v1.2.0-2E7D32?style=for-the-badge)](docs/대방교회_온라인_주보_릴리즈_및_수정이력_대장.xlsx)

---

## 1. 프로젝트 배경 및 목표 (Problem & Goal)

기존 양면 3단 접이식 종이 주보(PDF)는 스마트폰 화면에서 글씨가 작아 가독성이 떨어지고, 매주 인쇄 및 배포에 반복적인 리소스가 소요되었습니다.  
별도의 앱 설치나 회원가입 없이 **카카오톡 링크 클릭만으로 PC와 모바일 모두에서 즉시 열람 가능한 디지털 주보 플랫폼**과, 비개발자 관리자도 매주 5분 내에 주보·예배 영상·활동 사진을 등록할 수 있는 **관리자(Admin) CMS**를 구축했습니다.

### 핵심 설계 목표
* **비용 효율적 서버리스 아키텍처:** 주일 오전에 읽기(Read) 트래픽이 집중되는 스파이크성 워크로드에 맞춰 상시 서버 비용 없이 무료 할당량 내에서 자동 확장되는 Firebase BaaS 채택
* **크로스 디바이스 반응형 UI:** PC 웹에서는 3열 정렬 테이블을 유지하고, 모바일에서는 가독성을 높인 2단 카드형 레이아웃으로 자동 전환
* **QA 협업을 고려한 설계 (Design for Testability):** QA 조직의 API 및 E2E 검증을 위한 REST API 명세서, DB 스키마, RBAC 보안 권한 매트릭스 및 버전별 릴리즈 대장 문서화

---

## 2. 시스템 아키텍처 (System Architecture)

```text
+-----------------------------------------------------------------------------------+
|                       [ Client Layer: Flutter Web / Mobile ]                      |
|                                                                                   |
|   +-----------------------------------+     +---------------------------------+   |
|   |   ViewerScreen (성도용 열람 화면)   |     |   AdminScreen (관리자 관리 화면)  |   |
|   |  - 반응형 분기 (Width < 600px)    |     |  - Firebase Auth 로그인 인증     |   |
|   |    * Mobile: 2단 카드형 레이아웃   |     |  - 예배 인도자(presider) 분리   |   |
|   |    * PC Web: 3열 정렬 테이블      |     |  - 다중 이미지 클라이언트 압축    |   |
|   |  - 상단 토글형 인라인 YouTube 카드 |     |    (maxWidth: 1200, quality: 80)|   |
|   |    (showFullscreenButton: false)  |     |  - 등록 주보 CRUD 및 샘플 채우기|   |
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
|   |  - ID Token (JWT) 발급      |    |  - SSL 인증서 및 글로벌 CDN 캐싱       |   |
|   +--------------+--------------+    +----------------------------------------+   |
|                  |                                                                |
|                  +-----------------------+-----------------------+                |
|                  v                       v                       v                |
|   +-----------------------------+    +----------------------------------------+   |
|   |       Cloud Firestore       |    |            Firebase Storage            |   |
|   |  - DaebangBulletins/{id}    |    |  - bulletins/{timestamp}_{file}.jpg    |   |
|   |  - ChurchSettings/info      |    |  - CORS: Origin[*] GET 허용            |   |
|   |  - Rules: Read(All),        |    |  - Rules: Read(All), Write(Admin UID)  |   |
|   |           Write(Admin UID)  |    |                                        |   |
|   +-----------------------------+    +----------------------------------------+   |
+-----------------------------------------------------------------------------------+
```

---

## 3. 주요 엔지니어링 구현 내용 (`v1.2.0` 기준)

### ① 뷰포트 기반 이원화 반응형 레이아웃 및 예배 인도자 분리 (`lib/screens/viewer_screen.dart`)
* 화면 가로 폭(`MediaQuery.of(context).size.width < 600`)을 실시간 감지하여 UI 구조를 분기했습니다.
* **PC Web (`>= 600px`):** 좌측 예배 순서, 중앙 본문/제목(말씀선포 강조 박스), 우측 담당자로 구성된 3열 정렬 테이블 형태로 출력합니다.
* **Mobile (`< 600px`):** 좁은 화면에서의 텍스트 겹침을 원천 차단하기 위해 `순서 ── 담당자` 상단 행과 `내용` 하단 블록의 2단 구조로 자동 전환됩니다.
* **예배 인도자(`presider`)·설교자 분리 및 축도 동기화:** 관리자 페이지에서 설교자와 예배 인도자를 별도로 지정할 수 있으며, 주일 예배 헤더(`인도`)와 주일·수요 축도란에 자동 반영됩니다. (기존 주보 데이터는 설교자로 자동 폴백 처리)

### ② 상단 토글형 인라인 YouTube 플레이어 및 실시간 교회 안내 연동
* **토글형 인라인 영상 카드:** 상단 날짜 선택바 우측의 붉은색 `▶ 예배영상` 버튼을 누를 때만 `youtube_player_iframe` 기반 16:9 플레이어 카드가 펼쳐지며, 카드 닫기(`X`) 또는 주차 변경 시 플레이어 컨트롤러가 자동 해제되어 브라우저 리소스 누수를 방지합니다.
* **동적 교회 안내 연동:** 하단 `예배 시간 및 섬기는 이들 안내` 섹션은 Firestore `ChurchSettings/info` 문서를 실시간 구독하여 앱 재배포 없이도 운영 정보를 즉시 갱신할 수 있습니다.

### ③ 클라이언트 사이드 이미지 자동 압축 및 Storage 파이프라인 (`lib/screens/admin_screen.dart`)
* 고화질 스마트폰 원본 사진(장당 4~8MB)을 그대로 업로드할 경우 발생하는 스토리지 및 트래픽 초과를 방지하기 위해, 클라이언트 단에서 `image` 패키지로 리사이징·압축(`maxWidth: 1200, quality: 80`)을 수행합니다.
* 별도 백엔드 이미지 처리 서버 없이 장당 200~300KB 수준으로 압축 후 Firebase Storage에 직접 업로드하고 다운로드 URL을 Firestore 문서에 바인딩합니다.

### ④ 서버 측 보안 규칙(Security Rules) 기반 RBAC 접근 제어
* 프론트엔드 UI 숨김 처리만으로는 REST API 직접 호출 우회를 막을 수 없으므로, Firestore(`DaebangBulletins`, `ChurchSettings/info`)와 Storage의 서버 측 Security Rules에 `request.auth.uid` 검증을 적용하여 **비로그인 읽기(Read-Only)와 관리자 전용 쓰기(Write)**를 엄격히 분리했습니다.

---

## 4. 프로덕션 트러블슈팅 (Production Troubleshooting)

실제 웹 배포 및 크로스 디바이스 검증 과정에서 발생한 핵심 이슈와 근본 원인 해결(RCA) 내역입니다.

| 이슈 구분 | 발생 증상 및 원인 | 해결 방안 (Engineering Solution) |
| :--- | :--- | :--- |
| **외부 이미지 CORS 차단** | 초기 Google Drive 외부 링크 연동 시 Flutter Web 렌더러에서 브라우저 CORS 정책 위반(`statusCode: 0`) 발생 | 외부 링크 방식을 폐기하고, 클라이언트 자동 압축 후 Firebase Storage에 직접 업로드하는 자체 미디어 파이프라인으로 전환 |
| **Storage 버킷 CORS 정책** | Storage 업로드 성공 후 웹 브라우저에서 썸네일 호출 시 `statusCode: 0` 에러 발생 | Google Cloud Shell에서 `cors.json`을 정의하고 `gsutil cors set` 명령어로 버킷 레벨의 `GET` 요청 CORS 헤더 허용 |
| **동적 텍스트 UI 오버플로우** | 긴 직함 입력 시 우측 고정폭 열에서 화면 경계 오버플로우 발생 및 모바일 좁은 폭에서의 텍스트 겹침 | `600px` 기준 반응형 분기(`_buildResponsiveWorshipRow`)를 적용하여 모바일에서는 2단 카드형, PC에서는 3열 테이블형으로 구조 분리 |
| **배포 후 캐시 고착 이슈** | `firebase deploy` 완료 후에도 Flutter Web의 기본 Service Worker가 이전 빌드를 캐싱하여 신규 배포본 미반영 | 브라우저 Site Data 초기화 및 빌드 캐시 제어를 적용해 배포 즉시 최신 버전이 반영되도록 개선 |
| **웹 인라인 YouTube 전체화면 충돌 (`v1.2.0`)** | 카드 레이아웃 내부의 `<iframe>`에서 자체 전체화면 API 호출 시 브라우저 레이어 충돌로 렌더링 오류 발생 | `YoutubePlayerParams`의 `showFullscreenButton: false`로 내부 충돌을 차단하고, 카드 우측 상단에 외부 창으로 열리는 `크게 보기` 버튼을 분리 배치 |

---

## 5. 화면 미리보기 (Screenshots)

| PC 웹 뷰어 (3열 정렬 양식) | 모바일 뷰어 (2단 카드형) | 관리자 사진 압축 업로드 |
| :---: | :---: | :---: |
| ![PC Viewer](docs/images/pc_viewer.png) | ![Mobile Viewer](docs/images/mobile_viewer.png) | ![Admin Upload](docs/images/admin_upload.png) |

---

## 6. 프로젝트 구조 (Directory Structure)

```text
church-bulletin-serverless/
├── docs/
│   ├── images/
│   │   ├── pc_viewer.png
│   │   ├── mobile_viewer.png
│   │   └── admin_upload.png
│   ├── 대방교회_온라인_주보_구축_및_트러블슈팅_보고서_v1.2.docx
│   ├── 대방교회_온라인_주보_QA_검증_및_API_명세서_v1.2.docx
│   └── 대방교회_온라인_주보_릴리즈_및_수정이력_대장.xlsx
├── church_bulletin/
│   └── lib/
│       ├── models/
│       │   └── bulletin_model.dart
│       ├── screens/
│       │   ├── viewer_screen.dart
│       │   └── admin_screen.dart
│       ├── firebase_options.example.dart
│       └── main.dart
├── .gitignore
└── README.md
```

---

## 7. 기술 문서 및 QA 핸드오프 산출물 (`docs/`)

개발 및 운영 고도화 과정에서 QA 조직이 블랙박스/화이트박스 테스트와 변경 이력 추적을 즉시 수행할 수 있도록 아래 공식 문서를 작성하여 관리하고 있습니다.

* 📄 **[구축 및 트러블슈팅 보고서 (v1.2)](docs/대방교회_온라인_주보_구축_및_트러블슈팅_보고서_v1.2.docx):** 릴리즈 노트(1페이지), 전체 시스템 설계, 구현 상세, 트러블슈팅 7건 요약 및 주간 운영 매뉴얼
* 📄 **[QA 검증 및 API 명세서 (v1.2)](docs/대방교회_온라인_주보_QA_검증_및_API_명세서_v1.2.docx):** 릴리즈 노트(1페이지), Firebase REST API 엔드포인트 명세, cURL 샘플, DB 스키마 정의서, 보안 권한 매트릭스 및 E2E 테스트 케이스 12종
* 📊 **[버전별 릴리즈 및 수정 이력 대장](docs/대방교회_온라인_주보_릴리즈_및_수정이력_대장.xlsx):** `v1.0.0` ~ `v1.2.0` 세부 변경 이력, QA 검증 포인트 및 자동 집계 요약 대시보드

---

## 8. 로컬 실행 및 배포 방법 (Build & Deploy)

```bash
# 1. 프로젝트 앱 폴더 이동 및 의존성 패키지 설치
cd church_bulletin
flutter pub get

# 2. 로컬 웹 개발 서버 실행
flutter run -d chrome

# 3. 프로덕션 릴리즈 빌드 및 Firebase Hosting 배포
flutter build web --release
firebase deploy --only hosting
```