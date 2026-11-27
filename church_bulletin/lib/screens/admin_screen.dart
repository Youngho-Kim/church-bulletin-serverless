import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/bulletin_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 주보 입력 컨트롤러
  final _dateController = TextEditingController();
  final _volumeController = TextEditingController(text: '제45권 25호');
  final _mottoController = TextEditingController(text: '그리스도를 닮아가는 공동체');
  final _mottoVerseController = TextEditingController();
  final _presiderController = TextEditingController(text: '박건용 목사');
  final _sundayPrayerController = TextEditingController();
  final _nextWeekPrayerController = TextEditingController();
  final _sundayHymn1Controller = TextEditingController();
  final _offeringHymnController = TextEditingController();
  final _sundayScriptureController = TextEditingController();
  final _sermonSeriesController = TextEditingController();
  final _sermonTitleController = TextEditingController();
  final _preacherController = TextEditingController(text: '박건용 목사');

  final _wedHymn1Controller = TextEditingController();
  final _wedHymn2Controller = TextEditingController();
  final _wedScriptureController = TextEditingController();
  final _wedTitleController = TextEditingController();

  final _announcementsController = TextEditingController();
  final _missionTitleController = TextEditingController();
  final _missionContentController = TextEditingController();
  final _youtubeUrlController = TextEditingController();

  List<String> _uploadedImageUrls = [];
  String? _editingDocId;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _dateController.dispose();
    _volumeController.dispose();
    _mottoController.dispose();
    _mottoVerseController.dispose();
    _presiderController.dispose();
    _sundayPrayerController.dispose();
    _nextWeekPrayerController.dispose();
    _sundayHymn1Controller.dispose();
    _offeringHymnController.dispose();
    _sundayScriptureController.dispose();
    _sermonSeriesController.dispose();
    _sermonTitleController.dispose();
    _preacherController.dispose();
    _wedHymn1Controller.dispose();
    _wedHymn2Controller.dispose();
    _wedScriptureController.dispose();
    _wedTitleController.dispose();
    _announcementsController.dispose();
    _missionTitleController.dispose();
    _missionContentController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    }
  }

  void _fillSampleData() {
    setState(() {
      _editingDocId = null;
      _dateController.text = '2026-06-21';
      _volumeController.text = '제45권 26호';
      _mottoController.text = '그리스도를 닮아가는 공동체';
      _mottoVerseController.text = '빌립보서 2:5';
      _presiderController.text = '박건용 목사';
      _sundayPrayerController.text = '임익빈 장로';
      _nextWeekPrayerController.text = '이원태 안수집사';
      _sundayHymn1Controller.text = '488장';
      _offeringHymnController.text = '482장';
      _sundayScriptureController.text = '롬 8:17-25';
      _sermonSeriesController.text = '로마서 강해(14)';
      _sermonTitleController.text = '우리 몸의 속량을 기다리느니라';
      _preacherController.text = '박건용 목사';
      _wedHymn1Controller.text = '384장';
      _wedHymn2Controller.text = '435장';
      _wedScriptureController.text = '시편 23:1-6';
      _wedTitleController.text = '여호와는 나의 목자시니';
      _announcementsController.text =
          '오늘 예배에 참석하신 모든 성도님들을 환영합니다.\n다음 주일은 맥추감사주일로 지킵니다.';
      _missionTitleController.text = '6월 협력 선교사 소식';
      _missionContentController.text =
          '현지 사역과 성도들의 영적 성장을 위해 함께 기도해 주세요.';
      _youtubeUrlController.text = '';
    });
  }

  void _loadBulletinToForm(Bulletin b) {
    setState(() {
      _editingDocId = b.id;
      _dateController.text = b.date;
      _volumeController.text = b.volume;
      _mottoController.text = b.motto;
      _mottoVerseController.text = b.mottoVerse;
      _presiderController.text = b.presider;
      _sundayPrayerController.text = b.sundayPrayer;
      _nextWeekPrayerController.text = b.nextWeekPrayer;
      _sundayHymn1Controller.text = b.sundayHymn1;
      _offeringHymnController.text = b.offeringHymn;
      _sundayScriptureController.text = b.sundayScripture;
      _sermonSeriesController.text = b.sermonSeries;
      _sermonTitleController.text = b.sermonTitle;
      _preacherController.text = b.preacher;
      _wedHymn1Controller.text = b.wedHymn1;
      _wedHymn2Controller.text = b.wedHymn2;
      _wedScriptureController.text = b.wedScripture;
      _wedTitleController.text = b.wedTitle;
      _announcementsController.text = b.announcements.join('\n');
      _missionTitleController.text = b.missionTitle;
      _missionContentController.text = b.missionContent;
      _uploadedImageUrls = List<String>.from(b.imageUrls);
      _youtubeUrlController.text = b.youtubeUrl;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${b.date} 주보 데이터를 불러왔습니다.')),
    );
  }

  Future<void> _pickAndUploadImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      for (final file in pickedFiles) {
        final rawBytes = await file.readAsBytes();
        final decoded = img.decodeImage(rawBytes);
        Uint8List uploadBytes = rawBytes;

        if (decoded != null) {
          final resized = decoded.width > 1200
              ? img.copyResize(decoded, width: 1200)
              : decoded;
          uploadBytes =
              Uint8List.fromList(img.encodeJpg(resized, quality: 80));
        }

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('bulletins')
            .child(fileName);

        await ref.putData(
            uploadBytes, SettableMetadata(contentType: 'image/jpeg'));
        final downloadUrl = await ref.getDownloadURL();
        _uploadedImageUrls.add(downloadUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 압축 및 업로드가 완료되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveBulletin() async {
    final dateText = _dateController.text.trim();
    if (dateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주일 날짜(YYYY-MM-DD)를 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final preacherText = _preacherController.text.trim().isEmpty
          ? '박건용 목사'
          : _preacherController.text.trim();
      final presiderText = _presiderController.text.trim().isEmpty
          ? preacherText
          : _presiderController.text.trim();

      final bulletin = Bulletin(
        id: _editingDocId ?? dateText,
        date: dateText,
        volume: _volumeController.text.trim(),
        motto: _mottoController.text.trim(),
        mottoVerse: _mottoVerseController.text.trim(),
        presider: presiderText,
        sundayPrayer: _sundayPrayerController.text.trim(),
        nextWeekPrayer: _nextWeekPrayerController.text.trim(),
        sundayHymn1: _sundayHymn1Controller.text.trim(),
        offeringHymn: _offeringHymnController.text.trim(),
        sundayScripture: _sundayScriptureController.text.trim(),
        sermonSeries: _sermonSeriesController.text.trim(),
        sermonTitle: _sermonTitleController.text.trim(),
        preacher: preacherText,
        wedHymn1: _wedHymn1Controller.text.trim(),
        wedHymn2: _wedHymn2Controller.text.trim(),
        wedScripture: _wedScriptureController.text.trim(),
        wedTitle: _wedTitleController.text.trim(),
        announcements: _announcementsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        missionTitle: _missionTitleController.text.trim(),
        missionContent: _missionContentController.text.trim(),
        imageUrls: _uploadedImageUrls,
        youtubeUrl: _youtubeUrlController.text.trim(),
      );

      final docId = _editingDocId ?? dateText;
      await FirebaseFirestore.instance
          .collection('DaebangBulletins')
          .doc(docId)
          .set(bulletin.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$dateText 주보가 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteBulletin(String docId) async {
    await FirebaseFirestore.instance
        .collection('DaebangBulletins')
        .doc(docId)
        .delete();
    if (_editingDocId == docId) {
      setState(() => _editingDocId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('관리자 로그인')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '관리자 이메일',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _signIn,
                          child: const Text('로그인'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('주보 관리 (관리자)'),
            actions: [
              TextButton.icon(
                onPressed: _fillSampleData,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('샘플 채우기'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. 기본 및 표지 정보',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: '주일 날짜 (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _volumeController,
                            decoration: const InputDecoration(
                              labelText: '주보 호수 (예: 제45권 25호)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mottoController,
                            decoration: const InputDecoration(
                              labelText: '교회 표어',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _mottoVerseController,
                            decoration: const InputDecoration(
                              labelText: '표어 성구',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('2. 주일 예배 순서 및 봉사자',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _presiderController,
                      decoration: const InputDecoration(
                        labelText: '예배 인도자 (축도)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sundayPrayerController,
                            decoration: const InputDecoration(
                              labelText: '대표기도',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _nextWeekPrayerController,
                            decoration: const InputDecoration(
                              labelText: '다음 주 기도',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sundayHymn1Controller,
                            decoration: const InputDecoration(
                              labelText: '찬양 (예: 488장)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _offeringHymnController,
                            decoration: const InputDecoration(
                              labelText: '헌금과헌신 찬양 (예: 482장)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sundayScriptureController,
                            decoration: const InputDecoration(
                              labelText: '성경봉독 (예: 롬 8:17-25)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _sermonSeriesController,
                            decoration: const InputDecoration(
                              labelText: '강해 시리즈 (예: 로마서 강해(14))',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _sermonTitleController,
                            decoration: const InputDecoration(
                              labelText: '주일 설교 제목',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _preacherController,
                            decoration: const InputDecoration(
                              labelText: '설교자',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('3. 수요 예배 순서',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _wedHymn1Controller,
                            decoration: const InputDecoration(
                              labelText: '수요 첫찬양',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _wedHymn2Controller,
                            decoration: const InputDecoration(
                              labelText: '수요 끝찬양',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _wedScriptureController,
                            decoration: const InputDecoration(
                              labelText: '수요 성경봉독',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _wedTitleController,
                      decoration: const InputDecoration(
                        labelText: '수요 말씀 제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('4. 교회 소식 및 선교편지 / 사진 업로드',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _announcementsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '교회 소식 (줄바꿈으로 구분)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _missionTitleController,
                      decoration: const InputDecoration(
                        labelText: '선교편지 / 칼럼 제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _missionContentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '선교편지 / 칼럼 본문',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _isUploading ? null : _pickAndUploadImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(_isUploading
                              ? '업로드 중...'
                              : '활동 사진 선택 (자동 압축 업로드)'),
                        ),
                        const SizedBox(width: 12),
                        Text('첨부됨: ${_uploadedImageUrls.length}장'),
                        if (_uploadedImageUrls.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                setState(() => _uploadedImageUrls.clear()),
                            child: const Text('초기화',
                                style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _youtubeUrlController,
                      decoration: const InputDecoration(
                        labelText: '예배 영상 YouTube 링크',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E4C6D),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : _saveBulletin,
                        icon: const Icon(Icons.save),
                        label: Text(_isSaving ? '저장 중...' : '주보 저장하기'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text('등록된 주보 목록 (클릭 시 수정)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('DaebangBulletins')
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, listSnap) {
                        if (!listSnap.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final docs = listSnap.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, idx) {
                            final b = Bulletin.fromFirestore(docs[idx]);
                            return Card(
                              child: ListTile(
                                title: Text('${b.date} (${b.volume})'),
                                subtitle: Text(b.sermonTitle),
                                onTap: () => _loadBulletinToForm(b),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteBulletin(b.id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}