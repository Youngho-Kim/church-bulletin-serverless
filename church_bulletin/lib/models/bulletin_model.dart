import 'package:cloud_firestore/cloud_firestore.dart';

class Bulletin {
  final String id;
  final String date;
  final String volume;
  final String motto;
  final String mottoVerse;
  final String presider; // 주일 예배 인도자 (축도자 겸용)
  final String sundayPrayer;
  final String nextWeekPrayer;
  final String sundayHymn1;
  final String offeringHymn;
  final String sundayScripture;
  final String sermonSeries;
  final String sermonTitle;
  final String preacher;
  final String wedHymn1;
  final String wedHymn2;
  final String wedScripture;
  final String wedTitle;
  final List<String> announcements;
  final String missionTitle;
  final String missionContent;
  final List<String> imageUrls;
  final String youtubeUrl;

  Bulletin({
    required this.id,
    required this.date,
    required this.volume,
    required this.motto,
    required this.mottoVerse,
    required this.presider,
    required this.sundayPrayer,
    required this.nextWeekPrayer,
    required this.sundayHymn1,
    required this.offeringHymn,
    required this.sundayScripture,
    required this.sermonSeries,
    required this.sermonTitle,
    required this.preacher,
    required this.wedHymn1,
    required this.wedHymn2,
    required this.wedScripture,
    required this.wedTitle,
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
      date: data['date'] ?? '',
      volume: data['volume'] ?? '',
      motto: data['motto'] ?? '',
      mottoVerse: data['mottoVerse'] ?? '',
      // 기존 데이터에 presider가 없으면 설교자(preacher)를 기본값으로 적용
      presider: (data['presider'] != null &&
              data['presider'].toString().trim().isNotEmpty)
          ? data['presider']
          : preacher,
      sundayPrayer: data['sundayPrayer'] ?? '',
      nextWeekPrayer: data['nextWeekPrayer'] ?? '',
      sundayHymn1: data['sundayHymn1'] ?? '',
      offeringHymn: data['offeringHymn'] ?? '',
      sundayScripture: data['sundayScripture'] ?? '',
      sermonSeries: data['sermonSeries'] ?? '',
      sermonTitle: data['sermonTitle'] ?? '',
      preacher: preacher,
      wedHymn1: data['wedHymn1'] ?? '',
      wedHymn2: data['wedHymn2'] ?? '',
      wedScripture: data['wedScripture'] ?? '',
      wedTitle: data['wedTitle'] ?? '',
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
      'presider': presider,
      'sundayPrayer': sundayPrayer,
      'nextWeekPrayer': nextWeekPrayer,
      'sundayHymn1': sundayHymn1,
      'offeringHymn': offeringHymn,
      'sundayScripture': sundayScripture,
      'sermonSeries': sermonSeries,
      'sermonTitle': sermonTitle,
      'preacher': preacher,
      'wedHymn1': wedHymn1,
      'wedHymn2': wedHymn2,
      'wedScripture': wedScripture,
      'wedTitle': wedTitle,
      'announcements': announcements,
      'missionTitle': missionTitle,
      'missionContent': missionContent,
      'imageUrls': imageUrls,
      'youtubeUrl': youtubeUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}