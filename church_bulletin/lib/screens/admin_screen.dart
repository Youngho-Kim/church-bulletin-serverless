import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String? _loginError;
  bool _isLoading = false;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController(text: '제45권 25호');
  final _mottoCtrl = TextEditingController(text: '그리스도를 닮아가는 공동체');
  final _mottoVerseCtrl = TextEditingController();
  final _presiderController = TextEditingController(text: '박건용 목사');
  final _sundayPrayerCtrl = TextEditingController();
  final _nextWeekPrayerCtrl = TextEditingController();
  final _sundayHymn1Ctrl = TextEditingController();
  final _sundayScriptureCtrl = TextEditingController();
  final _sermonSeriesCtrl = TextEditingController();
  final _sermonTitleCtrl = TextEditingController();
  final _preacherCtrl = TextEditingController(text: '박건용 목사');
  final _offeringHymnCtrl = TextEditingController();

  final _wedHymn1Ctrl = TextEditingController();
  final _wedScriptureCtrl = TextEditingController();
  final _wedTitleCtrl = TextEditingController();
  final _wedHymn2Ctrl = TextEditingController();

  final _announcementsCtrl = TextEditingController();
  final _missionTitleCtrl = TextEditingController();
  final _missionContentCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  // 업로드 완료된 이미지 URL 목록
  List<String> _uploadedImageUrls = [];

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _loginError = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _loginError = '로그인 실패: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 다중 이미지 선택 -> 자동 압축(가로 1200px, 품질 80%) -> Firebase Storage 업로드
  Future<void> _pickAndUploadImages() async {
    final docId = _dateCtrl.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 올리기 전에 먼저 [주일 날짜]를 입력해 주세요.')),
      );
      return;
    }

    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
    );

    if (pickedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final List<String> newUrls = [];
      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        final bytes = await file.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('bulletins/$docId/$fileName');

        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final downloadUrl = await ref.getDownloadURL();
        newUrls.add(downloadUrl);
      }

      setState(() {
        _uploadedImageUrls.addAll(newUrls);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newUrls.length}장의 사진이 압축 업로드되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _fillPdfSampleData() {
    _dateCtrl.text = '2026-06-14';
    _volumeCtrl.text = '제45권 25호';
    _mottoCtrl.text = '그리스도를 닮아가는 공동체';
    _mottoVerseCtrl.text = '히브리서 12장 2절';
    _sundayPrayerCtrl.text = '권인택 권사';
    _nextWeekPrayerCtrl.text = '이영자 권사';
    _sundayHymn1Ctrl.text = '488장';
    _sundayScriptureCtrl.text = '롬 8:17-25(신약 249p)';
    _sermonSeriesCtrl.text = '로마서 강해(14)';
    _sermonTitleCtrl.text = '우리 몸의 속량을 기다리느니라';
    _preacherCtrl.text = '박건용 목사';
    _offeringHymnCtrl.text = '482장';

    _wedHymn1Ctrl.text = '508장';
    _wedScriptureCtrl.text = '왕하 7:1-10';
    _wedTitleCtrl.text = '아름다운 소식이 있는 날';
    _wedHymn2Ctrl.text = '503장';

    _announcementsCtrl.text =
        '환영 : 오늘 예배에 참석하신 분들을 주님의 이름으로 환영합니다.\n'
        '모임 : 예배 후에 학부모 기도모임이 있습니다.\n'
        '다음 주 예배 후에 식사모임이 있습니다.\n'
        '기도 : 환우들과 교회, 나라와 민족을 위해서, 세계 선교를 위해서 계속 기도해 주시기 바랍니다.';
    _missionTitleCtrl.text = '미얀마 선교편지 02 - 어린이 캠프';
    _missionContentCtrl.text =
        '미얀마에서는 3월부터 5월까지 3개월간의 학교 방학을 합니다. 학생들에게 항상 매우 기대되는 즐거운 시간입니다.\n'
        '이 시기를 활용하여 다곤대학교 교회 주일학교 어린이들을 위한 즐거운 어린이 성경 캠프가 5월 1~2일 개최되었습니다.\n'
        '다곤대학교 교회와 쉐알링 교회가 공동으로 주최한 이 행사에는 52명의 주일학교 어린이들이 참여했습니다.\n'
        '\'하나님의 비전\'을 주제로 성경공부, 만들기, 춤, 게임 등의 활동을 했습니다. 가장 큰 하이라이트는 다음 날 양곤 동물원으로 떠난 특별 현장 학습이었습니다.';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('2026-06-14 PDF 주보 내용이 입력되었습니다.')),
    );
  }

  void _loadBulletinToForm(Bulletin b) {
    setState(() {
      _dateCtrl.text = b.id;
      _volumeCtrl.text = b.volume;
      _mottoCtrl.text = b.motto;
      _mottoVerseCtrl.text = b.mottoVerse;
      _presiderController.text = b.presider;
      _sundayPrayerCtrl.text = b.sundayPrayer;
      _nextWeekPrayerCtrl.text = b.nextWeekPrayer;
      _sundayHymn1Ctrl.text = b.sundayHymn1;
      _sundayScriptureCtrl.text = b.sundayScripture;
      _sermonSeriesCtrl.text = b.sermonSeries;
      _sermonTitleCtrl.text = b.sermonTitle;
      _preacherCtrl.text = b.preacher;
      _offeringHymnCtrl.text = b.offeringHymn;
      _wedHymn1Ctrl.text = b.wedHymn1;
      _wedScriptureCtrl.text = b.wedScripture;
      _wedTitleCtrl.text = b.wedTitle;
      _wedHymn2Ctrl.text = b.wedHymn2;
      _announcementsCtrl.text = b.announcements.join('\n');
      _missionTitleCtrl.text = b.missionTitle;
      _missionContentCtrl.text = b.missionContent;
      _uploadedImageUrls = List<String>.from(b.imageUrls);
      _youtubeCtrl.text = b.youtubeUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${b.date} 주보를 불러왔습니다.')),
    );
  }

  Future<void> _saveBulletin() async {
    if (!_formKey.currentState!.validate()) return;

    final docId = _dateCtrl.text.trim();
    final formattedDate = docId.replaceAll('-', '.');

    final announcements = _announcementsCtrl.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final bulletin = Bulletin(
      id: docId,
      date: formattedDate,
      volume: _volumeCtrl.text.trim(),
      motto: _mottoCtrl.text.trim(),
      mottoVerse: _mottoVerseCtrl.text.trim(),
      presider: _presiderController.text.trim(),
      sundayPrayer: _sundayPrayerCtrl.text.trim(),
      nextWeekPrayer: _nextWeekPrayerCtrl.text.trim(),
      sundayHymn1: _sundayHymn1Ctrl.text.trim(),
      sundayScripture: _sundayScriptureCtrl.text.trim(),
      sermonSeries: _sermonSeriesCtrl.text.trim(),
      sermonTitle: _sermonTitleCtrl.text.trim(),
      preacher: _preacherCtrl.text.trim(),
      offeringHymn: _offeringHymnCtrl.text.trim(),
      wedHymn1: _wedHymn1Ctrl.text.trim(),
      wedScripture: _wedScriptureCtrl.text.trim(),
      wedTitle: _wedTitleCtrl.text.trim(),
      wedHymn2: _wedHymn2Ctrl.text.trim(),
      announcements: announcements,
      missionTitle: _missionTitleCtrl.text.trim(),
      missionContent: _missionContentCtrl.text.trim(),
      imageUrls: _uploadedImageUrls,
      youtubeUrl: _youtubeCtrl.text.trim(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('DaebangBulletins')
          .doc(docId)
          .set(bulletin.toMap(), SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$docId 주보가 저장되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  Future<void> _deleteBulletin(String docId) async {
    await FirebaseFirestore.instance
        .collection('DaebangBulletins')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
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
                            labelText: '관리자 이메일', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: '비밀번호', border: OutlineInputBorder()),
                        onSubmitted: (_) => _signIn(),
                      ),
                      if (_loginError != null) ...[
                        const SizedBox(height: 12),
                        Text(_loginError!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('로그인'),
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
                onPressed: _fillPdfSampleData,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('6/14 샘플 채우기'),
              ),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('1. 기본 및 표지 정보',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateCtrl,
                                decoration: const InputDecoration(
                                    labelText: '주일 날짜 (YYYY-MM-DD)',
                                    border: OutlineInputBorder()),
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? '필수 입력' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _volumeCtrl,
                                decoration: const InputDecoration(
                                    labelText: '주보 호수 (예: 제45권 25호)',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mottoCtrl,
                                decoration: const InputDecoration(
                                    labelText: '교회 표어',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _mottoVerseCtrl,
                                decoration: const InputDecoration(
                                    labelText: '표어 성구',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text('2. 주일 예배 순서 및 봉사자',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sundayPrayerCtrl,
                                decoration: const InputDecoration(
                                    labelText: '대표기도',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _nextWeekPrayerCtrl,
                                decoration: const InputDecoration(
                                    labelText: '다음 주 기도',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sundayHymn1Ctrl,
                                decoration: const InputDecoration(
                                    labelText: '찬양 (예: 488장)',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _offeringHymnCtrl,
                                decoration: const InputDecoration(
                                    labelText: '헌금과헌신 찬양 (예: 482장)',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sundayScriptureCtrl,
                                decoration: const InputDecoration(
                                    labelText: '성경봉독 (예: 롬 8:17-25)',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _sermonSeriesCtrl,
                                decoration: const InputDecoration(
                                    labelText: '강해 시리즈 (예: 로마서 강해(14))',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _sermonTitleCtrl,
                                decoration: const InputDecoration(
                                    labelText: '주일 설교 제목',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _preacherCtrl,
                                decoration: const InputDecoration(
                                    labelText: '설교자',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text('3. 수요 예배 순서',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _wedHymn1Ctrl,
                                decoration: const InputDecoration(
                                    labelText: '수요 첫찬양',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _wedHymn2Ctrl,
                                decoration: const InputDecoration(
                                    labelText: '수요 끝찬양',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _wedScriptureCtrl,
                                decoration: const InputDecoration(
                                    labelText: '수요 성경봉독',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _wedTitleCtrl,
                          decoration: const InputDecoration(
                              labelText: '수요 말씀 제목',
                              border: OutlineInputBorder()),
                        ),

                        const SizedBox(height: 20),
                        const Text('4. 교회 소식 및 선교편지 / 사진 업로드',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _announcementsCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: '교회 소식 (줄바꿈으로 구분)',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _missionTitleCtrl,
                          decoration: const InputDecoration(
                              labelText: '선교편지 / 칼럼 제목',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _missionContentCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: '선교편지 / 칼럼 본문',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),

                        // 직접 파일 선택 및 자동 압축 업로드 버튼
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  _isUploading ? null : _pickAndUploadImages,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_photo_alternate),
                              label: Text(_isUploading
                                  ? '압축 업로드 중...'
                                  : '활동 사진 선택 (자동 압축 업로드)'),
                            ),
                            const SizedBox(width: 12),
                            Text('첨부됨: ${_uploadedImageUrls.length}장',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                        if (_uploadedImageUrls.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _uploadedImageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _uploadedImageUrls[idx],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _uploadedImageUrls.removeAt(idx);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _youtubeCtrl,
                          decoration: const InputDecoration(
                              labelText: '예배 영상 YouTube 링크',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saveBulletin,
                            icon: const Icon(Icons.save),
                            label: const Text('주보 저장하기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 40),
                  const Text('등록된 주보 목록 (클릭 시 수정)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('DaebangBulletins')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final b = Bulletin.fromFirestore(doc);
                          return Card(
                            child: ListTile(
                              title: Text('${b.date} (${b.volume})'),
                              subtitle: Text(b.sermonTitle),
                              onTap: () => _loadBulletinToForm(b),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBulletin(b.id),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}