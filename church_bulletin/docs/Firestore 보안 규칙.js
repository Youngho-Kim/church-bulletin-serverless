rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
  // 1. 기존 주간 주보 데이터 규칙
    match /DaebangBulletins/{bulletinId} {
      // 모든 성도(비로그인 포함)에게 주보 열람 허용
      allow read: if true;
      
      // 지정된 관리자 UID로 로그인한 경우에만 작성, 수정, 삭제 허용
      allow write: if request.auth != null && request.auth.uid == "YOUR_ADMIN_UID";
    }
    // 2. 새로 추가할 교회 고정 안내 정보 규칙
    match /ChurchSettings/{docId} {
      allow read: if true; 
      allow write: if request.auth != null && request.auth.uid == 'YOUR_ADMIN_UID'; 
    }
  }
}