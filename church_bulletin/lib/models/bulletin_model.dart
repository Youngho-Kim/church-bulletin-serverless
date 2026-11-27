import 'package:cloud_firestore/cloud_firestore.dart';

class Bulletin {
  final String id; // YYYY-MM-DD (예: 2026-06-14)
  final String date; // 2026.06.14
  final String volume; // 제45권 25호
  final String motto; // 표어: 그리스도를 닮아가는 공동체
  final String mottoVerse; // 히브리서 12장 2절
  final String presider;       // ✅ 추가: 예배 인도자

  // 주일 1부 예배 정보
  final String sundayPrayer;
  final String nextWeekPrayer;
  final String sundayHymn1;
  final String sundayScripture;
  final String sermonSeries;
  final String sermonTitle;
  final String preacher;
  final String offeringHymn;

  // 수요 예배 정보
  final String wedHymn1;
  final String wedScripture;
  final String wedTitle;
  final String wedHymn2;

  // 교회 소식 및 선교편지 / 미디어
  final List<String> announcements;
  final String missionTitle;
  final String missionContent;
  final List<String> imageUrls; // Firebase Storage 다운로드 URL 목록
  final String youtubeUrl;

  Bulletin({
    required this.id,
    required this.date,
    required this.volume,
    required this.motto,
    required this.mottoVerse,
    required this.presider,    // ✅ 추가
    required this.sundayPrayer,
    required this.nextWeekPrayer,
    required this.sundayHymn1,
    required this.sundayScripture,
    required this.sermonSeries,
    required this.sermonTitle,
    required this.preacher,
    required this.offeringHymn,
    required this.wedHymn1,
    required this.wedScripture,
    required this.wedTitle,
    required this.wedHymn2,
    required this.announcements,
    required this.missionTitle,
    required this.missionContent,
    required this.imageUrls,
    required this.youtubeUrl,
  });

  factory Bulletin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final preacher = data['preacher'] ?? '박건용 목사';
    return Bulletin(
      id: doc.id,
      date: data['date'] ?? doc.id,
      volume: data['volume'] ?? '제45권 25호',
      motto: data['motto'] ?? '그리스도를 닮아가는 공동체',
      mottoVerse: data['mottoVerse'] ?? '',
      // 기존 주보 데이터에 presider가 없으면 설교자(preacher)를 기본값으로 사용
      presider: (data['presider'] != null && data['presider'].toString().trim().isNotEmpty)
          ? data['presider']
          : preacher,
      sundayPrayer: data['sundayPrayer'] ?? '',
      nextWeekPrayer: data['nextWeekPrayer'] ?? '',
      sundayHymn1: data['sundayHymn1'] ?? '',
      sundayScripture: data['sundayScripture'] ?? '',
      sermonSeries: data['sermonSeries'] ?? '',
      sermonTitle: data['sermonTitle'] ?? '',
      preacher: data['preacher'] ?? '박건용 목사',
      offeringHymn: data['offeringHymn'] ?? '',
      wedHymn1: data['wedHymn1'] ?? '',
      wedScripture: data['wedScripture'] ?? '',
      wedTitle: data['wedTitle'] ?? '',
      wedHymn2: data['wedHymn2'] ?? '',
      announcements: List<String>.from(data['announcements'] ?? []),
      missionTitle: data['missionTitle'] ?? '',
      missionContent: data['missionContent'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      youtubeUrl: data['youtubeUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'volume': volume,
      'motto': motto,
      'mottoVerse': mottoVerse,
      'presider': presider,    // ✅ 추가
      'sundayPrayer': sundayPrayer,
      'nextWeekPrayer': nextWeekPrayer,
      'sundayHymn1': sundayHymn1,
      'sundayScripture': sundayScripture,
      'sermonSeries': sermonSeries,
      'sermonTitle': sermonTitle,
      'preacher': preacher,
      'offeringHymn': offeringHymn,
      'wedHymn1': wedHymn1,
      'wedScripture': wedScripture,
      'wedTitle': wedTitle,
      'wedHymn2': wedHymn2,
      'announcements': announcements,
      'missionTitle': missionTitle,
      'missionContent': missionContent,
      'imageUrls': imageUrls,
      'youtubeUrl': youtubeUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}